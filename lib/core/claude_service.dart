import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_type.dart';

class ParsedEvent {
  ParsedEvent({
    required this.eventType,
    this.catName,
    this.notes,
    this.metadata = const {},
  });

  final CatEventType eventType;
  final String? catName;
  final String? notes;
  final Map<String, dynamic> metadata;
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
    return '''You are a cat care logging assistant. Parse the user's voice transcript and extract one or more care events.

Return ONLY valid JSON in this format:
{
  "events": [
    {
      "event_type": $types,
      "cat_name": "<name if mentioned, else null>",
      "notes": "<any additional detail mentioned>",
      "metadata": {}
    }
  ]
}

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
      events.add(ParsedEvent(
        eventType: CatEventTypeX.fromStorageKey(
            map['event_type'] as String? ?? 'note'),
        catName: map['cat_name'] as String?,
        notes: map['notes'] as String?,
        metadata:
            (map['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ));
    }

    return ClaudeParseSuccess(events);
  }
}
