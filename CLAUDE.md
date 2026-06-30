# PawLog — Claude Code Build Guide

## Project Summary

PawLog is a cat-care companion app built in Flutter, targeting Android as its first public release. It helps cat owners effortlessly log daily care events via voice or tap, receive smart reminders when care is overdue, and build a rich health history to share with their vet.

The core insight: cat owners forget when they last scooped litter, changed water, or dewormed their cat — and vets rarely get accurate timelines. PawLog solves both problems with minimal friction, using conversational voice logging so users can record events hands-free (e.g., while cleaning up vomit).

**Build & Release Strategy:**
- Build and test on iOS first (developer has an iPhone for personal testing)
- iOS build serves as the primary development and QA environment
- Once iOS version is stable and tested, compile for Android, run smoke tests, and publish to Google Play first ($25 one-time fee vs Apple's $99/year)
- iOS App Store release follows as a second step
- Flutter shares 100% of the codebase across platforms — Android conversion is a platform config task, not a rebuild

---

## Tech Stack

| Layer | Tool | Notes |
|---|---|---|
| Framework | Flutter (Dart) | Single codebase for Android + iOS |
| Backend / Auth / DB | Supabase | Postgres DB, auth, real-time sync |
| Voice Input | Flutter `speech_to_text` package | Button-to-talk, not always-on |
| Voice Output (TTS) | Flutter `flutter_tts` package | App speaks follow-up questions aloud |
| Intent Parsing | Anthropic Claude API (`claude-haiku-4-5`) | Parses voice transcript → structured JSON event(s) |
| Local Notifications | `flutter_local_notifications` package | Reminder alerts based on last-logged timestamps |
| State Management | Riverpod | Preferred for Flutter; clean and testable |
| Navigation | `go_router` | Declarative routing |

---

## Core Features (V1 Scope)

### 1. Cat Profiles
- Free tier: 1 cat only
- Premium tier: unlimited cats
- All logs are tied to a specific cat profile
- If multiple cats exist (premium) and a voice log doesn't mention a name, prompt user to select which cat

### 2. Event Logging — Tap or Voice
- Prominent floating mic button on home screen
- Tap to start listening; auto-stops after 2–3 seconds of silence OR after 30 seconds max (hard cutoff)
- Transcript is capped at 500 characters before sending to API (cost control)
- Claude API parses transcript → returns structured JSON of one or more events
- Confirmation screen shown before saving — user can edit or cancel
- Tap-based logging also available for each event type as a fallback

**Loggable events in V1:**
- Litter scooped
- Litter fully changed
- Water changed
- Vomiting (with follow-up prompts)
- Hairball
- Deworming (log product name)
- Flea/tick treatment (log product name)
- General health note (freeform)

### 3. Conversational Follow-Up (Voice Interview)
After logging certain events, the app speaks follow-up questions via TTS and listens for short responses. Keep to 2–3 questions max per event. Questions should be yes/no or very brief.

**Example flow for vomiting:**
1. App: "Got it — logged that [cat name] vomited. Did you notice any hairballs?"
2. User: "No"
3. App: "Was this shortly after eating?"
4. User: "Yes, about 10 minutes after"
5. App: "Anything else to add?"
6. User: "No"
7. App: "All logged."

Follow-up questions per event type:
- **Vomiting**: hairballs present? shortly after eating? anything unusual beforehand?
- **Litter change**: any unusual color or odor noticed?
- **Deworming / Flea treatment**: which product? first time or repeat?
- **General note**: no follow-ups; just confirm and save

### 4. Reminders & Alerts
- User sets thresholds per event type (e.g., "alert me if litter hasn't been scooped in 24 hours")
- Local push notifications only — no server required for solo users in V1
- On app open, check last timestamp per event type and fire notification if threshold exceeded
- Notification tapping opens the relevant log screen

### 5. Log History
- Scrollable timeline per cat, newest first
- Filter by event type
- Each entry shows: event type, timestamp, any notes captured
- Free tier: last 30 days visible; premium tier: full unlimited history

### 6. Basic Dashboard
- Per-cat summary: how many times each event occurred this week vs. last week
- No AI in V1 dashboard — just counts and timestamps
- Simple bar or line charts using `fl_chart` package

---

## Database Schema (Supabase / Postgres)

```sql
-- Cat profiles
CREATE TABLE cats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  breed TEXT,
  date_of_birth DATE,
  weight_kg NUMERIC(5,2),
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Event log
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cat_id UUID REFERENCES cats(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  event_type TEXT NOT NULL, -- 'litter_scoop', 'litter_change', 'water_change', 'vomit', 'hairball', 'deworming', 'flea_treatment', 'note'
  notes TEXT,
  metadata JSONB, -- flexible: product name, hairball present, after eating, etc.
  logged_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User notification preferences
CREATE TABLE notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  event_type TEXT NOT NULL,
  threshold_hours INTEGER NOT NULL, -- alert if no event logged within this many hours
  enabled BOOLEAN DEFAULT TRUE
);

-- Subscription / entitlement tracking
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) UNIQUE,
  tier TEXT NOT NULL DEFAULT 'free', -- 'free' | 'premium'
  started_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  store TEXT, -- 'google_play' | 'app_store' | null
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

Enable Row Level Security (RLS) on all tables so users can only read/write their own data.

---

## Claude API Integration

**Model:** `claude-haiku-4-5` (cheapest, fast, more than sufficient for this task)

**Intent parsing prompt:**

```
System: You are a cat care logging assistant. Parse the user's voice transcript and extract one or more care events. 

Return ONLY valid JSON in this format:
{
  "events": [
    {
      "event_type": "litter_scoop" | "litter_change" | "water_change" | "vomit" | "hairball" | "deworming" | "flea_treatment" | "note",
      "cat_name": "<name if mentioned, else null>",
      "notes": "<any additional detail mentioned>",
      "metadata": {}
    }
  ]
}

If no recognizable event is found, return: { "events": [] }
Do not include any explanation or text outside the JSON.

User: [transcript capped at 500 chars]
```

**Cost controls:**
- Cap transcript at 500 characters before sending
- 30-second max recording duration
- 2–3 second silence detection auto-stops mic
- Expected cost: ~$0.0006 per API call (Haiku pricing)

---

## Voice Flow Architecture

```
User taps mic
    → flutter speech_to_text starts listening
    → silence detected (pauseFor: 2s) OR 30s timeout
    → transcript captured, capped at 500 chars
    → send to Claude API
    → parse JSON response
    → if multiple cats and cat_name is null → show cat picker
    → show confirmation screen with parsed events
    → user confirms → write to Supabase
    → trigger follow-up TTS questions if event type warrants it
    → listen for each answer → append to event metadata
    → final confirmation: "All logged."
```

---

## App Screens (V1)

1. **Onboarding** — Sign up / login (Supabase Auth, email or Google)
2. **Home** — Dashboard summary + floating mic button + quick-tap event buttons
3. **Cat Profile Setup** — Add/edit cat details
4. **Log History** — Timeline per cat, filterable by event type
5. **Event Detail** — Single event with all notes and metadata
6. **Settings** — Notification thresholds per event type, manage cats, account

---

## Project Structure

```
lib/
  main.dart
  app.dart                  # GoRouter setup
  core/
    supabase_client.dart
    claude_service.dart     # API call + JSON parsing
    tts_service.dart        # Text-to-speech wrapper
    stt_service.dart        # Speech-to-text wrapper
  features/
    auth/
    cats/                   # Cat profiles
    events/                 # Logging, history, detail
    dashboard/
    settings/
  models/
    cat.dart
    event.dart
    notification_setting.dart
  providers/               # Riverpod providers
```

---

## V1 Build Order (Suggested)

**Phase 1 — Core (iOS build target)**
1. Flutter project setup + Supabase connection + auth flow
2. Cat profile creation screen
3. Supabase schema and RLS policies (including `cat_members` table — see Shared Household)
4. Manual tap-based event logging (no voice yet)
5. Log history screen
6. Local notifications + threshold settings
7. Basic dashboard (counts + simple charts)
8. Voice input (STT) → Claude API intent parsing
9. Confirmation screen for parsed events
10. TTS follow-up question flow
11. Multi-cat disambiguation
12. Shared household — invite by email flow
13. Polish, error handling, edge cases

**Phase 2 — iOS Testing**
- Test personally on iPhone throughout Phase 1
- Full QA pass on iOS before switching build targets
- Verify microphone permissions (`Info.plist`): `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`
- Verify push notification entitlements in Xcode

**Phase 3 — Android Conversion**
- Switch Flutter build target to Android
- Configure `AndroidManifest.xml` permissions: `RECORD_AUDIO`, `INTERNET`, `RECEIVE_BOOT_COMPLETED` (for notifications)
- Test on Android emulator and/or physical device
- Configure Google Play in-app billing (RevenueCat handles most of this)
- Smoke test all core flows end-to-end

**Phase 4 — Android Release**
- Create Google Play Developer account ($25 one-time)
- Prepare store listing: screenshots, description, privacy policy
- Submit to Google Play internal testing track first, then production

---

## Shared Household (V1 Premium Feature)

Multiple owners per cat account is supported in V1 for premium users. The admin (original cat owner) invites members by email. invited users receive a link, sign up or log in, and are added to the cat's member list.

**Additional table needed:**
```sql
CREATE TABLE cat_members (
  cat_id UUID REFERENCES cats(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member', -- 'owner' | 'member'
  invited_by UUID REFERENCES auth.users(id),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (cat_id, user_id)
);

CREATE TABLE cat_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cat_id UUID REFERENCES cats(id) ON DELETE CASCADE,
  invited_by UUID REFERENCES auth.users(id),
  email TEXT NOT NULL,
  token TEXT UNIQUE NOT NULL, -- secure random token for invite link
  accepted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days'
);
```

**Invite flow:**
1. Admin opens Settings → Household Members → Invite
2. Enters invitee's email address
3. Supabase Edge Function sends invite email with a unique link (or app generates a shareable code)
4. Invitee taps link → opens app → logs in or signs up → automatically joined as member
5. All members see the same cat's logs and can add new events
6. Only the owner can delete the cat profile or remove members

**RLS update:** All cat-related queries must join against `cat_members` to check access, not just `cats.user_id`.

---

## V2 Roadmap (Do Not Build Yet)

- LLM-generated monthly summaries + PDF vet reports (premium)
- "Ask about my cat" AI queries e.g. "when did Fluffy last throw up?" (premium)
- Trend detection and AI-powered health pattern analysis (premium)
- Smart reminders with adaptive thresholds based on logged patterns (premium)
- Photo attachments on log entries
- iOS App Store release (app already runs on iOS — this is just the store submission)
- In-app purchase / subscription paywall using `purchases_flutter` (RevenueCat SDK)

---

## Monetization & Tier Enforcement

### Pricing
- **Free**: $0 forever
- **Premium**: $3.99/month or $29.99/year (consider $2.99/month launch pricing for first cohort)

### Free Tier Limits
| Feature | Free | Premium |
|---|---|---|
| Cats | 1 | Unlimited |
| Voice logs | 3 per day | Unlimited |
| Log history | Last 30 days | Unlimited |
| Reminders | Basic (fixed thresholds) | Smart (adaptive) |
| Cloud sync | ❌ Local only | ✅ Supabase sync |
| AI queries ("when did she last vomit?") | ❌ | ✅ |
| Trend detection | ❌ | ✅ |
| Vet report generation | ❌ | ✅ |
| Shared household | ❌ | ✅ |

### Tier Enforcement Rules
- Check `subscriptions.tier` on app launch and cache result locally
- Gate premium features at the feature level, not just the UI — enforce server-side via RLS where possible
- Voice log counter: store daily voice log count in local storage, reset at midnight
- When free user hits a limit, show a friendly upsell modal explaining what premium unlocks — never a hard error
- Free users store data locally only (SQLite via `drift` package); premium users sync to Supabase
- In-app purchases: use RevenueCat (`purchases_flutter`) to manage subscriptions across Google Play and App Store

### Upsell Trigger Points
- User tries to add a second cat → upsell modal
- User hits 3rd voice log of the day → upsell modal
- User tries to view history older than 30 days → upsell modal
- After 7 days of active use → gentle premium prompt on home screen

---

## Key Constraints & Notes

- **No emergency health advice** — app is a logger only, not a diagnostic tool. No liability surface.
- **Disclaimer required** — add "PawLog is not a substitute for veterinary care" in onboarding and settings.
- **Voice is in-app only** — no always-on wake word. Mic activates only when user taps the button.
- **Storage split** — free users use local SQLite (`drift` package) only; premium users sync to Supabase. Design data layer to support both from day one.
- **Offline-first consideration** — queue failed Supabase writes locally and sync when connection restores.
- **Privacy** — voice audio is never stored. Only the parsed text transcript (and then only the metadata) is saved to the database.

