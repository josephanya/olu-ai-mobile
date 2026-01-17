import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:olu_ai/features/visits/data/visit_model.dart';
import 'package:olu_ai/features/visits/data/visit_repository.dart';

void main() {
  late Isar isar;
  late VisitRepository repository;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [VisitSchema],
      directory: Directory.systemTemp.createTempSync().path,
    );
    repository = VisitRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('addVisit adds a visit to the database', () async {
    final visit = Visit()
      ..patientId = 1
      ..audioPath = '/path/to/audio.m4a'
      ..transcript = 'Test transcript';

    await repository.addVisit(visit);

    final savedVisit = await repository.getVisit(visit.id);
    expect(savedVisit, isNotNull);
    expect(savedVisit!.transcript, 'Test transcript');
  });

  test('getVisitsForPatient returns visits for specific patient', () async {
    final visit1 = Visit()..patientId = 1;
    final visit2 = Visit()..patientId = 2;
    final visit3 = Visit()..patientId = 1;

    await repository.addVisit(visit1);
    await repository.addVisit(visit2);
    await repository.addVisit(visit3);

    final visits = await repository.getVisitsForPatient(1);
    expect(visits.length, 2);
  });
}
