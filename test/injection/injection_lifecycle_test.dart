// Sint injection lifecycle edge-case tests.
// Focus: put/lazyPut/permanent/fenix, double-registration, find error
// paths, putAsync, replace.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _CounterController extends SintController {
  int count = 0;
  int initCount = 0;
  int closeCount = 0;
  bool ready = false;

  @override
  void onInit() {
    super.onInit();
    initCount++;
  }

  @override
  void onReady() {
    super.onReady();
    ready = true;
  }

  @override
  void onClose() {
    closeCount++;
    super.onClose();
  }
}

class _Service {
  final String name;
  _Service(this.name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Sint.reset);

  group('Sint.put / find round-trip', () {
    test('put then find returns the same instance', () {
      final s = _Service('a');
      Sint.put<_Service>(s);
      expect(identical(Sint.find<_Service>(), s), isTrue);
    });

    test('put with tag is isolated from untagged', () {
      Sint.put<_Service>(_Service('default'));
      Sint.put<_Service>(_Service('alt'), tag: 'alt');
      expect(Sint.find<_Service>().name, 'default');
      expect(Sint.find<_Service>(tag: 'alt').name, 'alt');
    });

    test('two different tags do not collide', () {
      Sint.put<_Service>(_Service('one'), tag: 'one');
      Sint.put<_Service>(_Service('two'), tag: 'two');
      expect(Sint.find<_Service>(tag: 'one').name, 'one');
      expect(Sint.find<_Service>(tag: 'two').name, 'two');
    });
  });

  group('find error paths', () {
    test('find before put throws a clear error mentioning the type', () {
      // Sint throws a String message – assert the message content is helpful.
      expect(
        () => Sint.find<_Service>(),
        throwsA(
          predicate(
            (e) => e.toString().contains('_Service') && e.toString().contains('not found'),
          ),
        ),
      );
    });

    test('findOrNull returns null instead of throwing', () {
      expect(Sint.findOrNull<_Service>(), isNull);
    });

    test('find with the wrong tag throws', () {
      Sint.put<_Service>(_Service('a'));
      expect(() => Sint.find<_Service>(tag: 'missing'), throwsA(anything));
      // But the untagged one is still resolvable.
      expect(Sint.find<_Service>().name, 'a');
    });
  });

  group('lazyPut deferred creation', () {
    test('builder is not invoked until first find', () {
      var built = 0;
      Sint.lazyPut<_Service>(() {
        built++;
        return _Service('lazy');
      });
      expect(built, 0, reason: 'lazyPut must defer construction');
      expect(Sint.isRegistered<_Service>(), isTrue);
      expect(Sint.isPrepared<_Service>(), isTrue);

      Sint.find<_Service>();
      expect(built, 1);

      Sint.find<_Service>();
      expect(built, 1, reason: 'singleton — should not rebuild');
      expect(Sint.isPrepared<_Service>(), isFalse,
          reason: 'after first resolution it is no longer "prepared"');
    });

    test('subsequent lazyPut for the same type is ignored (no replace)', () {
      Sint.lazyPut<_Service>(() => _Service('first'));
      Sint.lazyPut<_Service>(() => _Service('second'));
      expect(Sint.find<_Service>().name, 'first');
    });
  });

  group('permanent vs fenix', () {
    test('permanent: true survives a normal delete', () {
      Sint.put<_Service>(_Service('forever'), permanent: true);
      final removed = Sint.delete<_Service>();
      expect(removed, isFalse);
      expect(Sint.isRegistered<_Service>(), isTrue);
      expect(Sint.find<_Service>().name, 'forever');
    });

    test('permanent + force=true does delete', () {
      Sint.put<_Service>(_Service('forever'), permanent: true);
      final removed = Sint.delete<_Service>(force: true);
      expect(removed, isTrue);
      expect(Sint.isRegistered<_Service>(), isFalse);
    });

    test('fenix recreates the instance after delete via builder', () {
      var built = 0;
      Sint.lazyPut<_Service>(() {
        built++;
        return _Service('phoenix-$built');
      }, fenix: true);

      expect(Sint.find<_Service>().name, 'phoenix-1');
      Sint.delete<_Service>();
      // After fenix delete the registration remains (factory still alive).
      expect(Sint.isRegistered<_Service>(), isTrue);
      expect(Sint.find<_Service>().name, 'phoenix-2',
          reason: 'fenix should recreate');
    });

    test('non-fenix lazyPut: after delete the factory is gone', () {
      Sint.lazyPut<_Service>(() => _Service('once'));
      Sint.find<_Service>();
      Sint.delete<_Service>();
      expect(Sint.isRegistered<_Service>(), isFalse);
      expect(() => Sint.find<_Service>(), throwsA(anything));
    });
  });

  group('replace / lazyReplace', () {
    test('replace swaps the instance, find returns the new one', () {
      Sint.put<_Service>(_Service('old'));
      Sint.replace<_Service>(_Service('new'));
      expect(Sint.find<_Service>().name, 'new');
    });

    test('replace preserves permanent flag', () {
      Sint.put<_Service>(_Service('old'), permanent: true);
      Sint.replace<_Service>(_Service('new'));
      // The new instance should also be permanent.
      final info = Sint.getInstanceInfo<_Service>();
      expect(info.isPermanent, isTrue);
      expect(Sint.delete<_Service>(), isFalse);
      expect(Sint.find<_Service>().name, 'new');
    });

    test('lazyReplace defers building and inherits permanent->fenix', () {
      Sint.put<_Service>(_Service('old'), permanent: true);
      var built = 0;
      Sint.lazyReplace<_Service>(() {
        built++;
        return _Service('lazy-new');
      });
      expect(built, 0);
      expect(Sint.find<_Service>().name, 'lazy-new');
      expect(built, 1);
      // Because parent was permanent, lazyReplace defaulted fenix=true –
      // delete should not break find.
      Sint.delete<_Service>();
      expect(Sint.find<_Service>().name, 'lazy-new');
      expect(built, 2);
    });
  });

  group('putAsync', () {
    test('putAsync registers the resolved value as singleton', () async {
      final s = await Sint.putAsync<_Service>(
        () async => _Service('async'),
      );
      expect(s.name, 'async');
      expect(identical(Sint.find<_Service>(), s), isTrue);
    });

    test('putAsync error propagates and nothing is registered', () async {
      await expectLater(
        Sint.putAsync<_Service>(() async => throw StateError('boom')),
        throwsStateError,
      );
      expect(Sint.isRegistered<_Service>(), isFalse);
    });
  });

  group('putOrFind', () {
    test('returns existing instance if registered', () {
      final original = _Service('orig');
      Sint.put<_Service>(original);
      final got = Sint.putOrFind<_Service>(() => _Service('other'));
      expect(identical(got, original), isTrue);
    });

    test('puts a new one when not registered', () {
      final got = Sint.putOrFind<_Service>(() => _Service('fresh'));
      expect(got.name, 'fresh');
      expect(identical(Sint.find<_Service>(), got), isTrue);
    });
  });

  group('SintController lifecycle order', () {
    testWidgets('onInit then onReady are called when find triggers it',
        (tester) async {
      Sint.lazyPut<_CounterController>(() => _CounterController());
      final c = Sint.find<_CounterController>();
      expect(c.initCount, 1, reason: 'onInit fires on first find');
      expect(c.ready, isFalse, reason: 'onReady deferred to next frame');
      // pumpWidget triggers a frame, which fires the post-frame callback.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(c.ready, isTrue);
    });

    test('onClose runs when the controller is deleted', () {
      Sint.put<_CounterController>(_CounterController());
      final c = Sint.find<_CounterController>();
      expect(c.closeCount, 0);
      Sint.delete<_CounterController>();
      expect(c.closeCount, 1);
      expect(c.isClosed, isTrue);
    });

    test('onInit only fires once even if find is called many times', () {
      Sint.lazyPut<_CounterController>(() => _CounterController());
      Sint.find<_CounterController>();
      Sint.find<_CounterController>();
      Sint.find<_CounterController>();
      expect(Sint.find<_CounterController>().initCount, 1);
    });

    test('reload re-runs onClose then nullifies dependency', () {
      Sint.put<_CounterController>(_CounterController());
      final c = Sint.find<_CounterController>();
      Sint.reload<_CounterController>();
      expect(c.closeCount, 1);
    });
  });

  group('deleteAll & resetInstance', () {
    test('deleteAll removes all non-permanent', () {
      Sint.put<_Service>(_Service('a'));
      Sint.put<_CounterController>(_CounterController());
      Sint.put<_Service>(_Service('p'), tag: 'p', permanent: true);
      Sint.deleteAll();
      expect(Sint.isRegistered<_Service>(), isFalse);
      expect(Sint.isRegistered<_CounterController>(), isFalse);
      expect(Sint.isRegistered<_Service>(tag: 'p'), isTrue,
          reason: 'permanent survives plain deleteAll');
    });

    test('Sint.reset clears even permanent instances', () {
      Sint.put<_Service>(_Service('p'), permanent: true);
      Sint.reset();
      expect(Sint.isRegistered<_Service>(), isFalse);
    });
  });
}
