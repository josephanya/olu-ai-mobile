import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olu_ai/core/database/database.dart';

class PatientRepository {
  final AppDatabase db;

  PatientRepository(this.db);

  Future<List<Patient>> getAllPatients() async {
    return await db.select(db.patients).get();
  }

  Future<Patient?> getPatient(int id) async {
    return await (db.select(db.patients)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> addPatient(PatientsCompanion patient) async {
    return await db.into(db.patients).insert(patient);
  }

  Future<void> updatePatient(PatientsCompanion patient) async {
    await db.update(db.patients).replace(patient);
  }

  Future<void> deletePatient(int id) async {
    await (db.delete(db.patients)..where((t) => t.id.equals(id))).go();
  }
}

final patientRepositoryProvider =
    FutureProvider<PatientRepository>((ref) async {
  final db = ref.watch(databaseProvider);
  return PatientRepository(db);
});
