import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import 'event_detail_screen.dart';
import 'export_report_sheet.dart';

class LogHistoryScreen extends ConsumerStatefulWidget {
  const LogHistoryScreen({
    super.key,
    required this.cat,
    this.initialEventType,
    this.initialDateRange,
    this.initialDateLabel,
  });

  final Cat cat;
  final CatEventType? initialEventType;
  final DateTimeRange? initialDateRange;
  final String? initialDateLabel;

  @override
  ConsumerState<LogHistoryScreen> createState() => _LogHistoryScreenState();
}

class _LogHistoryScreenState extends ConsumerState<LogHistoryScreen> {
  CatEventType? _typeFilter;
  DateTimeRange? _dateRange;
  String _dateLabel = 'All time';

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialEventType;
    _dateRange = widget.initialDateRange;
    if (widget.initialDateLabel != null) {
      _dateLabel = widget.initialDateLabel!;
    }
  }

  bool get _hasActiveFilter => _typeFilter != null || _dateRange != null;

  void _applyDatePreset(int days) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    setState(() {
      if (days == 0) {
        _dateRange = null;
        _dateLabel = 'All time';
      } else {
        _dateRange = DateTimeRange(
          start: todayDate.subtract(Duration(days: days - 1)),
          end: todayDate,
        );
        _dateLabel = 'Last $days days';
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _typeFilter = null;
      _dateRange = null;
      _dateLabel = 'All time';
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider(widget.cat.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export vet report',
            onPressed: () {
              final events =
                  ref.read(eventsStreamProvider(widget.cat.id)).value;
              if (events == null) return;
              showExportReportSheet(
                context,
                cat: widget.cat,
                allEvents: events,
                initialRange: _dateRange,
                initialRangeLabel: _dateRange != null ? _dateLabel : null,
                initialType: _typeFilter,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterRow(context),
          const Divider(height: 1),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                var filtered = events;
                if (_dateRange != null) {
                  filtered = filtered.where((e) {
                    final d = DateTime(
                        e.loggedAt.year, e.loggedAt.month, e.loggedAt.day);
                    return !d.isBefore(_dateRange!.start) &&
                        !d.isAfter(_dateRange!.end);
                  }).toList();
                }
                if (_typeFilter != null) {
                  filtered = filtered
                      .where((e) =>
                          CatEventTypeX.fromStorageKey(e.eventType) ==
                          _typeFilter)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('No events found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final event = filtered[index];
                    final type =
                        CatEventTypeX.fromStorageKey(event.eventType);
                    return ListTile(
                      leading: Icon(type.icon),
                      title: Text(type.label),
                      subtitle:
                          event.notes != null && event.notes!.isNotEmpty
                              ? Text(event.notes!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                              : null,
                      trailing: Text(
                        DateFormat.MMMd().add_jm().format(event.loggedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventDetailScreen(event: event),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error loading history: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          PopupMenuButton<int>(
            offset: const Offset(0, 36),
            onSelected: _applyDatePreset,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 0, child: Text('All time')),
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
              PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
            child: _FilterChip(
                label: _dateLabel, isActive: _dateRange != null),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<CatEventType?>(
            offset: const Offset(0, 36),
            onSelected: (type) => setState(() => _typeFilter = type),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All types')),
              for (final type in CatEventType.values)
                PopupMenuItem(value: type, child: Text(type.label)),
            ],
            child: _FilterChip(
              label: _typeFilter?.label ?? 'All types',
              isActive: _typeFilter != null,
            ),
          ),
          if (_hasActiveFilter) ...[
            const Spacer(),
            TextButton(
              onPressed: _clearFilters,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Clear'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isActive
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.w600 : null,
                ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
