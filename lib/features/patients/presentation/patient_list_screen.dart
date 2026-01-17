import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olu_ai/features/patients/presentation/patient_providers.dart';

class PatientListScreen extends ConsumerWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return const Center(child: Text('No patients found.'));
          }
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return ListTile(
                title: Text('${patient.firstName} ${patient.lastName}'),
                subtitle: Text(patient.village ?? 'No village'),
                onTap: () {
                  context.push('/patients/${patient.id}/visit');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add patient
          context.push('/patients/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
