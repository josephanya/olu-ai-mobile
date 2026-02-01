import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olu_ai/core/database/database.dart';
import 'package:olu_ai/features/visits/data/visit_repository.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase db;
  late VisitRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = VisitRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addVisit adds a visit to the database', () async {
    final visit = VisitsCompanion.insert(
      patientId: 1,
      audioPath: const drift.Value('/path/to/audio.m4a'),
      transcript: const drift.Value('Test transcript'),
    );

    final id = await repository.addVisit(visit);

    final savedVisit = await repository.getVisit(id);
    expect(savedVisit, isNotNull);
    expect(savedVisit!.transcript, 'Test transcript');
  });

  test('getVisitsForPatient returns visits for specific patient', () async {
    await repository.addVisit(VisitsCompanion.insert(patientId: 1));
    await repository.addVisit(VisitsCompanion.insert(patientId: 2));
    await repository.addVisit(VisitsCompanion.insert(patientId: 1));

    final visits = await repository.getVisitsForPatient(1);
    expect(visits.length, 2);
  });
}
