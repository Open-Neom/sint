import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _TestCyclicNotifier extends ListNotifier {
  void triggerCycle() {
    void cyclic() {
      ListNotifier.enqueueBatchedComputed(cyclic);
    }

    ListNotifier.enqueueBatchedComputed(cyclic);
  }

  void notifyOnce() => refresh();
}

void main() {
  group('Lote 86 — sint router, PathTranslator, log redaction & batch cycle guard', () {
    test('sanitizeRouteInformationState blocks prototype keys, deep nesting & JS non-finite nums', () {
      expect(
        sanitizeRouteInformationState(<String, Object?>{'id': 42, 'ok': true}),
        isNotNull,
      );
      expect(
        sanitizeRouteInformationState(<String, Object?>{
          '__proto__': <String, Object?>{'admin': true},
        }),
        isNull,
      );
      expect(
        sanitizeRouteInformationState(<String, Object?>{
          'constructor': 'evil',
        }),
        isNull,
      );
      final jsInf = identical(0, 0.0)
          ? ((double.infinity as dynamic) as int)
          : double.infinity;
      expect(
        sanitizeRouteInformationState(<String, Object?>{'v': jsInf}),
        isNull,
      );

      // Build > 32 nested lists
      Object nested = 'leaf';
      for (var i = 0; i < 40; i++) {
        nested = <Object>[nested];
      }
      expect(sanitizeRouteInformationState(nested), isNull);
    });

    test('SintInformationParser.parseRouteInformation survives when SintRoot is unmounted', () async {
      final parser = SintInformationParser.createInformationParser(
        initialRoute: '/home',
      );
      final decoded = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/')),
      );
      expect(decoded.pageSettings?.path, equals('/home'));
    });

    test('PathTranslator splits on #fragment as well as ?query & rejects __proto__ segments', () {
      final translator = PathTranslator.build(
        translations: <String, Map<String, String>>{
          'es': <String, String>{
            'book': 'libro',
            'evil': '__proto__',
          },
        },
        routeSegments: <String>{'book', 'evil'},
      );

      expect(
        translator.canonicalizePath('/libro/abc123#capitulo-2'),
        equals('/book/abc123#capitulo-2'),
      );
      expect(
        translator.localizePath('/book/abc123#capitulo-2', 'es'),
        equals('/libro/abc123#capitulo-2'),
      );
      expect(
        translator.canonicalizePath('/__proto__/abc123'),
        equals('/__proto__/abc123'),
      );
    });

    test('resolveRoutePath strips C0/C1/Bidi control characters from templates and params', () {
      final resolved = resolveRoutePath(
        '/user/:id\u202E',
        pathParams: <String, String>{'id': '42\x00'},
        queryParams: <String, String>{'tab': 'books\r\n'},
      );
      expect(resolved, equals('/user/42?tab=books'));
    });

    test('sanitizeSintLogMessage strips Gemma-4 thought blocks, JWTs, api_key & UTF-16 surrogates', () {
      const msg =
          '<|channel>thought\nsecret\n<channel|>'
          'GET /v1/chat?api_key=abc123&id_token=xyz '
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.c2lnbmF0dXJl99';
      final out = sanitizeSintLogMessage(msg);
      expect(out, isNot(contains('thought')));
      expect(out, contains('api_key=REDACTED'));
      expect(out, contains('id_token=REDACTED'));
      expect(out, isNot(contains('eyJhbGci')));

      expect(sanitizeSintLogMessage('X🔥Y', maxChars: 2), equals('X'));
    });

    test('ListNotifier.batch breaks cyclic Computed/listener loops deterministically', () async {
      final rx = 0.obs;
      final helper = _TestCyclicNotifier();

      expect(
        () => ListNotifier.batch(() {
          rx.value = 1;
          helper.triggerCycle();
        }),
        throwsA(isA<StateError>()),
      );

      // Engine recovers cleanly after cyclic flush failure
      var syncNotified = 0;
      var streamNotified = 0;
      final removeSync = helper.addListener(() => syncNotified++);
      final sub = rx.listen((_) => streamNotified++);
      ListNotifier.batch(() {
        helper.notifyOnce();
        rx.value = 2;
      });
      expect(syncNotified, equals(1));
      await Future<void>.delayed(Duration.zero);
      expect(streamNotified, equals(1));
      removeSync();
      await sub.cancel();
      rx.close();
      helper.dispose();
    });
  });
}
