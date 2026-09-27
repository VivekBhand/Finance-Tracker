import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_providers.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(hiveInitializerProvider);

    return MaterialApp(
      title: 'Micro Savings Goal Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2ECF8F)),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
      ),
      home: initState.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Scaffold(
          body: Center(child: Text('Initialization failed: $error')),
        ),
        data: (_) {
          return const AppStartupGuard();
        },
      ),
    );
  }
}

class AppStartupGuard extends ConsumerWidget {
  const AppStartupGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    if (goals.isEmpty) {
      return const OnboardingScreen();
    }
    return const MainShell();
  }
}
