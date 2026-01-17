import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olu_ai/features/patients/data/patient_model.dart';
import 'package:olu_ai/features/patients/data/patient_repository.dart';
import 'package:olu_ai/features/patients/presentation/patient_providers.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key});

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _villageController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (_formKey.currentState!.validate()) {
      final repository = await ref.read(patientRepositoryProvider.future);
      
      final newPatient = Patient()
        ..firstName = _firstNameController.text
        ..lastName = _lastNameController.text
        ..village = _villageController.text
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await repository.addPatient(newPatient);
      
      // Invalidate the list provider to refresh the list
      ref.invalidate(patientListProvider);

      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Patient'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _villageController,
                decoration: const InputDecoration(labelText: 'Village'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _savePatient,
                child: const Text('Save Patient'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
