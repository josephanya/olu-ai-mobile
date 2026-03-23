import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olu_ai/core/database/database.dart';
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
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final repository = await ref.read(patientRepositoryProvider.future);

        final newPatient = PatientsCompanion.insert(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          village: drift.Value(_villageController.text.trim()),
        );

        await repository.addPatient(newPatient);
        ref.invalidate(patientListProvider);

        if (mounted) {
          context.pop();
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save patient: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ─── Header ───────────────────────────────────
              Text('New Patient', style: theme.textTheme.displayMedium),
              const SizedBox(height: 6),
              Text(
                'Fill in the patient\'s details below',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),

              const SizedBox(height: 36),

              // ─── First Name ───────────────────────────────
              Text('First Name',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.textTheme.bodySmall?.color)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter first name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ─── Last Name ────────────────────────────────
              Text('Last Name',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.textTheme.bodySmall?.color)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter last name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ─── Village ──────────────────────────────────
              Text('Village',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.textTheme.bodySmall?.color)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _villageController,
                decoration: const InputDecoration(
                  hintText: 'Enter village (optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 44),

              // ─── Save Button ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePatient,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF003D36),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 20),
                            SizedBox(width: 10),
                            Text('Save Patient'),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
