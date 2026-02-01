import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olu_ai/core/database/database.dart';
import 'package:olu_ai/features/patients/data/patient_repository.dart';

final patientListProvider = FutureProvider<List<Patient>>((ref) async {
  final repository = await ref.watch(patientRepositoryProvider.future);
  return repository.getAllPatients();
});
