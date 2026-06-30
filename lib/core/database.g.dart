// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CatsTable extends Cats with TableInfo<$CatsTable, Cat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breedMeta = const VerificationMeta('breed');
  @override
  late final GeneratedColumn<String> breed = GeneratedColumn<String>(
    'breed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  @override
  late final GeneratedColumn<DateTime> dateOfBirth = GeneratedColumn<DateTime>(
    'date_of_birth',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    breed,
    dateOfBirth,
    weightKg,
    photoPath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cats';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('breed')) {
      context.handle(
        _breedMeta,
        breed.isAcceptableOrUnknown(data['breed']!, _breedMeta),
      );
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      breed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breed'],
      ),
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_of_birth'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CatsTable createAlias(String alias) {
    return $CatsTable(attachedDatabase, alias);
  }
}

class Cat extends DataClass implements Insertable<Cat> {
  final String id;
  final String name;
  final String? breed;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? photoPath;
  final DateTime createdAt;
  const Cat({
    required this.id,
    required this.name,
    this.breed,
    this.dateOfBirth,
    this.weightKg,
    this.photoPath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || breed != null) {
      map['breed'] = Variable<String>(breed);
    }
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CatsCompanion toCompanion(bool nullToAbsent) {
    return CatsCompanion(
      id: Value(id),
      name: Value(name),
      breed: breed == null && nullToAbsent
          ? const Value.absent()
          : Value(breed),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      createdAt: Value(createdAt),
    );
  }

  factory Cat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cat(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      breed: serializer.fromJson<String?>(json['breed']),
      dateOfBirth: serializer.fromJson<DateTime?>(json['dateOfBirth']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'breed': serializer.toJson<String?>(breed),
      'dateOfBirth': serializer.toJson<DateTime?>(dateOfBirth),
      'weightKg': serializer.toJson<double?>(weightKg),
      'photoPath': serializer.toJson<String?>(photoPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Cat copyWith({
    String? id,
    String? name,
    Value<String?> breed = const Value.absent(),
    Value<DateTime?> dateOfBirth = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    DateTime? createdAt,
  }) => Cat(
    id: id ?? this.id,
    name: name ?? this.name,
    breed: breed.present ? breed.value : this.breed,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    createdAt: createdAt ?? this.createdAt,
  );
  Cat copyWithCompanion(CatsCompanion data) {
    return Cat(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      breed: data.breed.present ? data.breed.value : this.breed,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cat(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('breed: $breed, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('weightKg: $weightKg, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, breed, dateOfBirth, weightKg, photoPath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cat &&
          other.id == this.id &&
          other.name == this.name &&
          other.breed == this.breed &&
          other.dateOfBirth == this.dateOfBirth &&
          other.weightKg == this.weightKg &&
          other.photoPath == this.photoPath &&
          other.createdAt == this.createdAt);
}

class CatsCompanion extends UpdateCompanion<Cat> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> breed;
  final Value<DateTime?> dateOfBirth;
  final Value<double?> weightKg;
  final Value<String?> photoPath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CatsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.breed = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatsCompanion.insert({
    required String id,
    required String name,
    this.breed = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Cat> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? breed,
    Expression<DateTime>? dateOfBirth,
    Expression<double>? weightKg,
    Expression<String>? photoPath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (breed != null) 'breed': breed,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (weightKg != null) 'weight_kg': weightKg,
      if (photoPath != null) 'photo_path': photoPath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? breed,
    Value<DateTime?>? dateOfBirth,
    Value<double?>? weightKg,
    Value<String?>? photoPath,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CatsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weightKg: weightKg ?? this.weightKg,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (breed.present) {
      map['breed'] = Variable<String>(breed.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('breed: $breed, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('weightKg: $weightKg, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catIdMeta = const VerificationMeta('catId');
  @override
  late final GeneratedColumn<String> catId = GeneratedColumn<String>(
    'cat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cats (id)',
    ),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    catId,
    eventType,
    notes,
    metadataJson,
    loggedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cat_id')) {
      context.handle(
        _catIdMeta,
        catId.isAcceptableOrUnknown(data['cat_id']!, _catIdMeta),
      );
    } else if (isInserting) {
      context.missing(_catIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      catId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cat_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final String id;
  final String catId;
  final String eventType;
  final String? notes;
  final String? metadataJson;
  final DateTime loggedAt;
  final DateTime createdAt;
  const Event({
    required this.id,
    required this.catId,
    required this.eventType,
    this.notes,
    this.metadataJson,
    required this.loggedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cat_id'] = Variable<String>(catId);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      catId: Value(catId),
      eventType: Value(eventType),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      loggedAt: Value(loggedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<String>(json['id']),
      catId: serializer.fromJson<String>(json['catId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      notes: serializer.fromJson<String?>(json['notes']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'catId': serializer.toJson<String>(catId),
      'eventType': serializer.toJson<String>(eventType),
      'notes': serializer.toJson<String?>(notes),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Event copyWith({
    String? id,
    String? catId,
    String? eventType,
    Value<String?> notes = const Value.absent(),
    Value<String?> metadataJson = const Value.absent(),
    DateTime? loggedAt,
    DateTime? createdAt,
  }) => Event(
    id: id ?? this.id,
    catId: catId ?? this.catId,
    eventType: eventType ?? this.eventType,
    notes: notes.present ? notes.value : this.notes,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
    loggedAt: loggedAt ?? this.loggedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      catId: data.catId.present ? data.catId.value : this.catId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      notes: data.notes.present ? data.notes.value : this.notes,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('catId: $catId, ')
          ..write('eventType: $eventType, ')
          ..write('notes: $notes, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    catId,
    eventType,
    notes,
    metadataJson,
    loggedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.catId == this.catId &&
          other.eventType == this.eventType &&
          other.notes == this.notes &&
          other.metadataJson == this.metadataJson &&
          other.loggedAt == this.loggedAt &&
          other.createdAt == this.createdAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<String> id;
  final Value<String> catId;
  final Value<String> eventType;
  final Value<String?> notes;
  final Value<String?> metadataJson;
  final Value<DateTime> loggedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.catId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.notes = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    required String catId,
    required String eventType,
    this.notes = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       catId = Value(catId),
       eventType = Value(eventType);
  static Insertable<Event> custom({
    Expression<String>? id,
    Expression<String>? catId,
    Expression<String>? eventType,
    Expression<String>? notes,
    Expression<String>? metadataJson,
    Expression<DateTime>? loggedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (catId != null) 'cat_id': catId,
      if (eventType != null) 'event_type': eventType,
      if (notes != null) 'notes': notes,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<String>? id,
    Value<String>? catId,
    Value<String>? eventType,
    Value<String?>? notes,
    Value<String?>? metadataJson,
    Value<DateTime>? loggedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      catId: catId ?? this.catId,
      eventType: eventType ?? this.eventType,
      notes: notes ?? this.notes,
      metadataJson: metadataJson ?? this.metadataJson,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (catId.present) {
      map['cat_id'] = Variable<String>(catId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('catId: $catId, ')
          ..write('eventType: $eventType, ')
          ..write('notes: $notes, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationSettingsTable extends NotificationSettings
    with TableInfo<$NotificationSettingsTable, NotificationSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thresholdHoursMeta = const VerificationMeta(
    'thresholdHours',
  );
  @override
  late final GeneratedColumn<int> thresholdHours = GeneratedColumn<int>(
    'threshold_hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventType,
    thresholdHours,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('threshold_hours')) {
      context.handle(
        _thresholdHoursMeta,
        thresholdHours.isAcceptableOrUnknown(
          data['threshold_hours']!,
          _thresholdHoursMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_thresholdHoursMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      thresholdHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}threshold_hours'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $NotificationSettingsTable createAlias(String alias) {
    return $NotificationSettingsTable(attachedDatabase, alias);
  }
}

class NotificationSetting extends DataClass
    implements Insertable<NotificationSetting> {
  final String id;
  final String eventType;
  final int thresholdHours;
  final bool enabled;
  const NotificationSetting({
    required this.id,
    required this.eventType,
    required this.thresholdHours,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_type'] = Variable<String>(eventType);
    map['threshold_hours'] = Variable<int>(thresholdHours);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  NotificationSettingsCompanion toCompanion(bool nullToAbsent) {
    return NotificationSettingsCompanion(
      id: Value(id),
      eventType: Value(eventType),
      thresholdHours: Value(thresholdHours),
      enabled: Value(enabled),
    );
  }

  factory NotificationSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationSetting(
      id: serializer.fromJson<String>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      thresholdHours: serializer.fromJson<int>(json['thresholdHours']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventType': serializer.toJson<String>(eventType),
      'thresholdHours': serializer.toJson<int>(thresholdHours),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  NotificationSetting copyWith({
    String? id,
    String? eventType,
    int? thresholdHours,
    bool? enabled,
  }) => NotificationSetting(
    id: id ?? this.id,
    eventType: eventType ?? this.eventType,
    thresholdHours: thresholdHours ?? this.thresholdHours,
    enabled: enabled ?? this.enabled,
  );
  NotificationSetting copyWithCompanion(NotificationSettingsCompanion data) {
    return NotificationSetting(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      thresholdHours: data.thresholdHours.present
          ? data.thresholdHours.value
          : this.thresholdHours,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationSetting(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('thresholdHours: $thresholdHours, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventType, thresholdHours, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationSetting &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.thresholdHours == this.thresholdHours &&
          other.enabled == this.enabled);
}

class NotificationSettingsCompanion
    extends UpdateCompanion<NotificationSetting> {
  final Value<String> id;
  final Value<String> eventType;
  final Value<int> thresholdHours;
  final Value<bool> enabled;
  final Value<int> rowid;
  const NotificationSettingsCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.thresholdHours = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationSettingsCompanion.insert({
    required String id,
    required String eventType,
    required int thresholdHours,
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventType = Value(eventType),
       thresholdHours = Value(thresholdHours);
  static Insertable<NotificationSetting> custom({
    Expression<String>? id,
    Expression<String>? eventType,
    Expression<int>? thresholdHours,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (thresholdHours != null) 'threshold_hours': thresholdHours,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationSettingsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventType,
    Value<int>? thresholdHours,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return NotificationSettingsCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      thresholdHours: thresholdHours ?? this.thresholdHours,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (thresholdHours.present) {
      map['threshold_hours'] = Variable<int>(thresholdHours.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationSettingsCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('thresholdHours: $thresholdHours, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeedingSchedulesTable extends FeedingSchedules
    with TableInfo<$FeedingSchedulesTable, FeedingSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedingSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catIdMeta = const VerificationMeta('catId');
  @override
  late final GeneratedColumn<String> catId = GeneratedColumn<String>(
    'cat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cats (id)',
    ),
  );
  static const VerificationMeta _timesPerDayMeta = const VerificationMeta(
    'timesPerDay',
  );
  @override
  late final GeneratedColumn<int> timesPerDay = GeneratedColumn<int>(
    'times_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    catId,
    timesPerDay,
    enabled,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feeding_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeedingSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cat_id')) {
      context.handle(
        _catIdMeta,
        catId.isAcceptableOrUnknown(data['cat_id']!, _catIdMeta),
      );
    } else if (isInserting) {
      context.missing(_catIdMeta);
    }
    if (data.containsKey('times_per_day')) {
      context.handle(
        _timesPerDayMeta,
        timesPerDay.isAcceptableOrUnknown(
          data['times_per_day']!,
          _timesPerDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timesPerDayMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeedingSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedingSchedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      catId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cat_id'],
      )!,
      timesPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_per_day'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FeedingSchedulesTable createAlias(String alias) {
    return $FeedingSchedulesTable(attachedDatabase, alias);
  }
}

class FeedingSchedule extends DataClass implements Insertable<FeedingSchedule> {
  final String id;
  final String catId;
  final int timesPerDay;
  final bool enabled;
  final DateTime createdAt;
  const FeedingSchedule({
    required this.id,
    required this.catId,
    required this.timesPerDay,
    required this.enabled,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cat_id'] = Variable<String>(catId);
    map['times_per_day'] = Variable<int>(timesPerDay);
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FeedingSchedulesCompanion toCompanion(bool nullToAbsent) {
    return FeedingSchedulesCompanion(
      id: Value(id),
      catId: Value(catId),
      timesPerDay: Value(timesPerDay),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
    );
  }

  factory FeedingSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedingSchedule(
      id: serializer.fromJson<String>(json['id']),
      catId: serializer.fromJson<String>(json['catId']),
      timesPerDay: serializer.fromJson<int>(json['timesPerDay']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'catId': serializer.toJson<String>(catId),
      'timesPerDay': serializer.toJson<int>(timesPerDay),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FeedingSchedule copyWith({
    String? id,
    String? catId,
    int? timesPerDay,
    bool? enabled,
    DateTime? createdAt,
  }) => FeedingSchedule(
    id: id ?? this.id,
    catId: catId ?? this.catId,
    timesPerDay: timesPerDay ?? this.timesPerDay,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
  );
  FeedingSchedule copyWithCompanion(FeedingSchedulesCompanion data) {
    return FeedingSchedule(
      id: data.id.present ? data.id.value : this.id,
      catId: data.catId.present ? data.catId.value : this.catId,
      timesPerDay: data.timesPerDay.present
          ? data.timesPerDay.value
          : this.timesPerDay,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedingSchedule(')
          ..write('id: $id, ')
          ..write('catId: $catId, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, catId, timesPerDay, enabled, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedingSchedule &&
          other.id == this.id &&
          other.catId == this.catId &&
          other.timesPerDay == this.timesPerDay &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt);
}

class FeedingSchedulesCompanion extends UpdateCompanion<FeedingSchedule> {
  final Value<String> id;
  final Value<String> catId;
  final Value<int> timesPerDay;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FeedingSchedulesCompanion({
    this.id = const Value.absent(),
    this.catId = const Value.absent(),
    this.timesPerDay = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeedingSchedulesCompanion.insert({
    required String id,
    required String catId,
    required int timesPerDay,
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       catId = Value(catId),
       timesPerDay = Value(timesPerDay);
  static Insertable<FeedingSchedule> custom({
    Expression<String>? id,
    Expression<String>? catId,
    Expression<int>? timesPerDay,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (catId != null) 'cat_id': catId,
      if (timesPerDay != null) 'times_per_day': timesPerDay,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeedingSchedulesCompanion copyWith({
    Value<String>? id,
    Value<String>? catId,
    Value<int>? timesPerDay,
    Value<bool>? enabled,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FeedingSchedulesCompanion(
      id: id ?? this.id,
      catId: catId ?? this.catId,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (catId.present) {
      map['cat_id'] = Variable<String>(catId.value);
    }
    if (timesPerDay.present) {
      map['times_per_day'] = Variable<int>(timesPerDay.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedingSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('catId: $catId, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeedingSlotsTable extends FeedingSlots
    with TableInfo<$FeedingSlotsTable, FeedingSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedingSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES feeding_schedules (id)',
    ),
  );
  static const VerificationMeta _catIdMeta = const VerificationMeta('catId');
  @override
  late final GeneratedColumn<String> catId = GeneratedColumn<String>(
    'cat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cats (id)',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta(
    'minute',
  );
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scheduleId,
    catId,
    label,
    hour,
    minute,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feeding_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeedingSlot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(
          data['schedule_id']!,
          _scheduleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('cat_id')) {
      context.handle(
        _catIdMeta,
        catId.isAcceptableOrUnknown(data['cat_id']!, _catIdMeta),
      );
    } else if (isInserting) {
      context.missing(_catIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeedingSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedingSlot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      catId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cat_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $FeedingSlotsTable createAlias(String alias) {
    return $FeedingSlotsTable(attachedDatabase, alias);
  }
}

class FeedingSlot extends DataClass implements Insertable<FeedingSlot> {
  final String id;
  final String scheduleId;
  final String catId;
  final String label;
  final int hour;
  final int minute;
  final int sortOrder;
  const FeedingSlot({
    required this.id,
    required this.scheduleId,
    required this.catId,
    required this.label,
    required this.hour,
    required this.minute,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['schedule_id'] = Variable<String>(scheduleId);
    map['cat_id'] = Variable<String>(catId);
    map['label'] = Variable<String>(label);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FeedingSlotsCompanion toCompanion(bool nullToAbsent) {
    return FeedingSlotsCompanion(
      id: Value(id),
      scheduleId: Value(scheduleId),
      catId: Value(catId),
      label: Value(label),
      hour: Value(hour),
      minute: Value(minute),
      sortOrder: Value(sortOrder),
    );
  }

  factory FeedingSlot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedingSlot(
      id: serializer.fromJson<String>(json['id']),
      scheduleId: serializer.fromJson<String>(json['scheduleId']),
      catId: serializer.fromJson<String>(json['catId']),
      label: serializer.fromJson<String>(json['label']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scheduleId': serializer.toJson<String>(scheduleId),
      'catId': serializer.toJson<String>(catId),
      'label': serializer.toJson<String>(label),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  FeedingSlot copyWith({
    String? id,
    String? scheduleId,
    String? catId,
    String? label,
    int? hour,
    int? minute,
    int? sortOrder,
  }) => FeedingSlot(
    id: id ?? this.id,
    scheduleId: scheduleId ?? this.scheduleId,
    catId: catId ?? this.catId,
    label: label ?? this.label,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  FeedingSlot copyWithCompanion(FeedingSlotsCompanion data) {
    return FeedingSlot(
      id: data.id.present ? data.id.value : this.id,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      catId: data.catId.present ? data.catId.value : this.catId,
      label: data.label.present ? data.label.value : this.label,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedingSlot(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('catId: $catId, ')
          ..write('label: $label, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, scheduleId, catId, label, hour, minute, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedingSlot &&
          other.id == this.id &&
          other.scheduleId == this.scheduleId &&
          other.catId == this.catId &&
          other.label == this.label &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.sortOrder == this.sortOrder);
}

class FeedingSlotsCompanion extends UpdateCompanion<FeedingSlot> {
  final Value<String> id;
  final Value<String> scheduleId;
  final Value<String> catId;
  final Value<String> label;
  final Value<int> hour;
  final Value<int> minute;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const FeedingSlotsCompanion({
    this.id = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.catId = const Value.absent(),
    this.label = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeedingSlotsCompanion.insert({
    required String id,
    required String scheduleId,
    required String catId,
    required String label,
    required int hour,
    required int minute,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scheduleId = Value(scheduleId),
       catId = Value(catId),
       label = Value(label),
       hour = Value(hour),
       minute = Value(minute),
       sortOrder = Value(sortOrder);
  static Insertable<FeedingSlot> custom({
    Expression<String>? id,
    Expression<String>? scheduleId,
    Expression<String>? catId,
    Expression<String>? label,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (catId != null) 'cat_id': catId,
      if (label != null) 'label': label,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeedingSlotsCompanion copyWith({
    Value<String>? id,
    Value<String>? scheduleId,
    Value<String>? catId,
    Value<String>? label,
    Value<int>? hour,
    Value<int>? minute,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return FeedingSlotsCompanion(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      catId: catId ?? this.catId,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (catId.present) {
      map['cat_id'] = Variable<String>(catId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedingSlotsCompanion(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('catId: $catId, ')
          ..write('label: $label, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CatsTable cats = $CatsTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $NotificationSettingsTable notificationSettings =
      $NotificationSettingsTable(this);
  late final $FeedingSchedulesTable feedingSchedules = $FeedingSchedulesTable(
    this,
  );
  late final $FeedingSlotsTable feedingSlots = $FeedingSlotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cats,
    events,
    notificationSettings,
    feedingSchedules,
    feedingSlots,
  ];
}

typedef $$CatsTableCreateCompanionBuilder =
    CatsCompanion Function({
      required String id,
      required String name,
      Value<String?> breed,
      Value<DateTime?> dateOfBirth,
      Value<double?> weightKg,
      Value<String?> photoPath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$CatsTableUpdateCompanionBuilder =
    CatsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> breed,
      Value<DateTime?> dateOfBirth,
      Value<double?> weightKg,
      Value<String?> photoPath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CatsTableReferences
    extends BaseReferences<_$AppDatabase, $CatsTable, Cat> {
  $$CatsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventsTable, List<Event>> _eventsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.events,
    aliasName: 'cats__id__events__cat_id',
  );

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.catId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CatsTableFilterComposer extends Composer<_$AppDatabase, $CatsTable> {
  $$CatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eventsRefs(
    Expression<bool> Function($$EventsTableFilterComposer f) f,
  ) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.catId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CatsTableOrderingComposer extends Composer<_$AppDatabase, $CatsTable> {
  $$CatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatsTable> {
  $$CatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get breed =>
      $composableBuilder(column: $table.breed, builder: (column) => column);

  GeneratedColumn<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> eventsRefs<T extends Object>(
    Expression<T> Function($$EventsTableAnnotationComposer a) f,
  ) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.catId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatsTable,
          Cat,
          $$CatsTableFilterComposer,
          $$CatsTableOrderingComposer,
          $$CatsTableAnnotationComposer,
          $$CatsTableCreateCompanionBuilder,
          $$CatsTableUpdateCompanionBuilder,
          (Cat, $$CatsTableReferences),
          Cat,
          PrefetchHooks Function({bool eventsRefs})
        > {
  $$CatsTableTableManager(_$AppDatabase db, $CatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> breed = const Value.absent(),
                Value<DateTime?> dateOfBirth = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatsCompanion(
                id: id,
                name: name,
                breed: breed,
                dateOfBirth: dateOfBirth,
                weightKg: weightKg,
                photoPath: photoPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> breed = const Value.absent(),
                Value<DateTime?> dateOfBirth = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatsCompanion.insert(
                id: id,
                name: name,
                breed: breed,
                dateOfBirth: dateOfBirth,
                weightKg: weightKg,
                photoPath: photoPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CatsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({eventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (eventsRefs) db.events],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventsRefs)
                    await $_getPrefetchedData<Cat, $CatsTable, Event>(
                      currentTable: table,
                      referencedTable: $$CatsTableReferences._eventsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$CatsTableReferences(db, table, p0).eventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.catId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatsTable,
      Cat,
      $$CatsTableFilterComposer,
      $$CatsTableOrderingComposer,
      $$CatsTableAnnotationComposer,
      $$CatsTableCreateCompanionBuilder,
      $$CatsTableUpdateCompanionBuilder,
      (Cat, $$CatsTableReferences),
      Cat,
      PrefetchHooks Function({bool eventsRefs})
    >;
typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      required String id,
      required String catId,
      required String eventType,
      Value<String?> notes,
      Value<String?> metadataJson,
      Value<DateTime> loggedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<String> id,
      Value<String> catId,
      Value<String> eventType,
      Value<String?> notes,
      Value<String?> metadataJson,
      Value<DateTime> loggedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, Event> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CatsTable _catIdTable(_$AppDatabase db) =>
      db.cats.createAlias('events__cat_id__cats__id');

  $$CatsTableProcessedTableManager get catId {
    final $_column = $_itemColumn<String>('cat_id')!;

    final manager = $$CatsTableTableManager(
      $_db,
      $_db.cats,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_catIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CatsTableFilterComposer get catId {
    final $$CatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.catId,
      referencedTable: $db.cats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatsTableFilterComposer(
            $db: $db,
            $table: $db.cats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatsTableOrderingComposer get catId {
    final $$CatsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.catId,
      referencedTable: $db.cats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatsTableOrderingComposer(
            $db: $db,
            $table: $db.cats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CatsTableAnnotationComposer get catId {
    final $$CatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.catId,
      referencedTable: $db.cats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatsTableAnnotationComposer(
            $db: $db,
            $table: $db.cats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, $$EventsTableReferences),
          Event,
          PrefetchHooks Function({bool catId})
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> catId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                catId: catId,
                eventType: eventType,
                notes: notes,
                metadataJson: metadataJson,
                loggedAt: loggedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String catId,
                required String eventType,
                Value<String?> notes = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                catId: catId,
                eventType: eventType,
                notes: notes,
                metadataJson: metadataJson,
                loggedAt: loggedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$EventsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({catId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (catId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.catId,
                                referencedTable: $$EventsTableReferences
                                    ._catIdTable(db),
                                referencedColumn: $$EventsTableReferences
                                    ._catIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, $$EventsTableReferences),
      Event,
      PrefetchHooks Function({bool catId})
    >;
typedef $$NotificationSettingsTableCreateCompanionBuilder =
    NotificationSettingsCompanion Function({
      required String id,
      required String eventType,
      required int thresholdHours,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$NotificationSettingsTableUpdateCompanionBuilder =
    NotificationSettingsCompanion Function({
      Value<String> id,
      Value<String> eventType,
      Value<int> thresholdHours,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$NotificationSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationSettingsTable> {
  $$NotificationSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get thresholdHours => $composableBuilder(
    column: $table.thresholdHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationSettingsTable> {
  $$NotificationSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get thresholdHours => $composableBuilder(
    column: $table.thresholdHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationSettingsTable> {
  $$NotificationSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get thresholdHours => $composableBuilder(
    column: $table.thresholdHours,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$NotificationSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationSettingsTable,
          NotificationSetting,
          $$NotificationSettingsTableFilterComposer,
          $$NotificationSettingsTableOrderingComposer,
          $$NotificationSettingsTableAnnotationComposer,
          $$NotificationSettingsTableCreateCompanionBuilder,
          $$NotificationSettingsTableUpdateCompanionBuilder,
          (
            NotificationSetting,
            BaseReferences<
              _$AppDatabase,
              $NotificationSettingsTable,
              NotificationSetting
            >,
          ),
          NotificationSetting,
          PrefetchHooks Function()
        > {
  $$NotificationSettingsTableTableManager(
    _$AppDatabase db,
    $NotificationSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> thresholdHours = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationSettingsCompanion(
                id: id,
                eventType: eventType,
                thresholdHours: thresholdHours,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventType,
                required int thresholdHours,
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationSettingsCompanion.insert(
                id: id,
                eventType: eventType,
                thresholdHours: thresholdHours,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationSettingsTable,
      NotificationSetting,
      $$NotificationSettingsTableFilterComposer,
      $$NotificationSettingsTableOrderingComposer,
      $$NotificationSettingsTableAnnotationComposer,
      $$NotificationSettingsTableCreateCompanionBuilder,
      $$NotificationSettingsTableUpdateCompanionBuilder,
      (
        NotificationSetting,
        BaseReferences<
          _$AppDatabase,
          $NotificationSettingsTable,
          NotificationSetting
        >,
      ),
      NotificationSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CatsTableTableManager get cats => $$CatsTableTableManager(_db, _db.cats);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$NotificationSettingsTableTableManager get notificationSettings =>
      $$NotificationSettingsTableTableManager(_db, _db.notificationSettings);
}
