import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import '../../providers/overdue_provider.dart';

const _trendWeeks = 4;
final _vomitColor = Colors.deepOrange;
final _hairballColor = Colors.purple;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.cat});

  final Cat cat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider(cat.id));
    final overdue = ref.watch(overdueItemsProvider(cat.id));
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading data: $e')),
        data: (events) => ListView(
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
                          '${item.eventType.label}: last logged ${_timeAgo(item.lastLoggedAt, now)}',
                        ),
                    ],
                  ),
                ),
              ),
            if (overdue.isNotEmpty) const SizedBox(height: 16),
            _LastActivitySection(events: events, now: now),
            const SizedBox(height: 24),
            _AverageIntervalSection(events: events),
            const SizedBox(height: 28),
            Text(
              'Symptom trend (vomiting & hairballs)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _SymptomTrendChart(events: events, now: now),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime then, DateTime now) {
    final hours = now.difference(then).inHours;
    if (hours < 24) return '$hours h ago';
    return '${(hours / 24).floor()} d ago';
  }
}

String _relativeTime(Duration diff) {
  final minutes = diff.inMinutes;
  if (minutes < 2) return 'just now';
  if (minutes < 60) return '${minutes} min ago';
  final hours = diff.inHours;
  if (hours < 24) return '${hours} h ago';
  final days = diff.inDays;
  if (days < 30) return '${days} d ago';
  if (days < 365) return '${(days / 7).floor()} wk ago';
  return '${(days / 30).floor()} mo ago';
}

String _intervalLabel(Duration avg) {
  final minutes = avg.inMinutes;
  if (minutes < 90) return 'every ${minutes} min';
  final hours = avg.inHours;
  if (hours < 36) return 'every ${hours} h';
  final days = avg.inDays;
  if (days < 14) return 'every ${days} d';
  if (days < 90) return 'every ${(days / 7).floor()} wk';
  return 'every ${(days / 30).floor()} mo';
}

class _LastActivitySection extends StatelessWidget {
  const _LastActivitySection({required this.events, required this.now});

  final List<Event> events;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final latest = <CatEventType, DateTime>{};
    for (final event in events) {
      final type = CatEventTypeX.fromStorageKey(event.eventType);
      final existing = latest[type];
      if (existing == null || event.loggedAt.isAfter(existing)) {
        latest[type] = event.loggedAt;
      }
    }

    final withData = latest.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final withDataTypes = withData.map((e) => e.key).toSet();
    final noDataTypes =
        CatEventType.values.where((t) => !withDataTypes.contains(t)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last activity',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final entry in withData)
          _ActivityRow(
            type: entry.key,
            label: _relativeTime(now.difference(entry.value)),
            muted: false,
          ),
        for (final type in noDataTypes)
          _ActivityRow(type: type, label: 'Never logged', muted: true),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.type,
    required this.label,
    required this.muted,
  });

  final CatEventType type;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? Theme.of(context).disabledColor : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(type.icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              type.label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
          ),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _AverageIntervalSection extends StatelessWidget {
  const _AverageIntervalSection({required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    final timestampsByType = <CatEventType, List<DateTime>>{};
    for (final event in events) {
      final type = CatEventTypeX.fromStorageKey(event.eventType);
      (timestampsByType[type] ??= []).add(event.loggedAt);
    }

    final averages = <CatEventType, Duration>{};
    for (final entry in timestampsByType.entries) {
      final sorted = entry.value..sort();
      if (sorted.length < 2) continue;
      var totalMicros = 0;
      for (var i = 1; i < sorted.length; i++) {
        totalMicros += sorted[i].difference(sorted[i - 1]).inMicroseconds;
      }
      averages[entry.key] =
          Duration(microseconds: totalMicros ~/ (sorted.length - 1));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average intervals',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Average time between each logged activity.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (averages.isEmpty)
          Text(
            'Log more events to see your average intervals per activity.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          for (final entry in averages.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value)))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(entry.key.icon, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    _intervalLabel(entry.value),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _SymptomTrendChart extends StatelessWidget {
  const _SymptomTrendChart({required this.events, required this.now});

  final List<Event> events;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(now.year, now.month, now.day);
    final bucketStarts = [
      for (var i = _trendWeeks - 1; i >= 0; i--)
        today.subtract(Duration(days: 7 * i + 6)),
    ];

    final vomitCounts = List<int>.filled(_trendWeeks, 0);
    final hairballCounts = List<int>.filled(_trendWeeks, 0);
    for (final event in events) {
      final type = CatEventTypeX.fromStorageKey(event.eventType);
      if (type != CatEventType.vomit && type != CatEventType.hairball) {
        continue;
      }
      final day = DateTime(
        event.loggedAt.year,
        event.loggedAt.month,
        event.loggedAt.day,
      );
      for (var i = 0; i < _trendWeeks; i++) {
        final bucketEnd = bucketStarts[i].add(const Duration(days: 7));
        if (!day.isBefore(bucketStarts[i]) && day.isBefore(bucketEnd)) {
          if (type == CatEventType.vomit) {
            vomitCounts[i]++;
          } else {
            hairballCounts[i]++;
          }
          break;
        }
      }
    }

    final maxCount = [...vomitCounts, ...hairballCounts, 1]
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxCount + 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                _trendLine(vomitCounts, _vomitColor),
                _trendLine(hairballCounts, _hairballColor),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value != value.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 ||
                          index >= bucketStarts.length ||
                          value != index.toDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat.Md().format(bucketStarts[index]),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(
                  drawVerticalLine: false, horizontalInterval: 1),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: _vomitColor, label: 'Vomiting'),
            const SizedBox(width: 16),
            _LegendDot(color: _hairballColor, label: 'Hairballs'),
          ],
        ),
      ],
    );
  }

  LineChartBarData _trendLine(List<int> counts, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < counts.length; i++)
          FlSpot(i.toDouble(), counts[i].toDouble()),
      ],
      isCurved: false,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: true),
    );
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
