import 'package:flutter_test/flutter_test.dart';
import 'package:wp_player/utils/data_parse/http_link_parsing/check_translate_http_link_to_player_link.dart';

void main() {
  group('checkTranslateHTTPLinkToPlayerLink', () {
    test('should convert dev listen link', () {
      expect(
        checkTranslateHTTPLinkToPlayerLink(
          'https://guide-dev.wavepaths.com/listen/free/8f902420-853b-4962-adb1-2de19e59fd3e',
        ),
        'wavepaths2://listen/dev/free/playerlib/8f902420-853b-4962-adb1-2de19e59fd3e',
      );
    });
    test('should convert prod listen link', () {
      expect(
        checkTranslateHTTPLinkToPlayerLink(
          'https://guide.wavepaths.com/listen/free/91747df4-0f86-4fd5-9150-0d397bdf2de0',
        ),
        'wavepaths2://listen/prod/free/playerlib/91747df4-0f86-4fd5-9150-0d397bdf2de0',
      );
    });
    test('should convert local listen link', () {
      expect(
        checkTranslateHTTPLinkToPlayerLink('http://localhost:8080/listen/free/91747df4-0f86-4fd5-9150-0d397bdf2de0'),
        'wavepaths2://listen/dev-local/free/playerlib/91747df4-0f86-4fd5-9150-0d397bdf2de0',
      );
    });
    test('should convert dev session link', () {
      expect(
        checkTranslateHTTPLinkToPlayerLink(
          'https://guide-dev.wavepaths.com/session/0aa1fa96-850f-4a6f-b788-44520bb5ccbb',
        ),
        'wavepaths2://session/dev/playerlib/0aa1fa96-850f-4a6f-b788-44520bb5ccbb',
      );
    });
    test('should convert prod session link', () {
      expect(
        checkTranslateHTTPLinkToPlayerLink('https://guide.wavepaths.com/session/cfba567c-e30c-40a5-8500-aecf2b420ffd'),
        'wavepaths2://session/prod/playerlib/cfba567c-e30c-40a5-8500-aecf2b420ffd',
      );
    });
    test('should convert local session link', () {
      expect(
        checkTranslateHTTPLinkToPlayerLink('https://localhost:8080/session/cfba567c-e30c-40a5-8500-aecf2b420ffd'),
        'wavepaths2://session/dev-local/playerlib/cfba567c-e30c-40a5-8500-aecf2b420ffd',
      );
    });
    test('should return null for malformed input', () {
      expect(checkTranslateHTTPLinkToPlayerLink('some_malformed input'), null);
    });
    test('returns null for unrelated http link', () {
      expect(checkTranslateHTTPLinkToPlayerLink('https://example.com/listen/free/123456'), null);
    });
    test('returns null for empty string', () {
      expect(checkTranslateHTTPLinkToPlayerLink(''), null);
    });

    test('returns null for incorrect connection type', () {
      expect(
        checkTranslateHTTPLinkToPlayerLink('https://localhost:8080/book/cfba567c-e30c-40a5-8500-aecf2b420ffd'),
        null,
      );
    });
  });
}
