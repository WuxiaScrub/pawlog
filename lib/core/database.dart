import 'package:drift/drift.dart';

import 'database_connection.dart';

part 'database.g.dart';

class Cats extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get breed => text().nullable()();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  RealColumn get weightKg => real().nullable()();
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

@DriftDatabase(tables: [Cats, Events, NotificationSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection('pawlog'));

  @override
  int get schemaVersion => 1;
}
