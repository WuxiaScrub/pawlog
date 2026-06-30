import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/overdue_provider.dart';

const _trendWeeks = 4;
final _vomitColor = Colors.deepOrange;
final _hairballColor = Colors.purple;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.cat});

  final Cat cat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsStreamProvider(cat.id)).value ?? [];
    final overdue = ref.watch(overdueItemsProvider(cat.id));
    final settings = ref.watch(effectiveSettingsProvider);
    final now = DateTime.now();

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
          _LatenessRanking(events: events, settings: settings, now: now),
          const SizedBox(height: 28),
          Text('Symptom trend (vomiting & hairballs)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _SymptomTrendChart(events: events, now: now),
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

class _LatenessStat {
  const _LatenessStat({
    required this.eventType,
    required this.lateCount,
    required this.totalIntervals,
  });

  final CatEventType eventType;
  final int lateCount;
  final int totalIntervals;

  double get lateRate => totalIntervals == 0 ? 0 : lateCount / totalIntervals;
}

/// Ranks schedulable event types by how often they were logged later than
/// their reminder threshold — i.e. what the owner most tends to fall behind
/// on (litter, water, etc.), rather than raw activity volume.
class _LatenessRanking extends StatelessWidget {
  const _LatenessRanking({
    required this.events,
    required this.settings,
    required this.now,
  });

  final List<Event> events;
  final Map<CatEventType, EffectiveSetting> settings;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final timestampsByType = <CatEventType, List<DateTime>>{};
    for (final event in events) {
      final type = CatEventTypeX.fromStorageKey(event.eventType);
      (timestampsByType[type] ??= []).add(event.loggedAt);
    }

    final stats = <_LatenessStat>[];
    for (final type in CatEventType.values) {
      if (!type.isSchedulable) continue;
      final setting = settings[type];
      if (setting == null || !setting.enabled || setting.thresholdHours <= 0) {
        continue;
      }
      final timestamps = timestampsByType[type];
      if (timestamps == null || timestamps.isEmpty) continue;
      timestamps.sort();

      var lateCount = 0;
      var total = 0;
      for (var i = 1; i < timestamps.length; i++) {
        total++;
        final gapHours =
            timestamps[i].difference(timestamps[i - 1]).inHours;
        if (gapHours > setting.thresholdHours) lateCount++;
      }
      // The open interval since the most recent log counts too — that's
      // what "currently overdue" looks like in this history.
      total++;
      if (now.difference(timestamps.last).inHours > setting.thresholdHours) {
        lateCount++;
      }

      stats.add(_LatenessStat(
        eventType: type,
        lateCount: lateCount,
        totalIntervals: total,
      ));
    }

    stats.sort((a, b) => b.lateRate.compareTo(a.lateRate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where you fall behind',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'How often each chore was logged later than its reminder threshold.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (stats.isEmpty)
          Text(
            'Not enough history yet — keep logging to see what you tend to miss.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          for (final stat in stats) _LatenessRow(stat: stat),
      ],
    );
  }
}

class _LatenessRow extends StatelessWidget {
  const _LatenessRow({required this.stat});

  final _LatenessStat stat;

  @override
  Widget build(BuildContext context) {
    final rate = stat.lateRate.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stat.eventType.icon, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  stat.eventType.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${(rate * 100).round()}% late',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              color: rate >= 0.5
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Late ${stat.lateCount} of ${stat.totalIntervals} time${stat.totalIntervals == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
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
    // Buckets are 7-day windows ending today, oldest first.
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
                      // Integer-only labels: 0.5/1.5 ticks would be
                      // meaningless for an event count.
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
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(drawVerticalLine: false, horizontalInterval: 1),
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
