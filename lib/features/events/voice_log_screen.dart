import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/claude_service.dart';
import '../../core/stt_service.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import '../../providers/voice_provider.dart';

class VoiceLogScreen extends ConsumerStatefulWidget {
  const VoiceLogScreen({super.key, required this.catId});

  final String catId;

  @override
  ConsumerState<VoiceLogScreen> createState() => _VoiceLogScreenState();
}

class _VoiceLogScreenState extends ConsumerState<VoiceLogScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.ready;
  String _partialTranscript = '';
  String _finalTranscript = '';
  String? _errorMessage;
  List<_EditableEvent> _events = [];
  bool _saving = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final stt = ref.read(sttServiceProvider);
    final available = await stt.initialize();
    if (!available) {
      setState(() {
        _phase = _Phase.error;
        _errorMessage =
            'Speech recognition is not available. Please grant microphone and speech recognition permissions in Settings.';
      });
      return;
    }

    setState(() {
      _phase = _Phase.listening;
      _partialTranscript = '';
      _finalTranscript = '';
    });
    _pulseController.repeat(reverse: true);

    await stt.startListening(
      onPartial: (partial) {
        if (mounted) setState(() => _partialTranscript = partial);
      },
      onFinal: (transcript) {
        if (!mounted) return;
        _pulseController.stop();
        _pulseController.reset();
        if (transcript.trim().isEmpty) {
          setState(() {
            _phase = _Phase.ready;
            _errorMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No speech detected. Try again.')),
          );
          return;
        }
        _finalTranscript = transcript;
        _sendToClaude(transcript);
      },
      onError: (error) {
        if (!mounted) return;
        _pulseController.stop();
        _pulseController.reset();
        setState(() {
          _phase = _Phase.error;
          _errorMessage = error;
        });
      },
    );
  }

  Future<void> _sendToClaude(String transcript) async {
    setState(() => _phase = _Phase.processing);

    final claude = ref.read(claudeServiceProvider);
    if (claude == null) {
      setState(() {
        _phase = _Phase.error;
        _errorMessage = 'API key not configured.';
      });
      return;
    }

    final result = await claude.parseTranscript(transcript);
    if (!mounted) return;

    switch (result) {
      case ClaudeParseSuccess(:final events):
        if (events.isEmpty) {
          _showNoEventsDialog(transcript);
          return;
        }
        setState(() {
          _phase = _Phase.confirm;
          _events = events.map(_EditableEvent.fromParsed).toList();
        });
      case ClaudeParseError(:final message):
        setState(() {
          _phase = _Phase.error;
          _errorMessage = message;
        });
    }
  }

  void _showNoEventsDialog(String transcript) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No events found'),
        content: const Text(
            "Couldn't identify any care events. Save as a general note?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save as Note'),
          ),
        ],
      ),
    ).then((save) {
      if (save == true) {
        setState(() {
          _phase = _Phase.confirm;
          _events = [
            _EditableEvent(
              eventType: CatEventType.note,
              notes: transcript,
              metadata: {},
            ),
          ];
        });
      } else {
        setState(() => _phase = _Phase.ready);
      }
    });
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    final repo = ref.read(eventsRepositoryProvider);

    for (final event in _events) {
      final metadata = _buildMetadata(event);
      await repo.logEvent(
        catId: widget.catId,
        eventType: event.eventType,
        notes: event.notes?.trim().isEmpty == true ? null : event.notes,
        metadata: metadata.isEmpty ? null : metadata,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${_events.length} ${_events.length == 1 ? 'event' : 'events'} logged.'),
      ),
    );
    Navigator.of(context).pop();
  }

  Map<String, dynamic> _buildMetadata(_EditableEvent event) {
    final m = <String, dynamic>{};
    switch (event.eventType) {
      case CatEventType.vomit:
        m['hairball_present'] = event.metadata['hairball_present'] ?? false;
        m['after_eating'] = event.metadata['after_eating'] ?? false;
      case CatEventType.litterChange:
        m['unusual_color_or_odor'] =
            event.metadata['unusual_color_or_odor'] ?? false;
      case CatEventType.deworming:
      case CatEventType.fleaTreatment:
        final product =
            (event.metadata['product_name'] as String?)?.trim() ?? '';
        if (product.isNotEmpty) m['product_name'] = product;
        m['first_time'] = event.metadata['first_time'] ?? false;
      case CatEventType.playtime:
        final dur = event.metadata['duration_minutes'];
        if (dur != null) m['duration_minutes'] = dur;
      case CatEventType.weight:
        final val = event.metadata['weight_value'];
        if (val != null) {
          m['weight_value'] = val;
          final inLbs = event.metadata['weight_unit'] == 'lb';
          m['weight_unit'] = inLbs ? 'lb' : 'kg';
          m['weight_kg'] = inLbs ? (val as num) * 0.453592 : val;
        }
      default:
        break;
    }
    return m;
  }

  void _removeEvent(int index) {
    setState(() {
      _events.removeAt(index);
      if (_events.isEmpty) _phase = _Phase.ready;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Log'),
      ),
      body: switch (_phase) {
        _Phase.ready => _buildReadyPhase(),
        _Phase.listening => _buildListeningPhase(),
        _Phase.processing => _buildProcessingPhase(),
        _Phase.confirm => _buildConfirmPhase(),
        _Phase.error => _buildErrorPhase(),
      },
    );
  }

  Widget _buildReadyPhase() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          const Text('Tap to start recording'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _startListening,
            icon: const Icon(Icons.mic),
            label: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningPhase() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + _pulseController.value * 0.2;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.mic,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Listening...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_partialTranscript.isNotEmpty)
              Text(
                _partialTranscript,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                await ref.read(sttServiceProvider).stop();
                _pulseController.stop();
                _pulseController.reset();
                if (mounted) setState(() => _phase = _Phase.ready);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingPhase() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Parsing your voice log...'),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _finalTranscript,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPhase() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.format_quote, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _finalTranscript,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _events.length,
            itemBuilder: (context, index) => _EventCard(
              event: _events[index],
              onRemove: () => _removeEvent(index),
              onChanged: (updated) =>
                  setState(() => _events[index] = updated),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _events.clear();
                              _phase = _Phase.ready;
                            }),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveAll,
                    child: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save All (${_events.length})',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPhase() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => setState(() => _phase = _Phase.ready),
                  child: const Text('Back'),
                ),
                if (_finalTranscript.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () => _sendToClaude(_finalTranscript),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _phase = _Phase.confirm;
                        _events = [
                          _EditableEvent(
                            eventType: CatEventType.note,
                            notes: _finalTranscript,
                            metadata: {},
                          ),
                        ];
                      });
                    },
                    child: const Text('Save as Note'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _Phase { ready, listening, processing, confirm, error }

class _EditableEvent {
  _EditableEvent({
    required this.eventType,
    this.notes,
    required this.metadata,
  });

  factory _EditableEvent.fromParsed(ParsedEvent parsed) {
    return _EditableEvent(
      eventType: parsed.eventType,
      notes: parsed.notes,
      metadata: Map<String, dynamic>.from(parsed.metadata),
    );
  }

  CatEventType eventType;
  String? notes;
  Map<String, dynamic> metadata;
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onRemove,
    required this.onChanged,
  });

  final _EditableEvent event;
  final VoidCallback onRemove;
  final void Function(_EditableEvent) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(event.eventType.icon, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.eventType.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onRemove,
                  tooltip: 'Remove this event',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: event.notes ?? '',
              decoration: const InputDecoration(
                labelText: 'Notes',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (val) {
                event.notes = val;
                onChanged(event);
              },
            ),
            ..._buildMetadataFields(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMetadataFields(BuildContext context) {
    switch (event.eventType) {
      case CatEventType.vomit:
        return [
          SwitchListTile(
            dense: true,
            title: const Text('Hairball present?'),
            value: event.metadata['hairball_present'] == true,
            onChanged: (val) {
              event.metadata['hairball_present'] = val;
              onChanged(event);
            },
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Shortly after eating?'),
            value: event.metadata['after_eating'] == true,
            onChanged: (val) {
              event.metadata['after_eating'] = val;
              onChanged(event);
            },
          ),
        ];
      case CatEventType.litterChange:
        return [
          SwitchListTile(
            dense: true,
            title: const Text('Unusual color or odor?'),
            value: event.metadata['unusual_color_or_odor'] == true,
            onChanged: (val) {
              event.metadata['unusual_color_or_odor'] = val;
              onChanged(event);
            },
          ),
        ];
      case CatEventType.deworming:
      case CatEventType.fleaTreatment:
        return [
          const SizedBox(height: 8),
          TextFormField(
            initialValue:
                (event.metadata['product_name'] as String?) ?? '',
            decoration: const InputDecoration(
              labelText: 'Product name',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              event.metadata['product_name'] = val;
              onChanged(event);
            },
          ),
          SwitchListTile(
            dense: true,
            title: const Text('First time using this?'),
            value: event.metadata['first_time'] == true,
            onChanged: (val) {
              event.metadata['first_time'] = val;
              onChanged(event);
            },
          ),
        ];
      case CatEventType.playtime:
        return [
          const SizedBox(height: 8),
          TextFormField(
            initialValue:
                event.metadata['duration_minutes']?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) {
              event.metadata['duration_minutes'] = int.tryParse(val);
              onChanged(event);
            },
          ),
        ];
      case CatEventType.weight:
        final inLbs = event.metadata['weight_unit'] == 'lb';
        return [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue:
                      event.metadata['weight_value']?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    event.metadata['weight_value'] = double.tryParse(val);
                    onChanged(event);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('kg')),
                  ButtonSegment(value: true, label: Text('lb')),
                ],
                selected: {inLbs},
                onSelectionChanged: (val) {
                  event.metadata['weight_unit'] =
                      val.first ? 'lb' : 'kg';
                  onChanged(event);
                },
              ),
            ],
          ),
        ];
      default:
        return [];
    }
  }
}
