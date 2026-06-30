import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import '../../providers/overdue_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.cat});

  final Cat cat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsStreamProvider(cat.id)).value ?? [];
    final overdue = ref.watch(overdueItemsProvider(cat.id));

    final now = DateTime.now();
    final thisWeekStart = now.subtract(const Duration(days: 7));
    final lastWeekStart = now.subtract(const Duration(days: 14));

    final thisWeekCounts = <CatEventType, int>{};
    final lastWeekCounts = <CatEventType, int>{};
    for (final type in CatEventType.values) {
      thisWeekCounts[type] = 0;
      lastWeekCounts[type] = 0;
    }
    for (final event in events) {
      final type = CatEventTypeX.fromStorageKey(event.eventType);
      if (event.loggedAt.isAfter(thisWeekStart)) {
        thisWeekCounts[type] = thisWeekCounts[type]! + 1;
      } else if (event.loggedAt.isAfter(lastWeekStart)) {
        lastWeekCounts[type] = lastWeekCounts[type]! + 1;
      }
    }

    final maxCount = [
      ...thisWeekCounts.values,
      ...lastWeekCounts.values,
      1,
    ].reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (overdue.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overdue',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    for (final item in overdue)
                      Text(
                        '${item.eventType.label}: last logged ${_hoursAgo(item.lastLoggedAt, now)}',
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('This week vs last week',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                maxY: (maxCount + 1).toDouble(),
                barGroups: [
                  for (var i = 0; i < CatEventType.values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: lastWeekCounts[CatEventType.values[i]]!
                              .toDouble(),
                          color: Colors.grey,
                          width: 8,
                        ),
                        BarChartRodData(
                          toY: thisWeekCounts[CatEventType.values[i]]!
                              .toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 8,
                        ),
                      ],
                    ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= CatEventType.values.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              CatEventType.values[index].label,
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Colors.grey, label: 'Last week'),
              const SizedBox(width: 16),
              _LegendDot(
                color: Theme.of(context).colorScheme.primary,
                label: 'This week',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _hoursAgo(DateTime then, DateTime now) {
    final hours = now.difference(then).inHours;
    if (hours < 24) return '$hours h ago';
    return '${(hours / 24).floor()} d ago';
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
