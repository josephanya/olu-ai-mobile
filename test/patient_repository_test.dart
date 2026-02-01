import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olu_ai/core/database/database.dart';
import 'package:olu_ai/features/patients/data/patient_repository.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase db;
  late PatientRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = PatientRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addPatient adds a patient to the database', () async {
    final patient = PatientsCompanion.insert(
      firstName: 'John',
      lastName: 'Doe',
      village: const drift.Value('Test Village'),
    );

    final id = await repository.addPatient(patient);

    final savedPatient = await repository.getPatient(id);
    expect(savedPatient, isNotNull);
    expect(savedPatient!.firstName, 'John');
    expect(savedPatient.lastName, 'Doe');
  });

  test('getAllPatients returns all patients', () async {
    await repository
        .addPatient(PatientsCompanion.insert(firstName: 'A', lastName: 'B'));
    await repository
        .addPatient(PatientsCompanion.insert(firstName: 'C', lastName: 'D'));

    final patients = await repository.getAllPatients();
    expect(patients.length, 2);
  });
}
