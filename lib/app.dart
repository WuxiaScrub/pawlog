import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/main_shell.dart';
import 'core/sync_service.dart';
import 'features/auth/welcome_screen.dart';
import 'features/cats/cat_care_screening_screen.dart';
import 'features/cats/cat_profile_setup_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cats_provider.dart';
import 'providers/database_provider.dart';
import 'providers/sync_provider.dart';

class PawLogApp extends ConsumerWidget {
  const PawLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize the database so the WASM binary downloads before
    // the user finishes logging in, preventing a stuck loading spinner.
    ref.watch(databaseProvider);
    // Keep the auto-sync provider alive without rebuilding the entire app
    // on every auth state change.
    ref.listen(autoSyncProvider, (_, __) {});
    return MaterialApp(
      title: 'PawLog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const _Root(),
    );
  }
}

final _authGatePassedProvider =
    NotifierProvider<_AuthGatePassedNotifier, bool>(
        _AuthGatePassedNotifier.new);

class _AuthGatePassedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void pass() => state = true;
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final gatePassed = ref.watch(_authGatePassedProvider);

    if (user != null) {
      return const _AppContent();
    }

    if (gatePassed) {
      return const _AppContent();
    }

    return const _AuthGate();
  }
}

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkSkipStatus();
  }

  Future<void> _checkSkipStatus() async {
    final skipped = await hasSkippedAuth();
    if (skipped && mounted) {
      ref.read(_authGatePassedProvider.notifier).pass();
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WelcomeScreen(
      onContinue: () {
        ref.read(_authGatePassedProvider.notifier).pass();
      },
    );
  }
}

class _AppContent extends ConsumerWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(syncStatusProvider, (prev, next) {
      final result = next.value;
      if (result != null && result.itemCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced ${result.itemCount} '
              '${result.itemCount == 1 ? 'item' : 'items'} to cloud',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    final catsAsync = ref.watch(catsStreamProvider);

    return catsAsync.when(
      data: (cats) {
        if (cats.isEmpty) return const CatProfileSetupScreen();
        final cat = cats.first;
        if (!cat.screeningDone) {
          return CatCareScreeningScreen(catId: cat.id, catName: cat.name);
        }
        return MainShell(cat: cat);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
