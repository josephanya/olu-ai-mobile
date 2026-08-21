import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

class Patients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get village => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Visits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get audioPath => text().nullable()();
  TextColumn get transcript => text().nullable()();
  TextColumn get aiAnalysis => text().nullable()();
  TextColumn get chwNotes => text().nullable()();
  TextColumn get asrSource =>
      text().withDefault(const Constant('sherpa_local'))();
  TextColumn get languageCode => text().withDefault(const Constant('sw'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Transcriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get visitId => integer().references(Visits, #id)();
  TextColumn get source => text()();
  TextColumn get transcript => text()();
  TextColumn get languageCode => text().nullable()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get processingLatencyMs => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();
  BoolColumn get usedForClinicalPipeline => boolean()();
}

@DriftDatabase(tables: [Patients, Visits, Transcriptions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(visits, visits.asrSource);
          await m.addColumn(visits, visits.languageCode);
          await m.createTable(transcriptions);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
