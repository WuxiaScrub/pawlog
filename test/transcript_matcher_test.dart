import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/core/transcript_matcher.dart';
import 'package:pawlog/models/event_type.dart';

void main() {
  const matcher = TranscriptMatcher();

  group('litter_scoop', () {
    test('matches "scooped the litter"', () {
      final r = matcher.tryMatch('scooped the litter');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.litterScoop);
    });

    test('matches "I just scooped litter"', () {
      final r = matcher.tryMatch('I just scooped litter');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.litterScoop);
    });

    test('matches "litter was scooped"', () {
      final r = matcher.tryMatch('litter was scooped');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.litterScoop);
    });

    test('matches case-insensitively', () {
      final r = matcher.tryMatch('SCOOPED THE LITTER');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.litterScoop);
    });

    test('matches "scooping the litter box"', () {
      final r = matcher.tryMatch('scooping the litter box');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.litterScoop);
    });
  });

  group('litter_change', () {
    test('matches "changed the litter"', () {
      final r = matcher.tryMatch('changed the litter');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.litterChange);
    });

    test('matches "fresh litter"', () {
      final r = matcher.tryMatch('put in fresh litter');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.litterChange);
    });

    test('matches "replaced the litter"', () {
      final r = matcher.tryMatch('replaced the litter');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.litterChange);
    });

    test('matches "dumped the old litter"', () {
      final r = matcher.tryMatch('dumped the old litter');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.litterChange);
    });

    test('matches "changed the entire litter"', () {
      final r = matcher.tryMatch('changed the entire litter');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.litterChange);
    });
  });

  group('water_change', () {
    test('matches "changed the water"', () {
      final r = matcher.tryMatch('changed the water');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.waterChange);
    });

    test('matches "fresh water"', () {
      final r = matcher.tryMatch('gave her fresh water');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.waterChange);
    });

    test('matches "refilled the water"', () {
      final r = matcher.tryMatch('refilled the water');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.waterChange);
    });

    test('matches "filled up the water bowl"', () {
      final r = matcher.tryMatch('filled up the water bowl');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.waterChange);
    });
  });

  group('vomit', () {
    test('matches "threw up"', () {
      final r = matcher.tryMatch('the cat threw up');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.vomit);
    });

    test('matches "vomited"', () {
      final r = matcher.tryMatch('kitty vomited');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.vomit);
    });

    test('matches "puked"', () {
      final r = matcher.tryMatch('she puked on the carpet');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.vomit);
    });

    test('matches "was sick"', () {
      final r = matcher.tryMatch('the cat was sick');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.vomit);
    });

    test('matches "got sick"', () {
      final r = matcher.tryMatch('she got sick after eating');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.vomit);
    });

    test('matches "being sick"', () {
      final r = matcher.tryMatch('the cat is being sick');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.vomit);
    });

    test('extracts notes from surrounding text', () {
      final r = matcher.tryMatch('she puked on the carpet');
      expect(r, isNotNull);
      expect(r!.notes, 'on the carpet');
    });
  });

  group('hairball', () {
    test('matches "hairball"', () {
      final r = matcher.tryMatch('found a hairball');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.hairball);
    });

    test('matches "hair ball" with space', () {
      final r = matcher.tryMatch('she had a hair ball');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.hairball);
    });
  });

  group('deworming', () {
    test('matches "dewormed"', () {
      final r = matcher.tryMatch('dewormed the cat');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.deworming);
    });

    test('matches "deworming"', () {
      final r = matcher.tryMatch('did the deworming today');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.deworming);
    });

    test('matches "worm treatment"', () {
      final r = matcher.tryMatch('gave her worm treatment');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.deworming);
    });
  });

  group('flea_treatment', () {
    test('matches "flea treatment"', () {
      final r = matcher.tryMatch('applied flea treatment');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.fleaTreatment);
    });

    test('matches "flea drops"', () {
      final r = matcher.tryMatch('gave her flea drops');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.fleaTreatment);
    });

    test('matches "flea and tick"', () {
      final r = matcher.tryMatch('did the flea and tick');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.fleaTreatment);
    });

    test('matches "tick medication"', () {
      final r = matcher.tryMatch('applied tick medication');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.fleaTreatment);
    });
  });

  group('feeding', () {
    test('matches "fed the cat"', () {
      final r = matcher.tryMatch('fed the cat');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.feeding);
    });

    test('matches "fed" alone', () {
      final r = matcher.tryMatch('just fed her');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.feeding);
    });

    test('matches "feeding"', () {
      final r = matcher.tryMatch('feeding time');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.feeding);
    });

    test('matches "gave him food"', () {
      final r = matcher.tryMatch('gave him food');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.feeding);
    });

    test('matches "breakfast time"', () {
      final r = matcher.tryMatch('breakfast time');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.feeding);
    });
  });

  group('playtime', () {
    test('matches "playtime"', () {
      final r = matcher.tryMatch('had some playtime');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.playtime);
    });

    test('matches "played with"', () {
      final r = matcher.tryMatch('played with the laser pointer');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.playtime);
    });

    test('matches "playing with"', () {
      final r = matcher.tryMatch('playing with the feather toy');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.playtime);
    });

    test('extracts duration from "played for 20 minutes"', () {
      final r = matcher.tryMatch('played for 20 minutes');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.playtime);
      expect(r!.metadata['duration_minutes'], 20);
    });

    test('extracts duration in hours', () {
      final r = matcher.tryMatch('played for 1 hour');
      expect(r, isNotNull);
      expect(r!.metadata['duration_minutes'], 60);
    });
  });

  group('weight', () {
    test('matches "weighed the cat"', () {
      final r = matcher.tryMatch('weighed the cat');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.weight);
    });

    test('matches "9 pounds"', () {
      final r = matcher.tryMatch("she's 9 pounds");
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.weight);
      expect(r!.metadata['weight_value'], 9.0);
      expect(r!.metadata['weight_unit'], 'lb');
    });

    test('matches "4.5 kg"', () {
      final r = matcher.tryMatch('kitty weighs 4.5 kg');
      expect(r, isNotNull);
      expect(r!.eventType, CatEventType.weight);
      expect(r!.metadata['weight_value'], 4.5);
      expect(r!.metadata['weight_unit'], 'kg');
    });

    test('matches "10 lbs"', () {
      final r = matcher.tryMatch('weight check 10 lbs');
      expect(r, isNotNull);
      expect(r!.metadata['weight_value'], 10.0);
      expect(r!.metadata['weight_unit'], 'lb');
    });
  });

  group('negation detection', () {
    test('rejects "forgot to scoop the litter"', () {
      expect(matcher.tryMatch('forgot to scoop the litter'), isNull);
    });

    test("rejects \"didn't scoop the litter\"", () {
      expect(matcher.tryMatch("didn't scoop the litter"), isNull);
    });

    test('rejects "need to change the water"', () {
      expect(matcher.tryMatch('need to change the water'), isNull);
    });

    test("rejects \"haven't fed the cat\"", () {
      expect(matcher.tryMatch("haven't fed the cat"), isNull);
    });

    test('rejects "should scoop the litter"', () {
      expect(matcher.tryMatch('should scoop the litter'), isNull);
    });

    test('rejects "going to change the litter"', () {
      expect(matcher.tryMatch('going to change the litter'), isNull);
    });

    test('rejects "remind me to scoop the litter"', () {
      expect(matcher.tryMatch('remind me to scoop the litter'), isNull);
    });

    test("rejects \"hasn't vomited\"", () {
      expect(matcher.tryMatch("she hasn't vomited"), isNull);
    });

    test('rejects "never threw up"', () {
      expect(matcher.tryMatch('she never threw up'), isNull);
    });

    test("rejects \"want to\" intent", () {
      expect(matcher.tryMatch('want to scoop the litter'), isNull);
    });
  });

  group('multi-event fallback', () {
    test('returns null for "scooped litter and changed water"', () {
      expect(
        matcher.tryMatch('scooped the litter and changed the water'),
        isNull,
      );
    });

    test('returns null for "threw up a hairball"', () {
      expect(matcher.tryMatch('threw up a hairball'), isNull);
    });

    test('returns null for "fed the cat and played with her"', () {
      expect(
        matcher.tryMatch('fed the cat and played with her'),
        isNull,
      );
    });
  });

  group('no match fallback', () {
    test('returns null for empty string', () {
      expect(matcher.tryMatch(''), isNull);
    });

    test('returns null for unrecognized text', () {
      expect(matcher.tryMatch('the weather is nice today'), isNull);
    });

    test('returns null for just "litter" (ambiguous)', () {
      expect(matcher.tryMatch('litter'), isNull);
    });
  });

  group('notes extraction', () {
    test('returns null notes for clean keyword match', () {
      final r = matcher.tryMatch('scooped the litter');
      expect(r!.notes, isNull);
    });

    test('strips leading filler words', () {
      final r = matcher.tryMatch('I just scooped the litter');
      expect(r!.notes, isNull);
    });

    test('preserves meaningful extra text', () {
      final r = matcher.tryMatch('scooped the litter it was smelly');
      expect(r, isNotNull);
      expect(r!.notes, 'it was smelly');
    });

    test('preserves original casing in notes', () {
      final r = matcher.tryMatch('Vomited on the Persian Rug');
      expect(r, isNotNull);
      expect(r!.notes, contains('Persian Rug'));
    });
  });
}
