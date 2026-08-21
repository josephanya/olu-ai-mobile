import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olu_ai/core/database/database.dart';

const benchmarkStatusNotApplicable = 'not_applicable';
const benchmarkStatusPending = 'pending_benchmark_reupload';
const benchmarkStatusSynced = 'benchmark_synced';
const benchmarkStatusFailed = 'benchmark_failed';
const asrSourceSaharaStreaming = 'sahara_streaming';
const asrSourceSherpaLocal = 'sherpa_local';
const asrSourceMixed = 'mixed';
const transcriptionSourceSaharaBenchmark = 'sahara_v2_benchmark';
const transcriptionSourceSherpaLocal = 'sherpa_local';

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

  Future<List<Visit>> getPendingBenchmarkVisits() async {
    return await (db.select(db.visits)
          ..where((t) => t.benchmarkSyncStatus.equals(benchmarkStatusPending)))
        .get();
  }

  Future<int> addTranscription(TranscriptionsCompanion transcription) async {
    return await db.into(db.transcriptions).insert(transcription);
  }

  Future<void> updateBenchmarkSyncStatus({
    required int visitId,
    required String status,
  }) async {
    await (db.update(db.visits)..where((t) => t.id.equals(visitId))).write(
      VisitsCompanion(benchmarkSyncStatus: Value(status)),
    );
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
