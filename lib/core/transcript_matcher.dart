import '../models/event_type.dart';

class MatchResult {
  MatchResult({
    required this.eventType,
    this.notes,
    this.metadata = const {},
  });

  final CatEventType eventType;
  final String? notes;
  final Map<String, dynamic> metadata;
}

class TranscriptMatcher {
  const TranscriptMatcher();

  static final _rules = <_EventRule>[
    _EventRule(CatEventType.litterScoop, [
      RegExp(r'scoop(ed|s|ing)?\s+(the\s+)?litter'),
      RegExp(r'litter\s+(was\s+|is\s+)?scoop(ed|s)'),
    ]),
    _EventRule(CatEventType.litterChange, [
      RegExp(
          r'chang(ed|e|ing)\s+(the\s+)?(entire\s+|whole\s+|all\s+(the\s+)?)?litter'),
      RegExp(r'litter\s+(was\s+)?chang(ed|e)'),
      RegExp(r'replac(ed|e|ing)\s+(the\s+)?litter'),
      RegExp(r'(fresh|new)\s+litter'),
      RegExp(r'swap(ped|ping)?\s+(the\s+)?litter'),
      RegExp(r'dump(ed|ing)?\s+(out\s+)?(the\s+)?(old\s+)?litter'),
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
      RegExp(r'threw\s+up'),
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
          r'flea\s*(treatment|medicine|meds|drops|medication|collar|spray)'),
      RegExp(
          r'tick\s*(treatment|medicine|meds|drops|medication|collar|spray)'),
      RegExp(r'flea\s+and\s+tick'),
      RegExp(r'applied\s+(the\s+)?flea'),
      RegExp(r'anti\s*-?\s*(flea|tick)'),
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

    final notes = _extractNotes(transcript, hit.match);
    final metadata = _extractMetadata(hit.eventType, text);

    return MatchResult(
      eventType: hit.eventType,
      notes: notes,
      metadata: metadata,
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

  String? _extractNotes(String original, Match match) {
    var remaining =
        (original.substring(0, match.start) + original.substring(match.end))
            .trim();

    remaining = remaining.replaceFirst(
      RegExp(
        r'^(i\s+)?(just\s+|also\s+|and\s+|so\s+|then\s+)*'
        r'(the\s+cat\s+|my\s+cat\s+|kitty\s+)?',
        caseSensitive: false,
      ),
      '',
    );

    remaining = remaining.replaceFirst(
      RegExp(r'\s*(and|so|then|also)\s*$', caseSensitive: false),
      '',
    );

    remaining = remaining.replaceAll(RegExp(r'^[,.\s;:!]+|[,.\s;:!]+$'), '');

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
