import 'package:drift/drift.dart';

import 'database_connection.dart';

part 'database.g.dart';

class Cats extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get breed => text().nullable()();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get photoPath => text().nullable()();
  // JSON array of CatEventType.storageKey strings — the event types the user
  // wants shown as quick-log buttons. null means "show all" (legacy/default).
  TextColumn get quickLogTypesJson => text().nullable()();
  // Set to true once the post-registration care-preferences screening is done,
  // so the app only shows the screening screen once per new cat.
  BoolColumn get screeningDone =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Events extends Table {
  TextColumn get id => text()();
  TextColumn get catId => text().references(Cats, #id)();
  TextColumn get eventType => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class NotificationSettings extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text().unique()();
  IntColumn get thresholdHours => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A cat's feeding schedule. Setup is optional — a cat with no row here
/// just uses ad-hoc feeding logging like any other event type.
class FeedingSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get catId => text().references(Cats, #id)();
  IntColumn get timesPerDay => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// One feeding slot (e.g. "Morning") belonging to a feeding schedule.
/// Whether a slot has been fed "today" is derived from Events rows logged
/// against it, rather than stored here.
class FeedingSlots extends Table {
  TextColumn get id => text()();
  TextColumn get scheduleId => text().references(FeedingSchedules, #id)();
  TextColumn get catId => text().references(Cats, #id)();
  TextColumn get label => text()();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncQueueItem')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    Cats,
    Events,
    NotificationSettings,
    FeedingSchedules,
    FeedingSlots,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection('pawlog'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _ensureNotificationSettingsEventTypeUnique();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(cats, cats.photoPath);
        await m.createTable(feedingSchedules);
        await m.createTable(feedingSlots);
      }
      if (from < 3) {
        await customStatement(
          'DELETE FROM notification_settings WHERE rowid NOT IN '
          '(SELECT MAX(rowid) FROM notification_settings GROUP BY event_type)',
        );
        await _ensureNotificationSettingsEventTypeUnique();
      }
      if (from < 4) {
        await m.addColumn(cats, cats.quickLogTypesJson);
        await m.addColumn(cats, cats.screeningDone);
      }
      if (from < 5) {
        await m.createTable(syncQueue);
      }
    },
  );

  Future<void> _ensureNotificationSettingsEventTypeUnique() {
    return customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'notification_settings_event_type_unique '
      'ON notification_settings (event_type)',
    );
  }
}
