import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _Foo {}

class _FooBar {}

class _Tracked extends SintController {
  _Tracked({this.close, this.initialize});
  final void Function()? close;
  final void Function()? initialize;
  int initCount = 0;
  int closeCount = 0;
  @override
  void onInit() {
    initCount++;
    initialize?.call();
    super.onInit();
  }

  @override
  void onClose() {
    closeCount++;
    close?.call();
    super.onClose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Sint.reset();
    RouterReportManager.dispose();
    Sint.smartManagement = SmartManagement.full;
    Sint.isLogEnable = false;
  });
  tearDown(() {
    Sint.reset();
    RouterReportManager.dispose();
  });

  group('typed identity and legacy key compatibility', () {
    test(
        'colliding type/tag strings cannot register, find, or delete each other',
        () {
      final tagged = Sint.put<_Foo>(_Foo(), tag: 'Bar');
      expect(Sint.isRegistered<_FooBar>(), isFalse);
      expect(Sint.findOrNull<_FooBar>(), isNull);
      expect(Sint.delete<_FooBar>(), isFalse);
      final untagged = Sint.put<_FooBar>(_FooBar());
      expect(Sint.find<_Foo>(tag: 'Bar'), same(tagged));
      expect(Sint.find<_FooBar>(), same(untagged));
      expect(Sint.delete<_Foo>(tag: 'Bar'), isTrue);
      expect(Sint.find<_FooBar>(), same(untagged));
    });

    test('null and empty tags are independent through reload and delete', () {
      Sint.lazyPut<_Tracked>(() => _Tracked());
      Sint.lazyPut<_Tracked>(() => _Tracked(), tag: '');
      final untagged = Sint.find<_Tracked>();
      final emptyTag = Sint.find<_Tracked>(tag: '');
      expect(identical(untagged, emptyTag), isFalse);
      Sint.reload<_Tracked>(tag: '');
      expect(emptyTag.closeCount, 1);
      expect(untagged.closeCount, 0);
      expect(Sint.delete<_Tracked>(tag: ''), isTrue);
      expect(Sint.find<_Tracked>(), same(untagged));
    });

    test('ambiguous legacy mutations fail before changing either registration',
        () {
      final first = Sint.put<_Foo>(_Foo(), tag: 'Bar');
      final second = Sint.put<_FooBar>(_FooBar());
      expect(() => Sint.delete(key: '_FooBar'), throwsStateError);
      expect(() => Sint.reload(key: '_FooBar'), throwsStateError);
      expect(() => Sint.markAsDirty(key: '_FooBar'), throwsStateError);
      expect(Sint.find<_Foo>(tag: 'Bar'), same(first));
      expect(Sint.find<_FooBar>(), same(second));
      // A failed dirty operation must not permit replacement either.
      expect(Sint.put<_Foo>(_Foo(), tag: 'Bar'), same(first));
      final keys = InjectionExtension.registeredKeys.toList();
      expect(keys.toSet().length, 2);
      expect(keys.map(InjectionExtension.registeredTypeForKey).toSet(),
          {_Foo, _FooBar});
      for (final key in keys) {
        expect(Sint.delete(key: key), isTrue);
      }
      expect(InjectionExtension.registeredKeys, isEmpty);
    });

    test('unambiguous historical keys remain supported', () {
      Sint.put<_Foo>(_Foo(), tag: 'x');
      expect(InjectionExtension.registeredKeys, ['_Foox']);
      expect(InjectionExtension.registeredTypeForKey('_Foox'), _Foo);
      expect(Sint.delete(key: '_Foox'), isTrue);
    });

    test('legacy route linking captures its generation before replacement', () {
      final router = RouterReportManager.instance;
      final route = Object();
      final original = Sint.put<_Tracked>(_Tracked());
      router.reportCurrentRoute(route);
      router.reportDependencyLinkedToRoute('_Tracked');
      Sint.delete<_Tracked>();
      router.reportCurrentRoute(Object());
      final current = Sint.put<_Tracked>(_Tracked());
      router.reportRouteDispose(route);
      expect(original.closeCount, 1);
      expect(current.closeCount, 0);
      expect(Sint.find<_Tracked>(), same(current));
    });

    test('generic type and key disagreement cannot delete another type', () {
      final second = Sint.put<_FooBar>(_FooBar());
      expect(() => Sint.delete<_Foo>(key: '_FooBar'), throwsArgumentError);
      expect(Sint.find<_FooBar>(), same(second));
    });
  });

  group('route generation ownership', () {
    test('three overlapping replacements close only their own generation', () {
      final router = RouterReportManager.instance;
      final routes = List.generate(3, (_) => Object());
      final instances = <_Tracked>[];
      for (final route in routes) {
        router.reportCurrentRoute(route);
        instances.add(Sint.put<_Tracked>(_Tracked()));
        router.reportRouteWillDispose(route);
      }
      router.reportRouteDispose(routes[1]);
      expect(instances.map((c) => c.closeCount), [0, 1, 0]);
      router.reportRouteDispose(routes[0]);
      expect(instances.map((c) => c.closeCount), [1, 1, 0]);
      expect(Sint.find<_Tracked>(), same(instances[2]));
      router.reportRouteDispose(routes[2]);
      expect(instances.map((c) => c.closeCount), [1, 1, 1]);
      expect(Sint.isRegistered<_Tracked>(), isFalse);
    });

    test('old route cannot close an explicitly replaced registration', () {
      final router = RouterReportManager.instance;
      final oldRoute = Object();
      final newRoute = Object();
      router.reportCurrentRoute(oldRoute);
      final old = Sint.put<_Tracked>(_Tracked());
      Sint.delete<_Tracked>();
      router.reportCurrentRoute(newRoute);
      final current = Sint.put<_Tracked>(_Tracked());
      router.reportRouteWillDispose(oldRoute);
      router.reportRouteDispose(oldRoute);
      expect(old.closeCount, 1);
      expect(current.closeCount, 0);
      expect(Sint.find<_Tracked>(), same(current));
      router.reportRouteDispose(newRoute);
      expect(current.closeCount, 1);
    });

    test('fenix revival survives stale route marking and disposal', () {
      final router = RouterReportManager.instance;
      final oldRoute = Object();
      final newRoute = Object();
      router.reportCurrentRoute(oldRoute);
      Sint.lazyPut<_Tracked>(() => _Tracked(), fenix: true);
      final old = Sint.find<_Tracked>();
      Sint.delete<_Tracked>();
      router.reportCurrentRoute(newRoute);
      final current = Sint.find<_Tracked>();
      router.reportRouteWillDispose(oldRoute);
      expect(Sint.put<_Tracked>(_Tracked()), same(current));
      router.reportRouteDispose(oldRoute);
      expect(old.closeCount, 1);
      expect(current.closeCount, 0);
      router.reportRouteDispose(newRoute);
      expect(current.closeCount, 1);
      expect(Sint.isPrepared<_Tracked>(), isTrue);
    });

    test('old route disposal cannot erase reentrant registration in onClose',
        () {
      final router = RouterReportManager.instance;
      final oldRoute = Object();
      final newRoute = Object();
      late _Tracked current;
      router.reportCurrentRoute(oldRoute);
      final old = Sint.put<_Tracked>(_Tracked(close: () {
        router.reportCurrentRoute(newRoute);
        current = Sint.put<_Tracked>(_Tracked());
      }));
      router.reportRouteDispose(oldRoute);
      expect(old.closeCount, 1);
      expect(Sint.find<_Tracked>(), same(current));
      expect(current.closeCount, 0);
      router.reportRouteDispose(newRoute);
      expect(current.closeCount, 1);
    });

    test('fenix onClose can revive without returning the closing instance', () {
      final router = RouterReportManager.instance;
      final oldRoute = Object();
      final newRoute = Object();
      final built = <_Tracked>[];
      _Tracked? revived;
      router.reportCurrentRoute(oldRoute);
      Sint.lazyPut<_Tracked>(() {
        final first = built.isEmpty;
        final controller = _Tracked(
            close: first
                ? () {
                    router.reportCurrentRoute(newRoute);
                    revived = Sint.find<_Tracked>();
                  }
                : null);
        built.add(controller);
        return controller;
      }, fenix: true);
      final old = Sint.find<_Tracked>();
      router.reportRouteDispose(oldRoute);
      expect(built.length, 2);
      expect(old.closeCount, 1);
      expect(revived, same(built[1]));
      expect(Sint.find<_Tracked>(), same(revived));
      expect(revived!.closeCount, 0);
      router.reportRouteDispose(newRoute);
      expect(revived!.closeCount, 1);
    });

    test('putOrFind starts a lazy controller and links its route', () {
      final router = RouterReportManager.instance;
      final route = Object();
      router.reportCurrentRoute(route);
      Sint.lazyPut<_Tracked>(() => _Tracked());
      final controller = Sint.putOrFind<_Tracked>(() => _Tracked());
      expect(controller.initCount, 1);
      router.reportRouteDispose(route);
      expect(controller.closeCount, 1);
      expect(Sint.isRegistered<_Tracked>(), isFalse);
    });

    test('route disposal handles colliding legacy strings independently', () {
      final router = RouterReportManager.instance;
      final firstRoute = Object();
      final secondRoute = Object();
      router.reportCurrentRoute(firstRoute);
      Sint.put<_Foo>(_Foo(), tag: 'Bar');
      router.reportCurrentRoute(secondRoute);
      final retained = Sint.put<_FooBar>(_FooBar());
      router.reportRouteDispose(firstRoute);
      expect(Sint.isRegistered<_Foo>(tag: 'Bar'), isFalse);
      expect(Sint.find<_FooBar>(), same(retained));
      router.reportRouteDispose(secondRoute);
      expect(InjectionExtension.registeredKeys, isEmpty);
    });

    test('reloadAll closes old resources without leaving stale route ownership',
        () {
      final router = RouterReportManager.instance;
      final oldRoute = Object();
      final newRoute = Object();
      router.reportCurrentRoute(oldRoute);
      Sint.lazyPut<_Tracked>(() => _Tracked());
      final old = Sint.find<_Tracked>();
      Sint.reloadAll();
      expect(old.closeCount, 1);
      router.reportCurrentRoute(newRoute);
      final current = Sint.find<_Tracked>();
      router.reportRouteDispose(oldRoute);
      expect(current.closeCount, 0);
      router.reportRouteDispose(newRoute);
      expect(current.closeCount, 1);
    });
  });

  test('failed lazy construction can retry initialization and route linking',
      () {
    final router = RouterReportManager.instance;
    final route = Object();
    router.reportCurrentRoute(route);
    var attempts = 0;
    Sint.lazyPut<_Tracked>(() {
      if (attempts++ == 0) throw StateError('temporary failure');
      return _Tracked();
    });
    expect(() => Sint.find<_Tracked>(), throwsStateError);
    expect(Sint.isPrepared<_Tracked>(), isTrue);
    final controller = Sint.find<_Tracked>();
    expect(controller.initCount, 1);
    router.reportRouteDispose(route);
    expect(controller.closeCount, 1);
  });

  test('a throwing onClose does not abandon the other route dependencies', () {
    final router = RouterReportManager.instance;
    final route = Object();
    router.reportCurrentRoute(route);
    final failure = StateError('close failed');
    final throwing = Sint.put<_Tracked>(_Tracked(close: () => throw failure),
        tag: 'throwing');
    final other = Sint.put<_Tracked>(_Tracked(), tag: 'other');
    expect(() => router.reportRouteDispose(route), throwsA(same(failure)));
    expect(throwing.closeCount, 1);
    expect(other.closeCount, 1);
    expect(InjectionExtension.registeredKeys, isEmpty);
    router.reportRouteDispose(route);
    expect(other.closeCount, 1);
  });

  test('onInit failure can retry lifecycle and route ownership', () {
    final router = RouterReportManager.instance;
    final route = Object();
    router.reportCurrentRoute(route);
    var attempts = 0;
    Sint.lazyPut<_Tracked>(() => _Tracked(initialize: () {
          if (attempts++ == 0) throw StateError('initialization failed');
        }));
    expect(() => Sint.find<_Tracked>(), throwsStateError);
    expect(Sint.isPrepared<_Tracked>(), isTrue);
    final controller = Sint.find<_Tracked>();
    expect(controller.initialized, isTrue);
    expect(controller.initCount, 2);
    router.reportRouteDispose(route);
    expect(controller.closeCount, 1);
  });

  test('spawn cleanup can reenter route reporting without concurrent mutation',
      () {
    final router = RouterReportManager.instance;
    final firstRoute = Object();
    final secondRoute = Object();
    var closing = false;
    _Tracked? spawnedDuringClose;
    router.reportCurrentRoute(firstRoute);
    Sint.spawn<_Tracked>(() => _Tracked(close: () {
          if (closing) return;
          closing = true;
          router.reportCurrentRoute(secondRoute);
          spawnedDuringClose = Sint.find<_Tracked>();
        }));
    final first = Sint.find<_Tracked>();
    router.reportRouteWillDispose(firstRoute);
    router.reportRouteDispose(firstRoute);
    expect(first.closeCount, 1);
    expect(spawnedDuringClose!.closeCount, 0);
    router.reportRouteDispose(secondRoute);
    expect(spawnedDuringClose!.closeCount, 1);
  });

  test('replace and lazyReplace override a fenix factory', () {
    Sint.lazyPut<_Tracked>(() => _Tracked(), fenix: true);
    final old = Sint.find<_Tracked>();
    final replacement = _Tracked();
    Sint.replace<_Tracked>(replacement);
    expect(old.closeCount, 1);
    expect(Sint.find<_Tracked>(), same(replacement));
    Sint.delete<_Tracked>();
    Sint.lazyPut<_Tracked>(() => _Tracked(), fenix: true);
    final second = Sint.find<_Tracked>();
    var built = 0;
    Sint.lazyReplace<_Tracked>(() {
      built++;
      return _Tracked();
    });
    expect(second.closeCount, 1);
    expect(built, 0);
    expect(Sint.find<_Tracked>(), isNot(same(second)));
    expect(built, 1);
  });
}
