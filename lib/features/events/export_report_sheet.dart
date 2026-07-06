import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import 'vet_report_service.dart';

/// The event scope options offered when exporting a vet report.
enum _ScopeOption { health, all, singleType }

/// Opens the "Export vet report" options sheet. [allEvents] is the cat's full,
/// unfiltered event list; the sheet applies its own date/type selection on top.
/// [initialRange]/[initialRangeLabel]/[initialType] pre-seed the options from
/// whatever filters are currently active on the history screen.
Future<void> showExportReportSheet(
  BuildContext context, {
  required Cat cat,
  required List<Event> allEvents,
  DateTimeRange? initialRange,
  String? initialRangeLabel,
  CatEventType? initialType,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ExportReportSheet(
      cat: cat,
      allEvents: allEvents,
      initialRange: initialRange,
      initialRangeLabel: initialRangeLabel,
      initialType: initialType,
    ),
  );
}

class _ExportReportSheet extends StatefulWidget {
  const _ExportReportSheet({
    required this.cat,
    required this.allEvents,
    this.initialRange,
    this.initialRangeLabel,
    this.initialType,
  });

  final Cat cat;
  final List<Event> allEvents;
  final DateTimeRange? initialRange;
  final String? initialRangeLabel;
  final CatEventType? initialType;

  @override
  State<_ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends State<_ExportReportSheet> {
  DateTimeRange? _range;
  String _rangeLabel = 'All time';
  late _ScopeOption _scope;
  bool _includeNotes = true;
  bool _includeDetails = true;
  bool _includePhotos = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
    _rangeLabel = widget.initialRangeLabel ?? 'All time';
    // If the user already narrowed history to one type, honor that; otherwise
    // default a vet report to the health-relevant subset.
    _scope = widget.initialType != null
        ? _ScopeOption.singleType
        : _ScopeOption.health;
  }

  void _applyPreset(int days) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    setState(() {
      if (days == 0) {
        _range = null;
        _rangeLabel = 'All time';
      } else {
        _range = DateTimeRange(
          start: todayDate.subtract(Duration(days: days - 1)),
          end: todayDate,
        );
        _rangeLabel = 'Last $days days';
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() {
        final start =
            DateTime(picked.start.year, picked.start.month, picked.start.day);
        final end = DateTime(picked.end.year, picked.end.month, picked.end.day);
        _range = DateTimeRange(start: start, end: end);
        _rangeLabel =
            '${DateFormat.yMMMd().format(start)} – ${DateFormat.yMMMd().format(end)}';
      });
    }
  }

  List<Event> _selectedEvents() {
    var filtered = widget.allEvents;
    if (_range != null) {
      filtered = filtered.where((e) {
        final d = DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day);
        return !d.isBefore(_range!.start) && !d.isAfter(_range!.end);
      }).toList();
    }
    switch (_scope) {
      case _ScopeOption.health:
        filtered = filtered
            .where((e) =>
                CatEventTypeX.fromStorageKey(e.eventType).isHealthRelevant)
            .toList();
        break;
      case _ScopeOption.singleType:
        filtered = filtered
            .where((e) =>
                CatEventTypeX.fromStorageKey(e.eventType) == widget.initialType)
            .toList();
        break;
      case _ScopeOption.all:
        break;
    }
    return filtered;
  }

  Future<void> _generate() async {
    final events = _selectedEvents();
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No events match these options — nothing to export.'),
        ),
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final bytes = await const VetReportService().build(
        cat: widget.cat,
        events: events,
        rangeLabel: _rangeLabel,
        includeNotes: _includeNotes,
        includeDetails: _includeDetails,
        includePhotos: _includePhotos,
      );
      final safeName =
          widget.cat.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'PawLog_${safeName}_$stamp.pdf',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _selectedEvents().length;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Export vet report',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Create a PDF of ${widget.cat.name}’s care history to print or '
            'share with your vet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _sectionLabel(context, 'Date range'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _choice('All time', _range == null, () => _applyPreset(0)),
              _choice('Last 30 days', _rangeLabel == 'Last 30 days',
                  () => _applyPreset(30)),
              _choice('Last 90 days', _rangeLabel == 'Last 90 days',
                  () => _applyPreset(90)),
              _choice(
                _range != null &&
                        _rangeLabel != 'Last 30 days' &&
                        _rangeLabel != 'Last 90 days'
                    ? _rangeLabel
                    : 'Custom…',
                _range != null &&
                    _rangeLabel != 'Last 30 days' &&
                    _rangeLabel != 'Last 90 days',
                _pickCustomRange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel(context, 'Events to include'),
          if (widget.initialType != null)
            RadioListTile<_ScopeOption>(
              value: _ScopeOption.singleType,
              groupValue: _scope,
              onChanged: (v) => setState(() => _scope = v!),
              contentPadding: EdgeInsets.zero,
              title: Text('Only ${widget.initialType!.label}'),
              subtitle: const Text('Matches your current history filter'),
            ),
          RadioListTile<_ScopeOption>(
            value: _ScopeOption.health,
            groupValue: _scope,
            onChanged: (v) => setState(() => _scope = v!),
            contentPadding: EdgeInsets.zero,
            title: const Text('Health events only'),
            subtitle: const Text(
                'Vomiting, hairballs, weight, medication, treatments & notes'),
          ),
          RadioListTile<_ScopeOption>(
            value: _ScopeOption.all,
            groupValue: _scope,
            onChanged: (v) => setState(() => _scope = v!),
            contentPadding: EdgeInsets.zero,
            title: const Text('All events'),
            subtitle: const Text('Includes litter, water, feeding & playtime'),
          ),
          const SizedBox(height: 4),
          _sectionLabel(context, 'What to show per event'),
          SwitchListTile(
            value: _includeNotes,
            onChanged: (v) => setState(() => _includeNotes = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('Include notes'),
            subtitle: const Text('Free-text notes on each event'),
          ),
          SwitchListTile(
            value: _includeDetails,
            onChanged: (v) => setState(() => _includeDetails = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('Include additional details'),
            subtitle: const Text(
                'Captured metadata (hairball present, product name, etc.)'),
          ),
          SwitchListTile(
            value: _includePhotos,
            onChanged: (v) => setState(() => _includePhotos = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('Include photos'),
            subtitle: const Text('Embed photos attached to events'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _generating || count == 0 ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_generating
                  ? 'Generating…'
                  : 'Generate PDF ($count ${count == 1 ? 'event' : 'events'})'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
