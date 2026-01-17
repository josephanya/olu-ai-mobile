import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:olu_ai/features/patients/presentation/patient_list_screen.dart';
import 'package:olu_ai/features/patients/presentation/patient_form_screen.dart';
import 'package:olu_ai/features/visits/presentation/active_visit_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PatientListScreen(),
        routes: [
          GoRoute(
            path: 'patients/new',
            builder: (context, state) => const PatientFormScreen(),
          ),
          GoRoute(
            path: 'patients/:id/visit',
            builder: (context, state) {
              final patientId = int.parse(state.pathParameters['id']!);
              return ActiveVisitScreen(patientId: patientId);
            },
          ),
        ],
      ),
    ],
  );
}
