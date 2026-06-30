import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/database.dart';
import '../../core/local_photo.dart';
import '../../core/photo_storage.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';

/// Shows the log-event sheet. Pass [existingEvent] to edit an already-logged
/// event in place instead of creating a new one.
Future<void> showLogEventSheet(
  BuildContext context, {
  required String catId,
  required CatEventType eventType,
  Event? existingEvent,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => LogEventSheet(
      catId: catId,
      eventType: eventType,
      existingEvent: existingEvent,
    ),
  );
}

class _PhotoChoice {
  _PhotoChoice(this.source);
  final ImageSource? source;
}

class LogEventSheet extends ConsumerStatefulWidget {
  const LogEventSheet({
    super.key,
    required this.catId,
    required this.eventType,
    this.existingEvent,
  });

  final String catId;
  final CatEventType eventType;
  final Event? existingEvent;

  @override
  ConsumerState<LogEventSheet> createState() => _LogEventSheetState();
}

class _LogEventSheetState extends ConsumerState<LogEventSheet> {
  final _notesController = TextEditingController();
  final _productController = TextEditingController();
  final _durationController = TextEditingController();
  final _weightController = TextEditingController();
  bool _hairballPresent = false;
  bool _afterEating = false;
  bool _unusualColorOrOdor = false;
  bool _firstTime = false;
  bool _weightInLbs = true;
  bool _saving = false;
  String? _photoPath;
  final _photoStorage = const PhotoStorage();

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    if (existing == null) return;

    _notesController.text = existing.notes ?? '';
    final metadata = existing.metadataJson != null
        ? jsonDecode(existing.metadataJson!) as Map<String, dynamic>
        : <String, dynamic>{};
    _hairballPresent = metadata['hairball_present'] as bool? ?? false;
    _afterEating = metadata['after_eating'] as bool? ?? false;
    _unusualColorOrOdor = metadata['unusual_color_or_odor'] as bool? ?? false;
    _firstTime = metadata['first_time'] as bool? ?? false;
    _productController.text = metadata['product_name'] as String? ?? '';
    final duration = metadata['duration_minutes'];
    if (duration != null) _durationController.text = duration.toString();
    _photoPath = metadata['photo_path'] as String?;
    final weightValue = metadata['weight_value'];
    if (weightValue != null) {
      _weightInLbs = (metadata['weight_unit'] as String?) != 'kg';
      _weightController.text = (weightValue as num).toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _productController.dispose();
    _durationController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext)
                  .pop(_PhotoChoice(ImageSource.camera)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext)
                  .pop(_PhotoChoice(ImageSource.gallery)),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoChoice(null)),
              ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice.source == null) {
      setState(() => _photoPath = null);
      return;
    }

    try {
      final saved = await _photoStorage.pickAndSave(source: choice.source!);
      if (saved != null) setState(() => _photoPath = saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save photo: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final metadata = <String, dynamic>{};
    switch (widget.eventType) {
      case CatEventType.vomit:
        metadata['hairball_present'] = _hairballPresent;
        metadata['after_eating'] = _afterEating;
        if (_photoPath != null) metadata['photo_path'] = _photoPath;
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
      case CatEventType.weight:
        final raw = double.tryParse(_weightController.text.trim());
        if (raw != null) {
          metadata['weight_value'] = raw;
          metadata['weight_unit'] = _weightInLbs ? 'lb' : 'kg';
          // Always store a kg copy for programmatic use.
          metadata['weight_kg'] =
              _weightInLbs ? raw * 0.453592 : raw;
        }
        break;
      default:
        break;
    }

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    final repo = ref.read(eventsRepositoryProvider);
    final existing = widget.existingEvent;
    if (existing != null) {
      await repo.updateEvent(
        id: existing.id,
        notes: notes,
        metadata: metadata.isEmpty ? null : metadata,
      );
    } else {
      await repo.logEvent(
        catId: widget.catId,
        eventType: widget.eventType,
        notes: notes,
        metadata: metadata.isEmpty ? null : metadata,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing != null
                ? 'Updated: ${widget.eventType.label}'
                : 'Logged: ${widget.eventType.label}',
          ),
        ),
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
                  widget.existingEvent != null
                      ? 'Edit ${widget.eventType.label}'
                      : widget.eventType.label,
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
              const SizedBox(height: 8),
              _PhotoPicker(photoPath: _photoPath, onTap: _pickPhoto),
              const SizedBox(height: 8),
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
            if (widget.eventType == CatEventType.weight) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText:
                            'Weight (${_weightInLbs ? 'lbs' : 'kg'})',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('lbs')),
                      ButtonSegment(value: false, label: Text('kg')),
                    ],
                    selected: {_weightInLbs},
                    onSelectionChanged: (sel) {
                      final newInLbs = sel.first;
                      if (newInLbs == _weightInLbs) return;
                      final raw = double.tryParse(
                          _weightController.text.trim());
                      setState(() {
                        _weightInLbs = newInLbs;
                        if (raw != null) {
                          final converted = newInLbs
                              ? raw / 0.453592
                              : raw * 0.453592;
                          _weightController.text =
                              converted.toStringAsFixed(1);
                        }
                      });
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
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

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photoPath, required this.onTap});

  final String? photoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = resolveLocalPhoto(photoPath);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          image: image != null
              ? DecorationImage(image: image, fit: BoxFit.cover)
              : null,
        ),
        child: image == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 4),
                    Text(
                      'Add a photo (optional)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
      ),
    );
  }
}
