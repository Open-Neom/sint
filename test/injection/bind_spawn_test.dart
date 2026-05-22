// Sint additional injection tests: Bind facade, spawn (factory mode),
// isRegistered/isPrepared, getInstanceInfo correctness, reload semantics.
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _Counter {
  int n = 0;
  void inc() => n++;
}

class _Resource {
  static int built = 0;
  _Resource() {
    built++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    _Resource.built = 0;
  });
  tearDown(Sint.reset);

  group('Bind facade mirrors Sint', () {
    test('Bind.put + Bind.find returns same instance as Sint', () {
      Bind.put<_Counter>(_Counter());
      final viaBind = Bind.find<_Counter>();
      final viaSint = Sint.find<_Counter>();
      expect(identical(viaBind, viaSint), isTrue);
    });

    test('Bind.lazyPut defers and Bind.delete clears it', () async {
      var built = 0;
      Bind.lazyPut<_Counter>(() {
        built++;
        return _Counter();
      });
      expect(built, 0);
      Bind.find<_Counter>();
      expect(built, 1);
      await Bind.delete<_Counter>();
      expect(Bind.isRegistered<_Counter>(), isFalse);
    });

    test('Bind.isRegistered reflects current state', () {
      expect(Bind.isRegistered<_Counter>(), isFalse);
      Bind.put<_Counter>(_Counter());
      expect(Bind.isRegistered<_Counter>(), isTrue);
    });
  });

  group('Sint.spawn (factory mode)', () {
    test('every find returns a NEW instance', () {
      Sint.spawn<_Resource>(() => _Resource());
      final a = Sint.find<_Resource>();
      final b = Sint.find<_Resource>();
      // spawn factory invokes builder per find.
      expect(_Resource.built, greaterThanOrEqualTo(2));
      expect(identical(a, b), isFalse);
    });

    test('isRegistered remains true even after many finds', () {
      Sint.spawn<_Resource>(() => _Resource());
      Sint.find<_Resource>();
      Sint.find<_Resource>();
      expect(Sint.isRegistered<_Resource>(), isTrue);
    });
  });

  group('isPrepared semantics', () {
    test('isPrepared = true after lazyPut and false after first find', () {
      Sint.lazyPut<_Counter>(() => _Counter());
      expect(Sint.isPrepared<_Counter>(), isTrue);
      Sint.find<_Counter>();
      expect(Sint.isPrepared<_Counter>(), isFalse);
    });

    test('isPrepared = false when not registered at all', () {
      expect(Sint.isPrepared<_Counter>(), isFalse);
    });
  });

  group('getInstanceInfo accuracy', () {
    test('reports permanent flag', () {
      Sint.put<_Counter>(_Counter(), permanent: true);
      final info = Sint.getInstanceInfo<_Counter>();
      expect(info.isPermanent, isTrue);
      expect(info.isRegistered, isTrue);
      expect(info.isSingleton, isTrue);
    });

    test('reports unregistered cleanly', () {
      final info = Sint.getInstanceInfo<_Counter>();
      expect(info.isRegistered, isFalse);
      expect(info.isPermanent, isNull);
      expect(info.isSingleton, isNull);
    });
  });

  group('reload', () {
    test('reload<T> deletes the dependency, next find rebuilds', () {
      Sint.lazyPut<_Resource>(() => _Resource());
      Sint.find<_Resource>();
      expect(_Resource.built, 1);
      Sint.reload<_Resource>();
      Sint.find<_Resource>();
      expect(_Resource.built, 2);
    });

    test('reloadAll skips permanent unless forced', () {
      Sint.lazyPut<_Resource>(() => _Resource(), tag: 'a');
      Sint.lazyPut<_Resource>(() => _Resource(), tag: 'b');
      // Make 'a' permanent.
      Sint.put<_Counter>(_Counter(), permanent: true);
      Sint.find<_Resource>(tag: 'a');
      Sint.find<_Resource>(tag: 'b');
      _Resource.built = 0;
      Sint.reloadAll();
      Sint.find<_Resource>(tag: 'a');
      Sint.find<_Resource>(tag: 'b');
      // Both will rebuild since they are not permanent.
      expect(_Resource.built, 2);
    });
  });

  group('double-registration', () {
    test('Sint.put twice for same type RETURNS the existing one (no replace)', () {
      // _insert short-circuits when the key exists and is not dirty.
      final first = Sint.put<_Counter>(_Counter());
      first.inc();
      final second = Sint.put<_Counter>(_Counter());
      // Sint sees the existing factory and returns it.
      expect(identical(first, second), isTrue);
      expect(second.n, 1);
    });

    test('replace<T> truly swaps the instance', () {
      final first = _Counter()..inc();
      final second = _Counter();
      Sint.put<_Counter>(first);
      Sint.replace<_Counter>(second);
      expect(identical(Sint.find<_Counter>(), second), isTrue);
      expect(Sint.find<_Counter>().n, 0);
    });
  });
}
