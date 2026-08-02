import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/claude_service.dart';
import '../../core/stt_service.dart';
import '../../core/tts_service.dart';
import '../../core/transcript_matcher.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import '../../providers/voice_provider.dart';

/// Whether a parsed batch can be saved without stopping at the confirmation
/// screen. Anything the parser resolved confidently is auto-saved so the whole
/// voice flow stays hands-free — tap, speak, hear it logged. The one exception
/// is a general note, where the transcript *is* the content: an empty one is
/// not worth saving silently.
bool _canAutoSave(List<_EditableEvent> events) {
  if (events.isEmpty) return false;
  return events.every((e) =>
      e.eventType != CatEventType.note ||
      (e.notes != null && e.notes!.trim().isNotEmpty));
}

// ---------------------------------------------------------------------------
// Voice follow-up question definitions
// ---------------------------------------------------------------------------

class _FollowUpQuestion {
  const _FollowUpQuestion({
    required this.metadataKey,
    required this.spokenQuestion,
    this.isYesNo = true,
  });

  final String metadataKey;
  final String spokenQuestion;
  final bool isYesNo;
}

const _followUpsByType = <CatEventType, List<_FollowUpQuestion>>{
  CatEventType.vomit: [
    _FollowUpQuestion(
      metadataKey: 'hairball_present',
      spokenQuestion: 'Did you notice any hairballs?',
    ),
    _FollowUpQuestion(
      metadataKey: 'after_eating',
      spokenQuestion: 'Was this shortly after eating?',
    ),
  ],
  CatEventType.litterScoop: [
    _FollowUpQuestion(
      metadataKey: 'blood_noticed',
      spokenQuestion: 'Did you notice any blood?',
    ),
    _FollowUpQuestion(
      metadataKey: 'diarrhea',
      spokenQuestion: 'Was there any diarrhea?',
    ),
    _FollowUpQuestion(
      metadataKey: 'unusual_odor',
      spokenQuestion: 'Was there an unusual odor?',
    ),
  ],
  CatEventType.litterChange: [
    _FollowUpQuestion(
      metadataKey: 'unusual_color_or_odor',
      spokenQuestion: 'Did you notice any unusual color or odor?',
    ),
  ],
  CatEventType.deworming: [
    _FollowUpQuestion(
      metadataKey: 'product_name',
      spokenQuestion: 'Which product did you use?',
      isYesNo: false,
    ),
    _FollowUpQuestion(
      metadataKey: 'first_time',
      spokenQuestion: 'Is this the first time using this product?',
    ),
  ],
  CatEventType.fleaTreatment: [
    _FollowUpQuestion(
      metadataKey: 'product_name',
      spokenQuestion: 'Which product did you use?',
      isYesNo: false,
    ),
    _FollowUpQuestion(
      metadataKey: 'first_time',
      spokenQuestion: 'Is this the first time using this product?',
    ),
  ],
};

List<_FollowUpQuestion> _pendingFollowUps(_EditableEvent event) {
  final all = _followUpsByType[event.eventType];
  if (all == null) return [];
  return all
      .where((q) => !event.metadata.containsKey(q.metadataKey))
      .take(3)
      .toList();
}

final _yesPattern = RegExp(
  r'\b(yes|yeah|yep|yup|uh huh|correct|right|definitely|absolutely|sure|did|was|it was)\b',
  caseSensitive: false,
);
final _noPattern = RegExp(
  r"\b(no|nope|nah|not|negative|didn'?t|don'?t|wasn'?t|none)\b",
  caseSensitive: false,
);
final _stopPattern = RegExp(
  r"\b(that'?s\s*(it|all|everything)|done|nothing\s*(else)?|no\s+more|skip|stop|finish|all\s+done)\b",
  caseSensitive: false,
);

class VoiceLogScreen extends ConsumerStatefulWidget {
  const VoiceLogScreen({super.key, required this.catId});

  final String catId;

  @override
  ConsumerState<VoiceLogScreen> createState() => _VoiceLogScreenState();
}

class _VoiceLogScreenState extends ConsumerState<VoiceLogScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.listening;
  String _partialTranscript = '';
  String _finalTranscript = '';
  String? _errorMessage;
  List<_EditableEvent> _events = [];
  bool _saving = false;

  /// How many times we have asked the user to repeat themselves this session.
  int _retryCount = 0;
  static const _maxRetries = 1;

  // Follow-up state
  String? _savedEventId;
  List<_FollowUpQuestion> _followUpQuestions = [];
  int _followUpIndex = 0;
  bool _followUpListening = false;
  String _followUpPartial = '';

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
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

  static const _matcher = TranscriptMatcher();

  Future<void> _sendToClaude(String transcript) async {
    setState(() => _phase = _Phase.processing);

    final localMatch = _matcher.tryMatch(transcript);
    if (localMatch != null) {
      final events = [
        _EditableEvent(
          eventType: localMatch.eventType,
          notes: localMatch.notes,
          metadata: Map<String, dynamic>.from(localMatch.metadata),
          loggedAt: localMatch.loggedAt,
        ),
      ];

      if (_canAutoSave(events)) {
        await _autoSave(events);
        return;
      }

      setState(() {
        _phase = _Phase.confirm;
        _events = events;
      });
      return;
    }

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
          await _handleUnrecognized(transcript);
          return;
        }
        final editable = events.map(_EditableEvent.fromParsed).toList();
        if (_canAutoSave(editable)) {
          await _autoSave(editable);
          return;
        }
        setState(() {
          _phase = _Phase.confirm;
          _events = editable;
        });
      case ClaudeParseError(:final message):
        setState(() {
          _phase = _Phase.error;
          _errorMessage = message;
        });
    }
  }

  Future<void> _autoSave(List<_EditableEvent> events) async {
    if (events.length == 1) {
      final questions = _pendingFollowUps(events.first);
      if (questions.isNotEmpty) {
        await _enterFollowUp(events, questions);
        return;
      }
    }
    await _persist(events);
    if (!mounted) return;
    _confirmAndClose(events);
  }

  Future<void> _enterFollowUp(
    List<_EditableEvent> events,
    List<_FollowUpQuestion> questions,
  ) async {
    final ids = await _persist(events);
    if (!mounted) return;

    final tts = ref.read(ttsServiceProvider);
    final label = events.first.eventType.label.toLowerCase();
    await tts.speakAfterMic('Got it, logged $label.');
    if (!mounted) return;

    setState(() {
      _phase = _Phase.followUp;
      _events = events;
      _savedEventId = ids.isNotEmpty ? ids.first : null;
      _followUpQuestions = questions;
      _followUpIndex = 0;
      _followUpListening = false;
      _followUpPartial = '';
    });

    await _askFollowUpQuestion();
  }

  Future<void> _askFollowUpQuestion() async {
    if (!mounted) return;
    if (_followUpIndex >= _followUpQuestions.length) {
      _finishFollowUp();
      return;
    }

    final question = _followUpQuestions[_followUpIndex];
    final tts = ref.read(ttsServiceProvider);

    setState(() => _followUpListening = false);

    await tts.speak(question.spokenQuestion);
    if (!mounted) return;

    setState(() {
      _followUpListening = true;
      _followUpPartial = '';
    });

    final stt = ref.read(sttServiceProvider);
    await stt.startListening(
      onPartial: (partial) {
        if (mounted) setState(() => _followUpPartial = partial);
      },
      onFinal: (transcript) {
        if (!mounted) return;
        _processFollowUpResponse(transcript);
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _followUpIndex = _followUpIndex + 1);
        _askFollowUpQuestion();
      },
    );
  }

  void _processFollowUpResponse(String transcript) {
    if (transcript.trim().isEmpty) {
      setState(() => _followUpIndex = _followUpIndex + 1);
      _askFollowUpQuestion();
      return;
    }

    final question = _followUpQuestions[_followUpIndex];
    final lower = transcript.toLowerCase();
    final wantsStop = _stopPattern.hasMatch(lower);

    if (question.isYesNo) {
      final isYes = _yesPattern.hasMatch(lower);
      final isNo = _noPattern.hasMatch(lower);
      if (isYes && !isNo) {
        _events.first.metadata[question.metadataKey] = true;
      } else if (isNo) {
        _events.first.metadata[question.metadataKey] = false;
      }
    } else {
      final cleaned = transcript
          .replaceAll(RegExp(r'\b(um+|uh+|er+|like|you know)\b',
              caseSensitive: false), '')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();
      if (cleaned.isNotEmpty) {
        _events.first.metadata[question.metadataKey] = cleaned;
      }
    }

    if (wantsStop) {
      _finishFollowUp();
      return;
    }

    setState(() => _followUpIndex = _followUpIndex + 1);
    _askFollowUpQuestion();
  }

  Future<void> _finishFollowUp() async {
    if (_savedEventId != null) {
      final repo = ref.read(eventsRepositoryProvider);
      final metadata = _buildMetadata(_events.first);
      await repo.updateEvent(
        id: _savedEventId!,
        notes: _events.first.notes,
        metadata: metadata.isEmpty ? null : metadata,
      );
    }
    if (!mounted) return;

    final tts = ref.read(ttsServiceProvider);
    unawaited(tts.speak('All logged.'));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged ${_events.first.eventType.label}.'),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<List<String>> _persist(List<_EditableEvent> events) async {
    final repo = ref.read(eventsRepositoryProvider);
    final ids = <String>[];
    for (final event in events) {
      final metadata = _buildMetadata(event);
      final id = await repo.logEvent(
        catId: widget.catId,
        eventType: event.eventType,
        notes: event.notes?.trim().isEmpty == true ? null : event.notes,
        metadata: metadata.isEmpty ? null : metadata,
        loggedAt: event.loggedAt,
      );
      ids.add(id);
    }
    return ids;
  }

  /// Speaks the confirmation, shows the snackbar, and closes the screen.
  ///
  /// Every save path in the voice flow routes through here, so audio feedback
  /// is a property of saving rather than of one shortcut through the flow.
  /// Tap-logging deliberately stays silent: the user is already looking at the
  /// screen and the snackbar is confirmation enough.
  void _confirmAndClose(List<_EditableEvent> events) {
    final tts = ref.read(ttsServiceProvider);
    // Deliberately not awaited: the screen should close straight away.
    // speakAfterMic waits out the iOS audio-route switch by itself, and the
    // service is a plain provider, so it outlives this widget.
    unawaited(tts.speakAfterMic(_spokenSummary(events)));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          events.length == 1
              ? 'Logged ${events.first.eventType.label}.'
              : '${events.length} events logged.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  String _spokenSummary(List<_EditableEvent> events) {
    final labels =
        events.map((e) => e.eventType.label.toLowerCase()).toList();
    if (labels.length == 1) return 'Logged ${labels.first}.';
    final last = labels.removeLast();
    return 'Logged ${labels.join(', ')} and $last.';
  }

  /// Nothing recognisable came back. Ask once, out loud, for a repeat before
  /// falling back to the save-as-note prompt.
  Future<void> _handleUnrecognized(String transcript) async {
    if (_retryCount >= _maxRetries) {
      _showNoEventsDialog(transcript);
      return;
    }
    _retryCount++;

    final tts = ref.read(ttsServiceProvider);
    // Awaited, unlike the confirmation: the mic must not reopen while the
    // prompt is still playing or the recogniser transcribes our own voice.
    await tts.speakAfterMic("Sorry, I didn't catch that. Please say it again.");
    if (!mounted) return;
    await _startListening();
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
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    await _persist(_events);
    if (!mounted) return;
    _confirmAndClose(_events);
  }

  Map<String, dynamic> _buildMetadata(_EditableEvent event) {
    final m = <String, dynamic>{};
    switch (event.eventType) {
      case CatEventType.vomit:
        m['hairball_present'] = event.metadata['hairball_present'] ?? false;
        m['after_eating'] = event.metadata['after_eating'] ?? false;
      case CatEventType.litterScoop:
        if (event.metadata['blood_noticed'] == true) {
          m['blood_noticed'] = true;
        }
        if (event.metadata['diarrhea'] == true) m['diarrhea'] = true;
        if (event.metadata['constipation_or_straining'] == true) {
          m['constipation_or_straining'] = true;
        }
        if (event.metadata['unusual_odor'] == true) m['unusual_odor'] = true;
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
      case CatEventType.symptom:
        final symptoms = event.metadata['symptoms'];
        if (symptoms is List && symptoms.isNotEmpty) {
          m['symptoms'] = symptoms;
        }
      default:
        break;
    }
    return m;
  }

  void _removeEvent(int index) {
    setState(() {
      _events.removeAt(index);
      if (_events.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
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
        _Phase.followUp => _buildFollowUpPhase(),
        _Phase.error => _buildErrorPhase(),
      },
    );
  }

  Widget _buildReadyPhase() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Starting microphone...'),
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
                if (mounted) Navigator.of(context).pop();
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
                        : () {
                              _events.clear();
                              Navigator.of(context).pop();
                            },
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

  Widget _buildFollowUpPhase() {
    final total = _followUpQuestions.length;
    final current = _followUpIndex < total ? _followUpIndex + 1 : total;
    final question = _followUpIndex < total
        ? _followUpQuestions[_followUpIndex].spokenQuestion
        : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _followUpListening ? Icons.mic : Icons.chat_bubble_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Question $current of $total',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              question,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_followUpListening && _followUpPartial.isNotEmpty)
              Text(
                _followUpPartial,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (_followUpListening && _followUpPartial.isEmpty)
              Text(
                'Listening...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            if (!_followUpListening)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () async {
                await ref.read(sttServiceProvider).stop();
                _finishFollowUp();
              },
              child: const Text('Skip remaining'),
            ),
          ],
        ),
      ),
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
                  onPressed: () => Navigator.of(context).pop(),
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

enum _Phase { ready, listening, processing, confirm, followUp, error }

class _EditableEvent {
  _EditableEvent({
    required this.eventType,
    this.notes,
    required this.metadata,
    this.loggedAt,
  });

  factory _EditableEvent.fromParsed(ParsedEvent parsed) {
    return _EditableEvent(
      eventType: parsed.eventType,
      notes: parsed.notes,
      metadata: Map<String, dynamic>.from(parsed.metadata),
      loggedAt: parsed.loggedAt,
    );
  }

  CatEventType eventType;
  String? notes;
  Map<String, dynamic> metadata;
  DateTime? loggedAt;
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
      case CatEventType.litterScoop:
        return [
          SwitchListTile(
            dense: true,
            title: const Text('Blood noticed'),
            value: event.metadata['blood_noticed'] == true,
            onChanged: (val) {
              event.metadata['blood_noticed'] = val;
              onChanged(event);
            },
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Diarrhea'),
            value: event.metadata['diarrhea'] == true,
            onChanged: (val) {
              event.metadata['diarrhea'] = val;
              onChanged(event);
            },
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Constipation / straining'),
            value: event.metadata['constipation_or_straining'] == true,
            onChanged: (val) {
              event.metadata['constipation_or_straining'] = val;
              onChanged(event);
            },
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Unusual odor'),
            value: event.metadata['unusual_odor'] == true,
            onChanged: (val) {
              event.metadata['unusual_odor'] = val;
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
