import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:olu_ai/core/database/isar_database.dart';
import 'package:olu_ai/features/patients/data/patient_model.dart';

part 'patient_repository.g.dart';

class PatientRepository {
  final Isar isar;

  PatientRepository(this.isar);

  Future<List<Patient>> getAllPatients() async {
    return isar.patients.where().findAll();
  }

  Future<Patient?> getPatient(int id) async {
    return isar.patients.get(id);
  }

  Future<void> addPatient(Patient patient) async {
    await isar.writeTxn(() async {
      await isar.patients.put(patient);
    });
  }

  Future<void> updatePatient(Patient patient) async {
    await isar.writeTxn(() async {
      await isar.patients.put(patient);
    });
  }

  Future<void> deletePatient(int id) async {
    await isar.writeTxn(() async {
      await isar.patients.delete(id);
    });
  }
}

@riverpod
Future<PatientRepository> patientRepository(PatientRepositoryRef ref) async {
  final isar = await ref.watch(isarDatabaseProvider.future);
  return PatientRepository(isar);
}
