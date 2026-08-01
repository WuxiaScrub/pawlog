import '../models/event_type.dart';

class MatchResult {
  MatchResult({
    required this.eventType,
    this.notes,
    this.metadata = const {},
    this.loggedAt,
  });

  final CatEventType eventType;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime? loggedAt;
}

class TranscriptMatcher {
  const TranscriptMatcher();

  // "litter" / "liter" / "litre" are homophones — STT often picks the wrong one.
  static const _litter = r'(litt?er|litre)';

  // "flea" / "flee" are homophones.
  static const _flea = r'(flea|flee)';

  static final _rules = <_EventRule>[
    _EventRule(CatEventType.litterScoop, [
      RegExp('scoop(ed|s|ing)?\\s+(the\\s+)?$_litter'),
      RegExp('$_litter\\s+(was\\s+|is\\s+)?scoop(ed|s)'),
    ]),
    _EventRule(CatEventType.litterChange, [
      RegExp(
          'chang(ed|e|ing)\\s+(the\\s+)?(entire\\s+|whole\\s+|all\\s+(the\\s+)?)?$_litter'),
      RegExp('$_litter\\s+(was\\s+)?chang(ed|e)'),
      RegExp('replac(ed|e|ing)\\s+(the\\s+)?$_litter'),
      RegExp('(fresh|new)\\s+$_litter'),
      RegExp('swap(ped|ping)?\\s+(the\\s+)?$_litter'),
      RegExp('dump(ed|ing)?\\s+(out\\s+)?(the\\s+)?(old\\s+)?$_litter'),
    ]),
    _EventRule(CatEventType.waterChange, [
      RegExp(r"chang(ed|e|ing)\s+(the\s+)?(cat'?s?\s+)?water"),
      RegExp(r'water\s+(was\s+)?chang(ed|e)'),
      RegExp(r'(fresh|new|clean)\s+water'),
      RegExp(r'refill(ed|ing)?\s+(the\s+)?water'),
      RegExp(
          r'fill(ed|ing)?\s+(up\s+)?(the\s+)?water\s*(bowl|dish|fountain)'),
    ]),
    _EventRule(CatEventType.vomit, [
      RegExp(r'(threw|through)\s+up'),
      RegExp(r'throw(ing|s)?\s+up'),
      RegExp(r'vomit(ed|ing|s)?'),
      RegExp(r'puke[ds]?|puking'),
      RegExp(r'(was|got|been|is)\s+sick'),
      RegExp(r'being\s+sick'),
      RegExp(r'sick(ed)?\s+up'),
    ]),
    _EventRule(CatEventType.hairball, [
      RegExp(r'hair\s*ball'),
    ]),
    _EventRule(CatEventType.deworming, [
      RegExp(r'de\s*worm(ed|ing|s|er)?'),
      RegExp(r'worm(ing)?\s+(treatment|medicine|meds|tablet|pill|paste)'),
    ]),
    _EventRule(CatEventType.fleaTreatment, [
      RegExp(
          '$_flea\\s*(treatment|medicine|meds|drops|medication|collar|spray)'),
      RegExp(
          r'tick\s*(treatment|medicine|meds|drops|medication|collar|spray)'),
      RegExp('$_flea\\s+and\\s+tick'),
      RegExp('applied\\s+(the\\s+)?$_flea'),
      RegExp('anti\\s*-?\\s*($_flea|tick)'),
    ]),
    _EventRule(CatEventType.feeding, [
      RegExp(r'\bfed\b'),
      RegExp(r'\bfeeding\b'),
      RegExp(
          r'gave\s+(him|her|them|the\s+cat|\w+)\s+(food|treats?|dinner|breakfast|lunch|meal|snack)'),
      RegExp(r'put\s+(out\s+)?(the\s+)?food'),
      RegExp(r'fill(ed|ing)?\s+(up\s+)?(the\s+)?food\s*(bowl|dish)'),
      RegExp(r'(breakfast|dinner|lunch|supper)\s+time'),
    ]),
    _EventRule(CatEventType.playtime, [
      RegExp(r'play\s*time'),
      RegExp(r'played\s+(with|for)'),
      RegExp(r'playing\s+with'),
    ]),
    _EventRule(CatEventType.weight, [
      RegExp(r'weigh(ed|s|ing)?\b'),
      RegExp(r'\bweight\s+(check|is|was|at)'),
      RegExp(r'\d+(\.\d+)?\s*(lbs?|pounds?|kgs?|kilos?|kilograms?)'),
    ]),
  ];

  static final _negationPattern = RegExp(
    r"(forgot\s+to|forget\s+to|didn'?t|did\s+not|don'?t|do\s+not"
    r"|haven'?t|have\s+not|hasn'?t|has\s+not"
    r"|need\s+to|needs\s+to|should"
    r"|want\s+to|wants\s+to|wanted\s+to"
    r"|going\s+to|gonna"
    r"|won'?t|will\s+not|can'?t|cannot|couldn'?t|could\s+not"
    r"|\bnot\b|\bnever\b"
    r"|remind\s+me\s+to|remember\s+to|plan\s+to|about\s+to)",
  );

  MatchResult? tryMatch(String transcript) {
    final text = transcript.trim().toLowerCase();
    if (text.isEmpty) return null;

    _MatchHit? hit;
    var matchCount = 0;

    for (final rule in _rules) {
      for (final pattern in rule.patterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          if (_hasNegation(text, match.start)) return null;
          matchCount++;
          if (matchCount > 1) return null;
          hit = _MatchHit(rule.eventType, match);
          break;
        }
      }
    }

    if (hit == null) return null;

    final timeResult = _extractTime(text);
    final notes = _extractNotes(
      transcript,
      hit.match,
      timeResult?.matchRange,
    );
    final metadata = _extractMetadata(hit.eventType, text);

    if (notes != null && _hasAmbiguousContent(notes)) return null;

    return MatchResult(
      eventType: hit.eventType,
      notes: notes,
      metadata: metadata,
      loggedAt: timeResult?.dateTime,
    );
  }

  bool _hasNegation(String text, int matchStart) {
    final before = text.substring(0, matchStart);
    final words =
        before.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final window = words.length <= 4 ? words : words.sublist(words.length - 4);
    final windowText = window.join(' ');
    return _negationPattern.hasMatch(windowText);
  }

  static final _ambiguousPattern = RegExp(
    r"(\d{1,2}\s*(o'?clock|hours?|minutes?|mins?|hrs?))"
    r'|(ago|last\s+night|this\s+morning|yesterday|before|after|earlier|later)'
    r'|(because|since|when|while|but|however|although)',
    caseSensitive: false,
  );

  bool _hasAmbiguousContent(String notes) {
    if (_ambiguousPattern.hasMatch(notes)) return true;
    final words = notes.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.length >= 5;
  }

  /// Matches leftovers that are nothing but a container noun, optionally with
  /// an article — "box", "the litter tray", "his water bowl".
  static final _bareContainerPattern = RegExp(
    r'^(the\s+|his\s+|her\s+|their\s+|my\s+)?'
    r'(litt?er\s+|litre\s+|water\s+|food\s+|cat\s+)?'
    r'(box(es)?|tray|bowl|dish|fountain|pan)$',
    caseSensitive: false,
  );

  static final _timePattern = RegExp(
    r'(yesterday\s+)?'
    r'(?:at\s+|around\s+)?'
    r'(\d{1,2})(?::(\d{2}))?\s*'
    r'(a\.?m\.?|p\.?m\.?)'
    r'(?:\s+(?:this\s+)?(?:morning|afternoon|evening|tonight))?',
    caseSensitive: false,
  );

  _TimeResult? _extractTime(String text) {
    final m = _timePattern.firstMatch(text);
    if (m == null) return null;

    var hour = int.tryParse(m.group(2)!);
    final minute = int.tryParse(m.group(3) ?? '0') ?? 0;
    final amPm = m.group(4)!.toLowerCase().replaceAll('.', '');
    if (hour == null || hour < 1 || hour > 12) return null;
    if (minute < 0 || minute > 59) return null;

    if (amPm == 'pm' && hour != 12) hour += 12;
    if (amPm == 'am' && hour == 12) hour = 0;

    final isYesterday = m.group(1) != null;
    var date = DateTime.now();
    if (isYesterday) date = date.subtract(const Duration(days: 1));

    final result = DateTime(date.year, date.month, date.day, hour, minute);
    if (result.isAfter(DateTime.now())) return null;

    return _TimeResult(result, _Range(m.start, m.end));
  }

  String? _extractNotes(String original, Match match, [_Range? timeRange]) {
    var remaining =
        (original.substring(0, match.start) + original.substring(match.end))
            .trim();

    if (timeRange != null) {
      final adjusted = _Range(
        timeRange.start > match.start
            ? timeRange.start - (match.end - match.start)
            : timeRange.start,
        timeRange.end > match.start
            ? timeRange.end - (match.end - match.start)
            : timeRange.end,
      );
      if (adjusted.start >= 0 && adjusted.end <= remaining.length) {
        remaining = (remaining.substring(0, adjusted.start) +
                remaining.substring(adjusted.end))
            .trim();
      }
    }

    remaining = remaining.replaceFirst(
      RegExp(
        r'(hey\s+|hi\s+|oh\s+|ah\s+|ok(ay)?\s+|well\s+|yeah\s+|yep\s+|yo\s+|um+\s+|uh+\s+|er+\s+|hm+\s+|hmm+\s+)*'
        r"(i\s+|i'?ve\s+|we\s+|we'?ve\s+|she\s+|he\s+|it'?s\s+)?"
        r'(just\s+|also\s+|already\s+|and\s+|so\s+|then\s+|like\s+)*'
        r'(did\s+|gave\s+(her|him|them|the\s+cat)\s+|put\s+(out\s+)?)?'
        r'(the\s+cat\s+|my\s+cat\s+|kitty\s+|the\s+|a\s+)?',
        caseSensitive: false,
      ),
      '',
    );

    remaining = remaining.replaceFirst(
      RegExp(
        r'\s*(and|so|then|also|now|today|already|again|too|though|okay|ok|yeah|yep|right)\s*$',
        caseSensitive: false,
      ),
      '',
    );

    remaining = remaining.replaceAll(
      RegExp(
        r'\b(um+|uh+|er+|hm+|hmm+|like|you\s+know|i\s+mean|sort\s+of|kind\s+of)\b',
        caseSensitive: false,
      ),
      '',
    );

    remaining = remaining.replaceAll(RegExp(r'\s{2,}'), ' ');
    remaining = remaining.replaceAll(RegExp(r'^[,.\s;:!]+|[,.\s;:!]+$'), '');

    // The event patterns stop at the noun ("scooped the litter"), so a phrase
    // like "scooped the litter box" leaves a bare container word behind. Drop
    // it when that is all that is left — but only then, so a real note such as
    // "water bowl is cracked" keeps its subject.
    if (_bareContainerPattern.hasMatch(remaining)) return null;

    return remaining.isEmpty ? null : remaining;
  }

  Map<String, dynamic> _extractMetadata(CatEventType eventType, String text) {
    final meta = <String, dynamic>{};

    switch (eventType) {
      case CatEventType.weight:
        final weightMatch = RegExp(
          r'(\d+(?:\.\d+)?)\s*(lbs?|pounds?|kgs?|kilos?|kilograms?)?',
        ).firstMatch(text);
        if (weightMatch != null) {
          final value = double.tryParse(weightMatch.group(1)!);
          if (value != null) {
            final unit = weightMatch.group(2) ?? '';
            final isLbs = unit.startsWith('lb') || unit.startsWith('pound');
            meta['weight_value'] = value;
            meta['weight_unit'] = isLbs ? 'lb' : 'kg';
          }
        }
      case CatEventType.playtime:
        final durMatch = RegExp(
          r'(\d+)\s*(minutes?|mins?|hours?|hrs?)',
        ).firstMatch(text);
        if (durMatch != null) {
          var minutes = int.tryParse(durMatch.group(1)!) ?? 0;
          final unit = durMatch.group(2)!;
          if (unit.startsWith('hour') || unit.startsWith('hr')) {
            minutes *= 60;
          }
          if (minutes > 0) meta['duration_minutes'] = minutes;
        }
      default:
        break;
    }

    return meta;
  }
}

class _EventRule {
  _EventRule(this.eventType, this.patterns);
  final CatEventType eventType;
  final List<RegExp> patterns;
}

class _MatchHit {
  _MatchHit(this.eventType, this.match);
  final CatEventType eventType;
  final Match match;
}

class _Range {
  _Range(this.start, this.end);
  final int start;
  final int end;
}

class _TimeResult {
  _TimeResult(this.dateTime, this.matchRange);
  final DateTime dateTime;
  final _Range matchRange;
}
