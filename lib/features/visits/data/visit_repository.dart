import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:olu_ai/core/database/isar_database.dart';
import 'package:olu_ai/features/visits/data/visit_model.dart';

part 'visit_repository.g.dart';

class VisitRepository {
  final Isar isar;

  VisitRepository(this.isar);

  Future<List<Visit>> getVisitsForPatient(int patientId) async {
    return isar.visits.where().patientIdEqualTo(patientId).findAll();
  }

  Future<Visit?> getVisit(int id) async {
    return isar.visits.get(id);
  }

  Future<void> addVisit(Visit visit) async {
    await isar.writeTxn(() async {
      await isar.visits.put(visit);
    });
  }

  Future<void> updateVisit(Visit visit) async {
    await isar.writeTxn(() async {
      await isar.visits.put(visit);
    });
  }

  Future<void> deleteVisit(int id) async {
    await isar.writeTxn(() async {
      await isar.visits.delete(id);
    });
  }
}

@riverpod
Future<VisitRepository> visitRepository(VisitRepositoryRef ref) async {
  final isar = await ref.watch(isarDatabaseProvider.future);
  return VisitRepository(isar);
}
