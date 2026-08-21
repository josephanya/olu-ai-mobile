import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olu_ai/core/router/app_router.dart';
import 'package:olu_ai/core/theme/app_theme.dart';
import 'package:olu_ai/services/benchmark_sync_worker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F1419),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: OluApp()));
}

class OluApp extends ConsumerWidget {
  const OluApp({super.key});

  static const _saharaApiKey = String.fromEnvironment('SAHARA_API_KEY');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final benchmarkSyncWorker = ref.watch(benchmarkSyncWorkerProvider);
    unawaited(benchmarkSyncWorker.startAutoSync(saharaApiKey: _saharaApiKey));

    return MaterialApp.router(
      title: 'Olu AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
