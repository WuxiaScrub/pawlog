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
  TextColumn get eventType => text()();
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

@DriftDatabase(
  tables: [Cats, Events, NotificationSettings, FeedingSchedules, FeedingSlots],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection('pawlog'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(cats, cats.photoPath);
        await m.createTable(feedingSchedules);
        await m.createTable(feedingSlots);
      }
    },
    beforeOpen: (details) async {
      // A past race in NotificationSettingsRepository.upsert could insert
      // more than one row for the same event type before a unique
      // constraint existed. Keep only the most recently written row per
      // event type so a stale threshold can't keep resurfacing.
      await customStatement(
        'DELETE FROM notification_settings WHERE rowid NOT IN '
        '(SELECT MAX(rowid) FROM notification_settings GROUP BY event_type)',
      );
    },
  );
}
