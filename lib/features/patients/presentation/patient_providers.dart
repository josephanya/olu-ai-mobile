import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:olu_ai/features/patients/data/patient_model.dart';
import 'package:olu_ai/features/patients/data/patient_repository.dart';

part 'patient_providers.g.dart';

@riverpod
Future<List<Patient>> patientList(PatientListRef ref) async {
  final repository = await ref.watch(patientRepositoryProvider.future);
  return repository.getAllPatients();
}
