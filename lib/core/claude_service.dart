import 'supabase_client.dart';

/// Sends a voice transcript to the `parse-voice-event` Supabase Edge
/// Function, which holds the Anthropic API key server-side and proxies the
/// call to Claude Haiku. The client never sees the key.
class ClaudeService {
  const ClaudeService();

  static const _maxTranscriptChars = 500;

  Future<List<Map<String, dynamic>>> parseTranscript(String transcript) async {
    final capped = transcript.length > _maxTranscriptChars
        ? transcript.substring(0, _maxTranscriptChars)
        : transcript;

    final response = await supabase.functions.invoke(
      'parse-voice-event',
      body: {'transcript': capped},
    );

    final events = (response.data as Map<String, dynamic>)['events'] as List?;
    return (events ?? const []).cast<Map<String, dynamic>>();
  }
}
