import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/events/home_screen.dart';
import '../features/events/log_history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../providers/overdue_provider.dart';
import 'database.dart';
import 'notifications_service.dart';

final _notificationsService = NotificationsService();

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.cat});

  final Cat cat;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Mirrors the spec's "on app open, check last timestamp per event type"
    // behavior: fire native reminders once when the home screen loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overdue = ref.read(overdueItemsProvider(widget.cat.id));
      _notificationsService.notifyOverdue(overdue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(cat: widget.cat),
      LogHistoryScreen(cat: widget.cat),
      DashboardScreen(cat: widget.cat),
      SettingsScreen(cat: widget.cat),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
