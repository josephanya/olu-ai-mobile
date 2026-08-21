// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PatientsTable extends Patients with TableInfo<$PatientsTable, Patient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastNameMeta =
      const VerificationMeta('lastName');
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
      'last_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateOfBirthMeta =
      const VerificationMeta('dateOfBirth');
  @override
  late final GeneratedColumn<DateTime> dateOfBirth = GeneratedColumn<DateTime>(
      'date_of_birth', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _villageMeta =
      const VerificationMeta('village');
  @override
  late final GeneratedColumn<String> village = GeneratedColumn<String>(
      'village', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        firstName,
        lastName,
        dateOfBirth,
        gender,
        phoneNumber,
        village,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patients';
  @override
  VerificationContext validateIntegrity(Insertable<Patient> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
          _dateOfBirthMeta,
          dateOfBirth.isAcceptableOrUnknown(
              data['date_of_birth']!, _dateOfBirthMeta));
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    }
    if (data.containsKey('village')) {
      context.handle(_villageMeta,
          village.isAcceptableOrUnknown(data['village']!, _villageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Patient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Patient(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      dateOfBirth: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_of_birth']),
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender']),
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number']),
      village: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}village']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PatientsTable createAlias(String alias) {
    return $PatientsTable(attachedDatabase, alias);
  }
}

class Patient extends DataClass implements Insertable<Patient> {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? village;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Patient(
      {required this.id,
      required this.firstName,
      required this.lastName,
      this.dateOfBirth,
      this.gender,
      this.phoneNumber,
      this.village,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || village != null) {
      map['village'] = Variable<String>(village);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PatientsCompanion toCompanion(bool nullToAbsent) {
    return PatientsCompanion(
      id: Value(id),
      firstName: Value(firstName),
      lastName: Value(lastName),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      gender:
          gender == null && nullToAbsent ? const Value.absent() : Value(gender),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      village: village == null && nullToAbsent
          ? const Value.absent()
          : Value(village),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Patient.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Patient(
      id: serializer.fromJson<int>(json['id']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      dateOfBirth: serializer.fromJson<DateTime?>(json['dateOfBirth']),
      gender: serializer.fromJson<String?>(json['gender']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      village: serializer.fromJson<String?>(json['village']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'dateOfBirth': serializer.toJson<DateTime?>(dateOfBirth),
      'gender': serializer.toJson<String?>(gender),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'village': serializer.toJson<String?>(village),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Patient copyWith(
          {int? id,
          String? firstName,
          String? lastName,
          Value<DateTime?> dateOfBirth = const Value.absent(),
          Value<String?> gender = const Value.absent(),
          Value<String?> phoneNumber = const Value.absent(),
          Value<String?> village = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Patient(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
        gender: gender.present ? gender.value : this.gender,
        phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
        village: village.present ? village.value : this.village,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Patient copyWithCompanion(PatientsCompanion data) {
    return Patient(
      id: data.id.present ? data.id.value : this.id,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      dateOfBirth:
          data.dateOfBirth.present ? data.dateOfBirth.value : this.dateOfBirth,
      gender: data.gender.present ? data.gender.value : this.gender,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      village: data.village.present ? data.village.value : this.village,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Patient(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('gender: $gender, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('village: $village, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, firstName, lastName, dateOfBirth, gender,
      phoneNumber, village, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Patient &&
          other.id == this.id &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.dateOfBirth == this.dateOfBirth &&
          other.gender == this.gender &&
          other.phoneNumber == this.phoneNumber &&
          other.village == this.village &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PatientsCompanion extends UpdateCompanion<Patient> {
  final Value<int> id;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<DateTime?> dateOfBirth;
  final Value<String?> gender;
  final Value<String?> phoneNumber;
  final Value<String?> village;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PatientsCompanion({
    this.id = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.gender = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.village = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PatientsCompanion.insert({
    this.id = const Value.absent(),
    required String firstName,
    required String lastName,
    this.dateOfBirth = const Value.absent(),
    this.gender = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.village = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : firstName = Value(firstName),
        lastName = Value(lastName);
  static Insertable<Patient> custom({
    Expression<int>? id,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<DateTime>? dateOfBirth,
    Expression<String>? gender,
    Expression<String>? phoneNumber,
    Expression<String>? village,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (village != null) 'village': village,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PatientsCompanion copyWith(
      {Value<int>? id,
      Value<String>? firstName,
      Value<String>? lastName,
      Value<DateTime?>? dateOfBirth,
      Value<String?>? gender,
      Value<String?>? phoneNumber,
      Value<String?>? village,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return PatientsCompanion(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      village: village ?? this.village,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (village.present) {
      map['village'] = Variable<String>(village.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientsCompanion(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('gender: $gender, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('village: $village, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $VisitsTable extends Visits with TableInfo<$VisitsTable, Visit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _patientIdMeta =
      const VerificationMeta('patientId');
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
      'patient_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES patients (id)'));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _audioPathMeta =
      const VerificationMeta('audioPath');
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
      'audio_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transcriptMeta =
      const VerificationMeta('transcript');
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
      'transcript', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _aiAnalysisMeta =
      const VerificationMeta('aiAnalysis');
  @override
  late final GeneratedColumn<String> aiAnalysis = GeneratedColumn<String>(
      'ai_analysis', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _chwNotesMeta =
      const VerificationMeta('chwNotes');
  @override
  late final GeneratedColumn<String> chwNotes = GeneratedColumn<String>(
      'chw_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _asrSourceMeta =
      const VerificationMeta('asrSource');
  @override
  late final GeneratedColumn<String> asrSource = GeneratedColumn<String>(
      'asr_source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sherpa_local'));
  static const VerificationMeta _languageCodeMeta =
      const VerificationMeta('languageCode');
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
      'language_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sw'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        patientId,
        timestamp,
        audioPath,
        transcript,
        aiAnalysis,
        chwNotes,
        asrSource,
        languageCode,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(Insertable<Visit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('patient_id')) {
      context.handle(_patientIdMeta,
          patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta));
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('audio_path')) {
      context.handle(_audioPathMeta,
          audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta));
    }
    if (data.containsKey('transcript')) {
      context.handle(
          _transcriptMeta,
          transcript.isAcceptableOrUnknown(
              data['transcript']!, _transcriptMeta));
    }
    if (data.containsKey('ai_analysis')) {
      context.handle(
          _aiAnalysisMeta,
          aiAnalysis.isAcceptableOrUnknown(
              data['ai_analysis']!, _aiAnalysisMeta));
    }
    if (data.containsKey('chw_notes')) {
      context.handle(_chwNotesMeta,
          chwNotes.isAcceptableOrUnknown(data['chw_notes']!, _chwNotesMeta));
    }
    if (data.containsKey('asr_source')) {
      context.handle(_asrSourceMeta,
          asrSource.isAcceptableOrUnknown(data['asr_source']!, _asrSourceMeta));
    }
    if (data.containsKey('language_code')) {
      context.handle(
          _languageCodeMeta,
          languageCode.isAcceptableOrUnknown(
              data['language_code']!, _languageCodeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Visit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Visit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      patientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}patient_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      audioPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_path']),
      transcript: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcript']),
      aiAnalysis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_analysis']),
      chwNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chw_notes']),
      asrSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asr_source'])!,
      languageCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language_code'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }
}

class Visit extends DataClass implements Insertable<Visit> {
  final int id;
  final int patientId;
  final DateTime timestamp;
  final String? audioPath;
  final String? transcript;
  final String? aiAnalysis;
  final String? chwNotes;
  final String asrSource;
  final String languageCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Visit(
      {required this.id,
      required this.patientId,
      required this.timestamp,
      this.audioPath,
      this.transcript,
      this.aiAnalysis,
      this.chwNotes,
      required this.asrSource,
      required this.languageCode,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['patient_id'] = Variable<int>(patientId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    if (!nullToAbsent || aiAnalysis != null) {
      map['ai_analysis'] = Variable<String>(aiAnalysis);
    }
    if (!nullToAbsent || chwNotes != null) {
      map['chw_notes'] = Variable<String>(chwNotes);
    }
    map['asr_source'] = Variable<String>(asrSource);
    map['language_code'] = Variable<String>(languageCode);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      timestamp: Value(timestamp),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      transcript: transcript == null && nullToAbsent
          ? const Value.absent()
          : Value(transcript),
      aiAnalysis: aiAnalysis == null && nullToAbsent
          ? const Value.absent()
          : Value(aiAnalysis),
      chwNotes: chwNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(chwNotes),
      asrSource: Value(asrSource),
      languageCode: Value(languageCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Visit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Visit(
      id: serializer.fromJson<int>(json['id']),
      patientId: serializer.fromJson<int>(json['patientId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      transcript: serializer.fromJson<String?>(json['transcript']),
      aiAnalysis: serializer.fromJson<String?>(json['aiAnalysis']),
      chwNotes: serializer.fromJson<String?>(json['chwNotes']),
      asrSource: serializer.fromJson<String>(json['asrSource']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'patientId': serializer.toJson<int>(patientId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'audioPath': serializer.toJson<String?>(audioPath),
      'transcript': serializer.toJson<String?>(transcript),
      'aiAnalysis': serializer.toJson<String?>(aiAnalysis),
      'chwNotes': serializer.toJson<String?>(chwNotes),
      'asrSource': serializer.toJson<String>(asrSource),
      'languageCode': serializer.toJson<String>(languageCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Visit copyWith(
          {int? id,
          int? patientId,
          DateTime? timestamp,
          Value<String?> audioPath = const Value.absent(),
          Value<String?> transcript = const Value.absent(),
          Value<String?> aiAnalysis = const Value.absent(),
          Value<String?> chwNotes = const Value.absent(),
          String? asrSource,
          String? languageCode,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Visit(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        timestamp: timestamp ?? this.timestamp,
        audioPath: audioPath.present ? audioPath.value : this.audioPath,
        transcript: transcript.present ? transcript.value : this.transcript,
        aiAnalysis: aiAnalysis.present ? aiAnalysis.value : this.aiAnalysis,
        chwNotes: chwNotes.present ? chwNotes.value : this.chwNotes,
        asrSource: asrSource ?? this.asrSource,
        languageCode: languageCode ?? this.languageCode,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Visit copyWithCompanion(VisitsCompanion data) {
    return Visit(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      transcript:
          data.transcript.present ? data.transcript.value : this.transcript,
      aiAnalysis:
          data.aiAnalysis.present ? data.aiAnalysis.value : this.aiAnalysis,
      chwNotes: data.chwNotes.present ? data.chwNotes.value : this.chwNotes,
      asrSource: data.asrSource.present ? data.asrSource.value : this.asrSource,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Visit(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('timestamp: $timestamp, ')
          ..write('audioPath: $audioPath, ')
          ..write('transcript: $transcript, ')
          ..write('aiAnalysis: $aiAnalysis, ')
          ..write('chwNotes: $chwNotes, ')
          ..write('asrSource: $asrSource, ')
          ..write('languageCode: $languageCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      patientId,
      timestamp,
      audioPath,
      transcript,
      aiAnalysis,
      chwNotes,
      asrSource,
      languageCode,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visit &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.timestamp == this.timestamp &&
          other.audioPath == this.audioPath &&
          other.transcript == this.transcript &&
          other.aiAnalysis == this.aiAnalysis &&
          other.chwNotes == this.chwNotes &&
          other.asrSource == this.asrSource &&
          other.languageCode == this.languageCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VisitsCompanion extends UpdateCompanion<Visit> {
  final Value<int> id;
  final Value<int> patientId;
  final Value<DateTime> timestamp;
  final Value<String?> audioPath;
  final Value<String?> transcript;
  final Value<String?> aiAnalysis;
  final Value<String?> chwNotes;
  final Value<String> asrSource;
  final Value<String> languageCode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.transcript = const Value.absent(),
    this.aiAnalysis = const Value.absent(),
    this.chwNotes = const Value.absent(),
    this.asrSource = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  VisitsCompanion.insert({
    this.id = const Value.absent(),
    required int patientId,
    this.timestamp = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.transcript = const Value.absent(),
    this.aiAnalysis = const Value.absent(),
    this.chwNotes = const Value.absent(),
    this.asrSource = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : patientId = Value(patientId);
  static Insertable<Visit> custom({
    Expression<int>? id,
    Expression<int>? patientId,
    Expression<DateTime>? timestamp,
    Expression<String>? audioPath,
    Expression<String>? transcript,
    Expression<String>? aiAnalysis,
    Expression<String>? chwNotes,
    Expression<String>? asrSource,
    Expression<String>? languageCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (timestamp != null) 'timestamp': timestamp,
      if (audioPath != null) 'audio_path': audioPath,
      if (transcript != null) 'transcript': transcript,
      if (aiAnalysis != null) 'ai_analysis': aiAnalysis,
      if (chwNotes != null) 'chw_notes': chwNotes,
      if (asrSource != null) 'asr_source': asrSource,
      if (languageCode != null) 'language_code': languageCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  VisitsCompanion copyWith(
      {Value<int>? id,
      Value<int>? patientId,
      Value<DateTime>? timestamp,
      Value<String?>? audioPath,
      Value<String?>? transcript,
      Value<String?>? aiAnalysis,
      Value<String?>? chwNotes,
      Value<String>? asrSource,
      Value<String>? languageCode,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return VisitsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      timestamp: timestamp ?? this.timestamp,
      audioPath: audioPath ?? this.audioPath,
      transcript: transcript ?? this.transcript,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      chwNotes: chwNotes ?? this.chwNotes,
      asrSource: asrSource ?? this.asrSource,
      languageCode: languageCode ?? this.languageCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (aiAnalysis.present) {
      map['ai_analysis'] = Variable<String>(aiAnalysis.value);
    }
    if (chwNotes.present) {
      map['chw_notes'] = Variable<String>(chwNotes.value);
    }
    if (asrSource.present) {
      map['asr_source'] = Variable<String>(asrSource.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('timestamp: $timestamp, ')
          ..write('audioPath: $audioPath, ')
          ..write('transcript: $transcript, ')
          ..write('aiAnalysis: $aiAnalysis, ')
          ..write('chwNotes: $chwNotes, ')
          ..write('asrSource: $asrSource, ')
          ..write('languageCode: $languageCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TranscriptionsTable extends Transcriptions
    with TableInfo<$TranscriptionsTable, Transcription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _visitIdMeta =
      const VerificationMeta('visitId');
  @override
  late final GeneratedColumn<int> visitId = GeneratedColumn<int>(
      'visit_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES visits (id)'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transcriptMeta =
      const VerificationMeta('transcript');
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
      'transcript', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _languageCodeMeta =
      const VerificationMeta('languageCode');
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
      'language_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _processingLatencyMsMeta =
      const VerificationMeta('processingLatencyMs');
  @override
  late final GeneratedColumn<int> processingLatencyMs = GeneratedColumn<int>(
      'processing_latency_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _usedForClinicalPipelineMeta =
      const VerificationMeta('usedForClinicalPipeline');
  @override
  late final GeneratedColumn<bool> usedForClinicalPipeline =
      GeneratedColumn<bool>('used_for_clinical_pipeline', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("used_for_clinical_pipeline" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        visitId,
        source,
        transcript,
        languageCode,
        completedAt,
        processingLatencyMs,
        errorMessage,
        usedForClinicalPipeline
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transcriptions';
  @override
  VerificationContext validateIntegrity(Insertable<Transcription> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('visit_id')) {
      context.handle(_visitIdMeta,
          visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta));
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('transcript')) {
      context.handle(
          _transcriptMeta,
          transcript.isAcceptableOrUnknown(
              data['transcript']!, _transcriptMeta));
    } else if (isInserting) {
      context.missing(_transcriptMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
          _languageCodeMeta,
          languageCode.isAcceptableOrUnknown(
              data['language_code']!, _languageCodeMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('processing_latency_ms')) {
      context.handle(
          _processingLatencyMsMeta,
          processingLatencyMs.isAcceptableOrUnknown(
              data['processing_latency_ms']!, _processingLatencyMsMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('used_for_clinical_pipeline')) {
      context.handle(
          _usedForClinicalPipelineMeta,
          usedForClinicalPipeline.isAcceptableOrUnknown(
              data['used_for_clinical_pipeline']!,
              _usedForClinicalPipelineMeta));
    } else if (isInserting) {
      context.missing(_usedForClinicalPipelineMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transcription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transcription(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      visitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}visit_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      transcript: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcript'])!,
      languageCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language_code']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
      processingLatencyMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}processing_latency_ms']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      usedForClinicalPipeline: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}used_for_clinical_pipeline'])!,
    );
  }

  @override
  $TranscriptionsTable createAlias(String alias) {
    return $TranscriptionsTable(attachedDatabase, alias);
  }
}

class Transcription extends DataClass implements Insertable<Transcription> {
  final int id;
  final int visitId;
  final String source;
  final String transcript;
  final String? languageCode;
  final DateTime completedAt;
  final int? processingLatencyMs;
  final String? errorMessage;
  final bool usedForClinicalPipeline;
  const Transcription(
      {required this.id,
      required this.visitId,
      required this.source,
      required this.transcript,
      this.languageCode,
      required this.completedAt,
      this.processingLatencyMs,
      this.errorMessage,
      required this.usedForClinicalPipeline});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['visit_id'] = Variable<int>(visitId);
    map['source'] = Variable<String>(source);
    map['transcript'] = Variable<String>(transcript);
    if (!nullToAbsent || languageCode != null) {
      map['language_code'] = Variable<String>(languageCode);
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    if (!nullToAbsent || processingLatencyMs != null) {
      map['processing_latency_ms'] = Variable<int>(processingLatencyMs);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['used_for_clinical_pipeline'] = Variable<bool>(usedForClinicalPipeline);
    return map;
  }

  TranscriptionsCompanion toCompanion(bool nullToAbsent) {
    return TranscriptionsCompanion(
      id: Value(id),
      visitId: Value(visitId),
      source: Value(source),
      transcript: Value(transcript),
      languageCode: languageCode == null && nullToAbsent
          ? const Value.absent()
          : Value(languageCode),
      completedAt: Value(completedAt),
      processingLatencyMs: processingLatencyMs == null && nullToAbsent
          ? const Value.absent()
          : Value(processingLatencyMs),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      usedForClinicalPipeline: Value(usedForClinicalPipeline),
    );
  }

  factory Transcription.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transcription(
      id: serializer.fromJson<int>(json['id']),
      visitId: serializer.fromJson<int>(json['visitId']),
      source: serializer.fromJson<String>(json['source']),
      transcript: serializer.fromJson<String>(json['transcript']),
      languageCode: serializer.fromJson<String?>(json['languageCode']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      processingLatencyMs:
          serializer.fromJson<int?>(json['processingLatencyMs']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      usedForClinicalPipeline:
          serializer.fromJson<bool>(json['usedForClinicalPipeline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'visitId': serializer.toJson<int>(visitId),
      'source': serializer.toJson<String>(source),
      'transcript': serializer.toJson<String>(transcript),
      'languageCode': serializer.toJson<String?>(languageCode),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'processingLatencyMs': serializer.toJson<int?>(processingLatencyMs),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'usedForClinicalPipeline':
          serializer.toJson<bool>(usedForClinicalPipeline),
    };
  }

  Transcription copyWith(
          {int? id,
          int? visitId,
          String? source,
          String? transcript,
          Value<String?> languageCode = const Value.absent(),
          DateTime? completedAt,
          Value<int?> processingLatencyMs = const Value.absent(),
          Value<String?> errorMessage = const Value.absent(),
          bool? usedForClinicalPipeline}) =>
      Transcription(
        id: id ?? this.id,
        visitId: visitId ?? this.visitId,
        source: source ?? this.source,
        transcript: transcript ?? this.transcript,
        languageCode:
            languageCode.present ? languageCode.value : this.languageCode,
        completedAt: completedAt ?? this.completedAt,
        processingLatencyMs: processingLatencyMs.present
            ? processingLatencyMs.value
            : this.processingLatencyMs,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        usedForClinicalPipeline:
            usedForClinicalPipeline ?? this.usedForClinicalPipeline,
      );
  Transcription copyWithCompanion(TranscriptionsCompanion data) {
    return Transcription(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      source: data.source.present ? data.source.value : this.source,
      transcript:
          data.transcript.present ? data.transcript.value : this.transcript,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      processingLatencyMs: data.processingLatencyMs.present
          ? data.processingLatencyMs.value
          : this.processingLatencyMs,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      usedForClinicalPipeline: data.usedForClinicalPipeline.present
          ? data.usedForClinicalPipeline.value
          : this.usedForClinicalPipeline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transcription(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('source: $source, ')
          ..write('transcript: $transcript, ')
          ..write('languageCode: $languageCode, ')
          ..write('completedAt: $completedAt, ')
          ..write('processingLatencyMs: $processingLatencyMs, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('usedForClinicalPipeline: $usedForClinicalPipeline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, visitId, source, transcript, languageCode,
      completedAt, processingLatencyMs, errorMessage, usedForClinicalPipeline);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transcription &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.source == this.source &&
          other.transcript == this.transcript &&
          other.languageCode == this.languageCode &&
          other.completedAt == this.completedAt &&
          other.processingLatencyMs == this.processingLatencyMs &&
          other.errorMessage == this.errorMessage &&
          other.usedForClinicalPipeline == this.usedForClinicalPipeline);
}

class TranscriptionsCompanion extends UpdateCompanion<Transcription> {
  final Value<int> id;
  final Value<int> visitId;
  final Value<String> source;
  final Value<String> transcript;
  final Value<String?> languageCode;
  final Value<DateTime> completedAt;
  final Value<int?> processingLatencyMs;
  final Value<String?> errorMessage;
  final Value<bool> usedForClinicalPipeline;
  const TranscriptionsCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.source = const Value.absent(),
    this.transcript = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.processingLatencyMs = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.usedForClinicalPipeline = const Value.absent(),
  });
  TranscriptionsCompanion.insert({
    this.id = const Value.absent(),
    required int visitId,
    required String source,
    required String transcript,
    this.languageCode = const Value.absent(),
    required DateTime completedAt,
    this.processingLatencyMs = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required bool usedForClinicalPipeline,
  })  : visitId = Value(visitId),
        source = Value(source),
        transcript = Value(transcript),
        completedAt = Value(completedAt),
        usedForClinicalPipeline = Value(usedForClinicalPipeline);
  static Insertable<Transcription> custom({
    Expression<int>? id,
    Expression<int>? visitId,
    Expression<String>? source,
    Expression<String>? transcript,
    Expression<String>? languageCode,
    Expression<DateTime>? completedAt,
    Expression<int>? processingLatencyMs,
    Expression<String>? errorMessage,
    Expression<bool>? usedForClinicalPipeline,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (source != null) 'source': source,
      if (transcript != null) 'transcript': transcript,
      if (languageCode != null) 'language_code': languageCode,
      if (completedAt != null) 'completed_at': completedAt,
      if (processingLatencyMs != null)
        'processing_latency_ms': processingLatencyMs,
      if (errorMessage != null) 'error_message': errorMessage,
      if (usedForClinicalPipeline != null)
        'used_for_clinical_pipeline': usedForClinicalPipeline,
    });
  }

  TranscriptionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? visitId,
      Value<String>? source,
      Value<String>? transcript,
      Value<String?>? languageCode,
      Value<DateTime>? completedAt,
      Value<int?>? processingLatencyMs,
      Value<String?>? errorMessage,
      Value<bool>? usedForClinicalPipeline}) {
    return TranscriptionsCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      source: source ?? this.source,
      transcript: transcript ?? this.transcript,
      languageCode: languageCode ?? this.languageCode,
      completedAt: completedAt ?? this.completedAt,
      processingLatencyMs: processingLatencyMs ?? this.processingLatencyMs,
      errorMessage: errorMessage ?? this.errorMessage,
      usedForClinicalPipeline:
          usedForClinicalPipeline ?? this.usedForClinicalPipeline,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<int>(visitId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (processingLatencyMs.present) {
      map['processing_latency_ms'] = Variable<int>(processingLatencyMs.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (usedForClinicalPipeline.present) {
      map['used_for_clinical_pipeline'] =
          Variable<bool>(usedForClinicalPipeline.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('source: $source, ')
          ..write('transcript: $transcript, ')
          ..write('languageCode: $languageCode, ')
          ..write('completedAt: $completedAt, ')
          ..write('processingLatencyMs: $processingLatencyMs, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('usedForClinicalPipeline: $usedForClinicalPipeline')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PatientsTable patients = $PatientsTable(this);
  late final $VisitsTable visits = $VisitsTable(this);
  late final $TranscriptionsTable transcriptions = $TranscriptionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [patients, visits, transcriptions];
}

typedef $$PatientsTableCreateCompanionBuilder = PatientsCompanion Function({
  Value<int> id,
  required String firstName,
  required String lastName,
  Value<DateTime?> dateOfBirth,
  Value<String?> gender,
  Value<String?> phoneNumber,
  Value<String?> village,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$PatientsTableUpdateCompanionBuilder = PatientsCompanion Function({
  Value<int> id,
  Value<String> firstName,
  Value<String> lastName,
  Value<DateTime?> dateOfBirth,
  Value<String?> gender,
  Value<String?> phoneNumber,
  Value<String?> village,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$PatientsTableReferences
    extends BaseReferences<_$AppDatabase, $PatientsTable, Patient> {
  $$PatientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VisitsTable, List<Visit>> _visitsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.visits,
          aliasName: $_aliasNameGenerator(db.patients.id, db.visits.patientId));

  $$VisitsTableProcessedTableManager get visitsRefs {
    final manager = $$VisitsTableTableManager($_db, $_db.visits)
        .filter((f) => f.patientId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_visitsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PatientsTableFilterComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get village => $composableBuilder(
      column: $table.village, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> visitsRefs(
      Expression<bool> Function($$VisitsTableFilterComposer f) f) {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.visits,
        getReferencedColumn: (t) => t.patientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VisitsTableFilterComposer(
              $db: $db,
              $table: $db.visits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PatientsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get village => $composableBuilder(
      column: $table.village, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PatientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<DateTime> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<String> get village =>
      $composableBuilder(column: $table.village, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> visitsRefs<T extends Object>(
      Expression<T> Function($$VisitsTableAnnotationComposer a) f) {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.visits,
        getReferencedColumn: (t) => t.patientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VisitsTableAnnotationComposer(
              $db: $db,
              $table: $db.visits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PatientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PatientsTable,
    Patient,
    $$PatientsTableFilterComposer,
    $$PatientsTableOrderingComposer,
    $$PatientsTableAnnotationComposer,
    $$PatientsTableCreateCompanionBuilder,
    $$PatientsTableUpdateCompanionBuilder,
    (Patient, $$PatientsTableReferences),
    Patient,
    PrefetchHooks Function({bool visitsRefs})> {
  $$PatientsTableTableManager(_$AppDatabase db, $PatientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> lastName = const Value.absent(),
            Value<DateTime?> dateOfBirth = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<String?> phoneNumber = const Value.absent(),
            Value<String?> village = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PatientsCompanion(
            id: id,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            gender: gender,
            phoneNumber: phoneNumber,
            village: village,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String firstName,
            required String lastName,
            Value<DateTime?> dateOfBirth = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<String?> phoneNumber = const Value.absent(),
            Value<String?> village = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PatientsCompanion.insert(
            id: id,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            gender: gender,
            phoneNumber: phoneNumber,
            village: village,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PatientsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({visitsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (visitsRefs) db.visits],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (visitsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$PatientsTableReferences._visitsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PatientsTableReferences(db, table, p0).visitsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.patientId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PatientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PatientsTable,
    Patient,
    $$PatientsTableFilterComposer,
    $$PatientsTableOrderingComposer,
    $$PatientsTableAnnotationComposer,
    $$PatientsTableCreateCompanionBuilder,
    $$PatientsTableUpdateCompanionBuilder,
    (Patient, $$PatientsTableReferences),
    Patient,
    PrefetchHooks Function({bool visitsRefs})>;
typedef $$VisitsTableCreateCompanionBuilder = VisitsCompanion Function({
  Value<int> id,
  required int patientId,
  Value<DateTime> timestamp,
  Value<String?> audioPath,
  Value<String?> transcript,
  Value<String?> aiAnalysis,
  Value<String?> chwNotes,
  Value<String> asrSource,
  Value<String> languageCode,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$VisitsTableUpdateCompanionBuilder = VisitsCompanion Function({
  Value<int> id,
  Value<int> patientId,
  Value<DateTime> timestamp,
  Value<String?> audioPath,
  Value<String?> transcript,
  Value<String?> aiAnalysis,
  Value<String?> chwNotes,
  Value<String> asrSource,
  Value<String> languageCode,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$VisitsTableReferences
    extends BaseReferences<_$AppDatabase, $VisitsTable, Visit> {
  $$VisitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PatientsTable _patientIdTable(_$AppDatabase db) => db.patients
      .createAlias($_aliasNameGenerator(db.visits.patientId, db.patients.id));

  $$PatientsTableProcessedTableManager? get patientId {
    if ($_item.patientId == null) return null;
    final manager = $$PatientsTableTableManager($_db, $_db.patients)
        .filter((f) => f.id($_item.patientId!));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TranscriptionsTable, List<Transcription>>
      _transcriptionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transcriptions,
              aliasName: $_aliasNameGenerator(
                  db.visits.id, db.transcriptions.visitId));

  $$TranscriptionsTableProcessedTableManager get transcriptionsRefs {
    final manager = $$TranscriptionsTableTableManager($_db, $_db.transcriptions)
        .filter((f) => f.visitId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_transcriptionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiAnalysis => $composableBuilder(
      column: $table.aiAnalysis, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chwNotes => $composableBuilder(
      column: $table.chwNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get asrSource => $composableBuilder(
      column: $table.asrSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get languageCode => $composableBuilder(
      column: $table.languageCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.patientId,
        referencedTable: $db.patients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PatientsTableFilterComposer(
              $db: $db,
              $table: $db.patients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transcriptionsRefs(
      Expression<bool> Function($$TranscriptionsTableFilterComposer f) f) {
    final $$TranscriptionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transcriptions,
        getReferencedColumn: (t) => t.visitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TranscriptionsTableFilterComposer(
              $db: $db,
              $table: $db.transcriptions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiAnalysis => $composableBuilder(
      column: $table.aiAnalysis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chwNotes => $composableBuilder(
      column: $table.chwNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get asrSource => $composableBuilder(
      column: $table.asrSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get languageCode => $composableBuilder(
      column: $table.languageCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.patientId,
        referencedTable: $db.patients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PatientsTableOrderingComposer(
              $db: $db,
              $table: $db.patients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => column);

  GeneratedColumn<String> get aiAnalysis => $composableBuilder(
      column: $table.aiAnalysis, builder: (column) => column);

  GeneratedColumn<String> get chwNotes =>
      $composableBuilder(column: $table.chwNotes, builder: (column) => column);

  GeneratedColumn<String> get asrSource =>
      $composableBuilder(column: $table.asrSource, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
      column: $table.languageCode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.patientId,
        referencedTable: $db.patients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PatientsTableAnnotationComposer(
              $db: $db,
              $table: $db.patients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transcriptionsRefs<T extends Object>(
      Expression<T> Function($$TranscriptionsTableAnnotationComposer a) f) {
    final $$TranscriptionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transcriptions,
        getReferencedColumn: (t) => t.visitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TranscriptionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transcriptions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$VisitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VisitsTable,
    Visit,
    $$VisitsTableFilterComposer,
    $$VisitsTableOrderingComposer,
    $$VisitsTableAnnotationComposer,
    $$VisitsTableCreateCompanionBuilder,
    $$VisitsTableUpdateCompanionBuilder,
    (Visit, $$VisitsTableReferences),
    Visit,
    PrefetchHooks Function({bool patientId, bool transcriptionsRefs})> {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> patientId = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<String?> transcript = const Value.absent(),
            Value<String?> aiAnalysis = const Value.absent(),
            Value<String?> chwNotes = const Value.absent(),
            Value<String> asrSource = const Value.absent(),
            Value<String> languageCode = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              VisitsCompanion(
            id: id,
            patientId: patientId,
            timestamp: timestamp,
            audioPath: audioPath,
            transcript: transcript,
            aiAnalysis: aiAnalysis,
            chwNotes: chwNotes,
            asrSource: asrSource,
            languageCode: languageCode,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int patientId,
            Value<DateTime> timestamp = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<String?> transcript = const Value.absent(),
            Value<String?> aiAnalysis = const Value.absent(),
            Value<String?> chwNotes = const Value.absent(),
            Value<String> asrSource = const Value.absent(),
            Value<String> languageCode = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              VisitsCompanion.insert(
            id: id,
            patientId: patientId,
            timestamp: timestamp,
            audioPath: audioPath,
            transcript: transcript,
            aiAnalysis: aiAnalysis,
            chwNotes: chwNotes,
            asrSource: asrSource,
            languageCode: languageCode,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$VisitsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {patientId = false, transcriptionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transcriptionsRefs) db.transcriptions
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (patientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.patientId,
                    referencedTable:
                        $$VisitsTableReferences._patientIdTable(db),
                    referencedColumn:
                        $$VisitsTableReferences._patientIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transcriptionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$VisitsTableReferences
                            ._transcriptionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VisitsTableReferences(db, table, p0)
                                .transcriptionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.visitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$VisitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VisitsTable,
    Visit,
    $$VisitsTableFilterComposer,
    $$VisitsTableOrderingComposer,
    $$VisitsTableAnnotationComposer,
    $$VisitsTableCreateCompanionBuilder,
    $$VisitsTableUpdateCompanionBuilder,
    (Visit, $$VisitsTableReferences),
    Visit,
    PrefetchHooks Function({bool patientId, bool transcriptionsRefs})>;
typedef $$TranscriptionsTableCreateCompanionBuilder = TranscriptionsCompanion
    Function({
  Value<int> id,
  required int visitId,
  required String source,
  required String transcript,
  Value<String?> languageCode,
  required DateTime completedAt,
  Value<int?> processingLatencyMs,
  Value<String?> errorMessage,
  required bool usedForClinicalPipeline,
});
typedef $$TranscriptionsTableUpdateCompanionBuilder = TranscriptionsCompanion
    Function({
  Value<int> id,
  Value<int> visitId,
  Value<String> source,
  Value<String> transcript,
  Value<String?> languageCode,
  Value<DateTime> completedAt,
  Value<int?> processingLatencyMs,
  Value<String?> errorMessage,
  Value<bool> usedForClinicalPipeline,
});

final class $$TranscriptionsTableReferences
    extends BaseReferences<_$AppDatabase, $TranscriptionsTable, Transcription> {
  $$TranscriptionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $VisitsTable _visitIdTable(_$AppDatabase db) => db.visits.createAlias(
      $_aliasNameGenerator(db.transcriptions.visitId, db.visits.id));

  $$VisitsTableProcessedTableManager? get visitId {
    if ($_item.visitId == null) return null;
    final manager = $$VisitsTableTableManager($_db, $_db.visits)
        .filter((f) => f.id($_item.visitId!));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TranscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $TranscriptionsTable> {
  $$TranscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get languageCode => $composableBuilder(
      column: $table.languageCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get processingLatencyMs => $composableBuilder(
      column: $table.processingLatencyMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get usedForClinicalPipeline => $composableBuilder(
      column: $table.usedForClinicalPipeline,
      builder: (column) => ColumnFilters(column));

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.visitId,
        referencedTable: $db.visits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VisitsTableFilterComposer(
              $db: $db,
              $table: $db.visits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TranscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TranscriptionsTable> {
  $$TranscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get languageCode => $composableBuilder(
      column: $table.languageCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get processingLatencyMs => $composableBuilder(
      column: $table.processingLatencyMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get usedForClinicalPipeline => $composableBuilder(
      column: $table.usedForClinicalPipeline,
      builder: (column) => ColumnOrderings(column));

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.visitId,
        referencedTable: $db.visits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VisitsTableOrderingComposer(
              $db: $db,
              $table: $db.visits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TranscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranscriptionsTable> {
  $$TranscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
      column: $table.languageCode, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get processingLatencyMs => $composableBuilder(
      column: $table.processingLatencyMs, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<bool> get usedForClinicalPipeline => $composableBuilder(
      column: $table.usedForClinicalPipeline, builder: (column) => column);

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.visitId,
        referencedTable: $db.visits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VisitsTableAnnotationComposer(
              $db: $db,
              $table: $db.visits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TranscriptionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TranscriptionsTable,
    Transcription,
    $$TranscriptionsTableFilterComposer,
    $$TranscriptionsTableOrderingComposer,
    $$TranscriptionsTableAnnotationComposer,
    $$TranscriptionsTableCreateCompanionBuilder,
    $$TranscriptionsTableUpdateCompanionBuilder,
    (Transcription, $$TranscriptionsTableReferences),
    Transcription,
    PrefetchHooks Function({bool visitId})> {
  $$TranscriptionsTableTableManager(
      _$AppDatabase db, $TranscriptionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> visitId = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> transcript = const Value.absent(),
            Value<String?> languageCode = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
            Value<int?> processingLatencyMs = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<bool> usedForClinicalPipeline = const Value.absent(),
          }) =>
              TranscriptionsCompanion(
            id: id,
            visitId: visitId,
            source: source,
            transcript: transcript,
            languageCode: languageCode,
            completedAt: completedAt,
            processingLatencyMs: processingLatencyMs,
            errorMessage: errorMessage,
            usedForClinicalPipeline: usedForClinicalPipeline,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int visitId,
            required String source,
            required String transcript,
            Value<String?> languageCode = const Value.absent(),
            required DateTime completedAt,
            Value<int?> processingLatencyMs = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            required bool usedForClinicalPipeline,
          }) =>
              TranscriptionsCompanion.insert(
            id: id,
            visitId: visitId,
            source: source,
            transcript: transcript,
            languageCode: languageCode,
            completedAt: completedAt,
            processingLatencyMs: processingLatencyMs,
            errorMessage: errorMessage,
            usedForClinicalPipeline: usedForClinicalPipeline,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TranscriptionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (visitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.visitId,
                    referencedTable:
                        $$TranscriptionsTableReferences._visitIdTable(db),
                    referencedColumn:
                        $$TranscriptionsTableReferences._visitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TranscriptionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TranscriptionsTable,
    Transcription,
    $$TranscriptionsTableFilterComposer,
    $$TranscriptionsTableOrderingComposer,
    $$TranscriptionsTableAnnotationComposer,
    $$TranscriptionsTableCreateCompanionBuilder,
    $$TranscriptionsTableUpdateCompanionBuilder,
    (Transcription, $$TranscriptionsTableReferences),
    Transcription,
    PrefetchHooks Function({bool visitId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db, _db.patients);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$TranscriptionsTableTableManager get transcriptions =>
      $$TranscriptionsTableTableManager(_db, _db.transcriptions);
}
