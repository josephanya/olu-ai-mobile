import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olu_ai/core/database/database.dart';

class VisitRepository {
  final AppDatabase db;

  VisitRepository(this.db);

  Future<List<Visit>> getVisitsForPatient(int patientId) async {
    return await (db.select(db.visits)
          ..where((t) => t.patientId.equals(patientId)))
        .get();
  }

  Future<Visit?> getVisit(int id) async {
    return await (db.select(db.visits)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> addVisit(VisitsCompanion visit) async {
    return await db.into(db.visits).insert(visit);
  }

  Future<void> updateVisit(VisitsCompanion visit) async {
    await db.update(db.visits).replace(visit);
  }

  Future<void> deleteVisit(int id) async {
    await (db.delete(db.visits)..where((t) => t.id.equals(id))).go();
  }
}

final visitRepositoryProvider = FutureProvider<VisitRepository>((ref) async {
  final db = ref.watch(databaseProvider);
  return VisitRepository(db);
});
