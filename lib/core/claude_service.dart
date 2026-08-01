import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_type.dart';

class ParsedEvent {
  ParsedEvent({
    required this.eventType,
    this.catName,
    this.notes,
    this.metadata = const {},
    this.loggedAt,
  });

  final CatEventType eventType;
  final String? catName;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime? loggedAt;
}

sealed class ClaudeParseResult {}

class ClaudeParseSuccess extends ClaudeParseResult {
  ClaudeParseSuccess(this.events);
  final List<ParsedEvent> events;
}

class ClaudeParseError extends ClaudeParseResult {
  ClaudeParseError(this.message, {this.rawResponse});
  final String message;
  final String? rawResponse;
}

class ClaudeService {
  ClaudeService(this._apiKey);
  final String _apiKey;

  static const _maxTranscriptLength = 500;

  static String get _systemPrompt {
    final types =
        CatEventType.values.map((t) => '"${t.storageKey}"').join(' | ');
    final now = DateTime.now().toIso8601String();
    return '''You are a cat care logging assistant. Parse the user's voice transcript and extract one or more care events. The current date/time is $now.

Return ONLY valid JSON in this format:
{
  "events": [
    {
      "event_type": $types,
      "cat_name": "<name if mentioned, else null>",
      "notes": "<only genuinely useful additional detail — omit filler words, pronouns, and restatements of the event itself. Set to null if there is nothing meaningful beyond the event type>",
      "logged_at": "<ISO 8601 timestamp if a specific time is mentioned, else null>",
      "metadata": {}
    }
  ]
}

If the user mentions a time (e.g. "at 10 AM", "this morning", "yesterday", "a couple hours ago"), compute the corresponding ISO 8601 timestamp for logged_at. If no time is mentioned, set logged_at to null.
Strip filler words (um, uh, hey, like, you know, I mean, so, okay, well) and pronouns from notes. If after stripping there is nothing meaningful left, set notes to null.
If no recognizable event is found, return: { "events": [] }
Do not include any explanation or text outside the JSON.''';
  }

  Future<ClaudeParseResult> parseTranscript(String transcript) async {
    final trimmed = transcript.length > _maxTranscriptLength
        ? transcript.substring(0, _maxTranscriptLength)
        : transcript;

    final body = jsonEncode({
      'model': 'claude-haiku-4-5-20241022',
      'max_tokens': 1024,
      'system': _systemPrompt,
      'messages': [
        {'role': 'user', 'content': trimmed},
      ],
    });

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: body,
      );
    } catch (e) {
      return ClaudeParseError('Network error: $e');
    }

    if (response.statusCode != 200) {
      return ClaudeParseError(
        'API error (${response.statusCode})',
        rawResponse: response.body,
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final content = json['content'] as List;
      final text = content.first['text'] as String;
      return _extractEvents(text);
    } catch (e) {
      return ClaudeParseError('Failed to parse response: $e',
          rawResponse: response.body);
    }
  }

  ClaudeParseResult _extractEvents(String text) {
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        try {
          parsed = jsonDecode(text.substring(start, end + 1))
              as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    if (parsed == null) {
      return ClaudeParseError('Could not parse JSON from response',
          rawResponse: text);
    }

    final rawEvents = parsed['events'] as List? ?? [];
    final events = <ParsedEvent>[];

    for (final e in rawEvents) {
      final map = e as Map<String, dynamic>;
      final loggedAtStr = map['logged_at'] as String?;
      DateTime? loggedAt;
      if (loggedAtStr != null) {
        loggedAt = DateTime.tryParse(loggedAtStr);
        if (loggedAt != null && loggedAt.isAfter(DateTime.now())) {
          loggedAt = null;
        }
      }
      events.add(ParsedEvent(
        eventType: CatEventTypeX.fromStorageKey(
            map['event_type'] as String? ?? 'note'),
        catName: map['cat_name'] as String?,
        notes: map['notes'] as String?,
        metadata:
            (map['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        loggedAt: loggedAt,
      ));
    }

    return ClaudeParseSuccess(events);
  }
}
