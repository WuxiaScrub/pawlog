import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event_type.dart';
import '../../providers/events_provider.dart';

Future<void> showLogEventSheet(
  BuildContext context, {
  required String catId,
  required CatEventType eventType,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => LogEventSheet(catId: catId, eventType: eventType),
  );
}

class LogEventSheet extends ConsumerStatefulWidget {
  const LogEventSheet({super.key, required this.catId, required this.eventType});

  final String catId;
  final CatEventType eventType;

  @override
  ConsumerState<LogEventSheet> createState() => _LogEventSheetState();
}

class _LogEventSheetState extends ConsumerState<LogEventSheet> {
  final _notesController = TextEditingController();
  final _productController = TextEditingController();
  final _durationController = TextEditingController();
  bool _hairballPresent = false;
  bool _afterEating = false;
  bool _unusualColorOrOdor = false;
  bool _firstTime = false;
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    _productController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final metadata = <String, dynamic>{};
    switch (widget.eventType) {
      case CatEventType.vomit:
        metadata['hairball_present'] = _hairballPresent;
        metadata['after_eating'] = _afterEating;
        break;
      case CatEventType.litterChange:
        metadata['unusual_color_or_odor'] = _unusualColorOrOdor;
        break;
      case CatEventType.deworming:
      case CatEventType.fleaTreatment:
        metadata['product_name'] = _productController.text.trim();
        metadata['first_time'] = _firstTime;
        break;
      case CatEventType.playtime:
        final minutes = int.tryParse(_durationController.text.trim());
        if (minutes != null) metadata['duration_minutes'] = minutes;
        break;
      default:
        break;
    }

    await ref.read(eventsRepositoryProvider).logEvent(
          catId: widget.catId,
          eventType: widget.eventType,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          metadata: metadata.isEmpty ? null : metadata,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged: ${widget.eventType.label}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsProduct = widget.eventType == CatEventType.deworming ||
        widget.eventType == CatEventType.fleaTreatment;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(widget.eventType.icon),
                const SizedBox(width: 8),
                Text(
                  widget.eventType.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.eventType == CatEventType.vomit) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hairball present?'),
                value: _hairballPresent,
                onChanged: (v) => setState(() => _hairballPresent = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Shortly after eating?'),
                value: _afterEating,
                onChanged: (v) => setState(() => _afterEating = v),
              ),
            ],
            if (widget.eventType == CatEventType.litterChange)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Unusual color or odor?'),
                value: _unusualColorOrOdor,
                onChanged: (v) => setState(() => _unusualColorOrOdor = v),
              ),
            if (needsProduct) ...[
              TextField(
                controller: _productController,
                decoration: const InputDecoration(labelText: 'Product name'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('First time using this product?'),
                value: _firstTime,
                onChanged: (v) => setState(() => _firstTime = v),
              ),
            ],
            if (widget.eventType == CatEventType.playtime) ...[
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes, optional)',
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
