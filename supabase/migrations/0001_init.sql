-- PawLog initial schema for Supabase (premium / cloud-sync tier).
--
-- Mirrors the local Drift schema (lib/core/database.dart) field-for-field
-- where the tables overlap, so the sync layer can map rows directly. Adds
-- user_id / auth ownership and the multi-owner tables (cat_members,
-- cat_invites, subscriptions) that only make sense once accounts exist.

-- ---------------------------------------------------------------------
-- Cats
-- ---------------------------------------------------------------------
create table cats (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  breed text,
  date_of_birth date,
  weight_kg numeric(5, 2),
  photo_url text,
  quick_log_types jsonb,
  screening_done boolean not null default false,
  created_at timestamptz not null default now()
);

alter table cats enable row level security;

-- ---------------------------------------------------------------------
-- Shared household (premium): additional owners per cat.
-- Declared before cats' RLS policies below since those policies join it.
-- ---------------------------------------------------------------------
create table cat_members (
  cat_id uuid not null references cats (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  invited_by uuid references auth.users (id),
  joined_at timestamptz not null default now(),
  primary key (cat_id, user_id)
);

alter table cat_members enable row level security;

create table cat_invites (
  id uuid primary key default gen_random_uuid(),
  cat_id uuid not null references cats (id) on delete cascade,
  invited_by uuid not null references auth.users (id),
  email text not null,
  token text unique not null,
  accepted boolean not null default false,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days')
);

alter table cat_invites enable row level security;

-- A user can see/act on a cat if they own it directly or are a household member.
create or replace function cat_is_accessible(target_cat_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from cats where id = target_cat_id and user_id = auth.uid()
  ) or exists (
    select 1 from cat_members
    where cat_id = target_cat_id and user_id = auth.uid()
  );
$$;

create policy "cats: select own or shared" on cats
  for select using (cat_is_accessible(id));
create policy "cats: insert own" on cats
  for insert with check (user_id = auth.uid());
create policy "cats: update own or shared" on cats
  for update using (cat_is_accessible(id));
create policy "cats: delete owner only" on cats
  for delete using (user_id = auth.uid());

create policy "cat_members: select if accessible" on cat_members
  for select using (cat_is_accessible(cat_id));
create policy "cat_members: owner manages members" on cat_members
  for all using (
    exists (select 1 from cats where id = cat_id and user_id = auth.uid())
  );

create policy "cat_invites: owner manages invites" on cat_invites
  for all using (
    exists (select 1 from cats where id = cat_id and user_id = auth.uid())
  );

-- ---------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------
create table events (
  id uuid primary key default gen_random_uuid(),
  cat_id uuid not null references cats (id) on delete cascade,
  user_id uuid not null references auth.users (id),
  event_type text not null,
  notes text,
  metadata jsonb,
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table events enable row level security;

create policy "events: select if cat accessible" on events
  for select using (cat_is_accessible(cat_id));
create policy "events: insert if cat accessible" on events
  for insert with check (cat_is_accessible(cat_id) and user_id = auth.uid());
create policy "events: update if cat accessible" on events
  for update using (cat_is_accessible(cat_id));
create policy "events: delete if cat accessible" on events
  for delete using (cat_is_accessible(cat_id));

-- ---------------------------------------------------------------------
-- Notification settings (per user, one row per event type)
-- ---------------------------------------------------------------------
create table notification_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  event_type text not null,
  threshold_hours integer not null,
  enabled boolean not null default true,
  unique (user_id, event_type)
);

alter table notification_settings enable row level security;

create policy "notification_settings: owner only" on notification_settings
  for all using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- Feeding schedules
-- ---------------------------------------------------------------------
create table feeding_schedules (
  id uuid primary key default gen_random_uuid(),
  cat_id uuid not null references cats (id) on delete cascade,
  times_per_day integer not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

alter table feeding_schedules enable row level security;

create policy "feeding_schedules: if cat accessible" on feeding_schedules
  for all using (cat_is_accessible(cat_id));

create table feeding_slots (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null references feeding_schedules (id) on delete cascade,
  cat_id uuid not null references cats (id) on delete cascade,
  label text not null,
  hour integer not null,
  minute integer not null,
  sort_order integer not null
);

alter table feeding_slots enable row level security;

create policy "feeding_slots: if cat accessible" on feeding_slots
  for all using (cat_is_accessible(cat_id));

-- ---------------------------------------------------------------------
-- Subscription / entitlement tracking
-- ---------------------------------------------------------------------
create table subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  tier text not null default 'free' check (tier in ('free', 'premium')),
  started_at timestamptz,
  expires_at timestamptz,
  store text check (store in ('google_play', 'app_store')),
  updated_at timestamptz not null default now()
);

alter table subscriptions enable row level security;

create policy "subscriptions: owner read" on subscriptions
  for select using (user_id = auth.uid());
-- Deliberately no client-side insert/update/delete policy: tier changes
-- are only ever written by the RevenueCat webhook (service role), never
-- by the app itself, so a compromised client can't grant itself premium.

-- ---------------------------------------------------------------------
-- Storage: cat photos (event photos + profile photos).
-- Bucket is created via the dashboard/CLI (storage.buckets), policies here.
-- Path convention: {user_id}/{filename}, enforced by policy below.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('cat-photos', 'cat-photos', false)
on conflict (id) do nothing;

create policy "cat-photos: owner read own folder" on storage.objects
  for select using (
    bucket_id = 'cat-photos' and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "cat-photos: owner write own folder" on storage.objects
  for insert with check (
    bucket_id = 'cat-photos' and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "cat-photos: owner delete own folder" on storage.objects
  for delete using (
    bucket_id = 'cat-photos' and (storage.foldername(name))[1] = auth.uid()::text
  );
