import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import '../../providers/overdue_provider.dart';

const _heatmapDays = 30;
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
          _ActivityHeatmap(events: events, now: now),
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

class _ActivityHeatmap extends StatefulWidget {
  const _ActivityHeatmap({required this.events, required this.now});

  final List<Event> events;
  final DateTime now;

  @override
  State<_ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<_ActivityHeatmap> {
  CatEventType? _filter;

  @override
  Widget build(BuildContext context) {
    final today =
        DateTime(widget.now.year, widget.now.month, widget.now.day);
    final dayCounts = <DateTime, int>{
      for (var i = 0; i < _heatmapDays; i++)
        today.subtract(Duration(days: _heatmapDays - 1 - i)): 0,
    };
    for (final event in widget.events) {
      if (_filter != null &&
          CatEventTypeX.fromStorageKey(event.eventType) != _filter) {
        continue;
      }
      final day = DateTime(
        event.loggedAt.year,
        event.loggedAt.month,
        event.loggedAt.day,
      );
      if (dayCounts.containsKey(day)) {
        dayCounts[day] = dayCounts[day]! + 1;
      }
    }

    final maxCount =
        dayCounts.values.fold(0, (a, b) => b > a ? b : a).clamp(1, 1 << 30);
    final primary = Theme.of(context).colorScheme.primary;
    final days = dayCounts.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Activity (last $_heatmapDays days)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            PopupMenuButton<CatEventType?>(
              tooltip: 'Filter by event type',
              icon: Icon(
                _filter == null ? Icons.filter_list : Icons.filter_alt,
              ),
              onSelected: (value) => setState(() => _filter = value),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('All events')),
                for (final type in CatEventType.values)
                  PopupMenuItem(value: type, child: Text(type.label)),
              ],
            ),
          ],
        ),
        if (_filter != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Showing: ${_filter!.label}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final entry = days[index];
            final intensity = entry.value == 0 ? 0.0 : entry.value / maxCount;
            return Tooltip(
              message:
                  '${DateFormat.MMMd().format(entry.key)}: ${entry.value} event${entry.value == 1 ? '' : 's'}',
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: entry.value == 0
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : primary.withValues(alpha: 0.15 + 0.85 * intensity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Darker squares = more care events logged that day.',
          style: Theme.of(context).textTheme.bodySmall,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: (maxCount + 1).toDouble(),
              lineBarsData: [
                _trendLine(vomitCounts, _vomitColor),
                _trendLine(hairballCounts, _hairballColor),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= bucketStarts.length) {
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
              gridData: const FlGridData(drawVerticalLine: false),
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
