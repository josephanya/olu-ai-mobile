import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:olu_ai/features/patients/data/patient_model.dart';
import 'package:olu_ai/features/patients/data/patient_repository.dart';

void main() {
  late Isar isar;
  late PatientRepository repository;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [PatientSchema],
      directory: Directory.systemTemp.createTempSync().path,
    );
    repository = PatientRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('addPatient adds a patient to the database', () async {
    final patient = Patient()
      ..firstName = 'John'
      ..lastName = 'Doe'
      ..village = 'Test Village';

    await repository.addPatient(patient);

    final savedPatient = await repository.getPatient(patient.id);
    expect(savedPatient, isNotNull);
    expect(savedPatient!.firstName, 'John');
    expect(savedPatient.lastName, 'Doe');
  });

  test('getAllPatients returns all patients', () async {
    final patient1 = Patient()..firstName = 'A'..lastName = 'B';
    final patient2 = Patient()..firstName = 'C'..lastName = 'D';

    await repository.addPatient(patient1);
    await repository.addPatient(patient2);

    final patients = await repository.getAllPatients();
    expect(patients.length, 2);
  });
}
