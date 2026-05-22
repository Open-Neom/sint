// Sint Worker tests: ever, once, debounce, interval and auto-cleanup
// when the controller is closed.
import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _TestController extends SintController {
  final count = 0.obs;
  final everEvents = <int>[];
  final onceEvents = <int>[];
  final debounceEvents = <int>[];
  final intervalEvents = <int>[];

  void wireAll({Duration debounceDur = const Duration(milliseconds: 100)}) {
    ever<int>(count, everEvents.add);
    once<int>(count, onceEvents.add);
    debounce<int>(count, debounceEvents.add, duration: debounceDur);
    interval<int>(count, intervalEvents.add,
        duration: const Duration(seconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Sint.reset);

  group('Worker.ever', () {
    test('fires for every change', () async {
      final c = _TestController();
      c.ever<int>(c.count, c.everEvents.add);
      // Drain the priming event from the broadcast stream.
      await Future<void>.delayed(Duration.zero);
      c.everEvents.clear();
      c.count.value = 1;
      c.count.value = 2;
      c.count.value = 3;
      await Future<void>.delayed(Duration.zero);
      expect(c.everEvents, [1, 2, 3]);
    });
  });

  group('Worker.once', () {
    test('fires only on the first change then auto-cancels', () async {
      final c = _TestController();
      c.once<int>(c.count, c.onceEvents.add);
      await Future<void>.delayed(Duration.zero);
      // The first received event might be the prime (initial value 0).
      c.count.value = 10;
      c.count.value = 20;
      c.count.value = 30;
      await Future<void>.delayed(Duration.zero);
      expect(c.onceEvents.length, 1,
          reason: 'once should fire exactly once and then cancel');
    });
  });

  group('Worker.debounce', () {
    test('only the last value within window is delivered', () {
      fakeAsync((async) {
        final c = _TestController();
        c.debounce<int>(
          c.count,
          c.debounceEvents.add,
          duration: const Duration(milliseconds: 200),
        );
        async.flushMicrotasks();
        c.debounceEvents.clear();

        c.count.value = 1;
        async.elapse(const Duration(milliseconds: 50));
        c.count.value = 2;
        async.elapse(const Duration(milliseconds: 50));
        c.count.value = 3;
        async.elapse(const Duration(milliseconds: 250));

        expect(c.debounceEvents, [3]);
      });
    });
  });

  group('Worker.interval', () {
    test('rate-limits emissions to one per duration window', () {
      fakeAsync((async) {
        final c = _TestController();
        c.interval<int>(
          c.count,
          c.intervalEvents.add,
          duration: const Duration(seconds: 1),
        );
        async.flushMicrotasks();
        c.intervalEvents.clear();

        c.count.value = 1; // emitted
        c.count.value = 2; // suppressed
        c.count.value = 3; // suppressed
        async.elapse(const Duration(milliseconds: 100));
        expect(c.intervalEvents, [1]);

        async.elapse(const Duration(seconds: 2));
        c.count.value = 4; // emitted
        async.elapse(const Duration(milliseconds: 100));
        expect(c.intervalEvents.contains(4), isTrue);
      });
    });
  });

  group('Auto-cleanup on controller close', () {
    test('all workers are cancelled and stop receiving events', () async {
      final c = _TestController();
      c.wireAll(debounceDur: const Duration(milliseconds: 50));
      await Future<void>.delayed(Duration.zero);

      // Simulate the lifecycle close (as Sint.delete would do).
      c.onDelete();

      c.everEvents.clear();
      c.count.value = 999;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(c.everEvents, isEmpty,
          reason: 'after onClose, ever should not fire');
    });

    test('integration: Sint.delete triggers worker cleanup', () async {
      Sint.put(_TestController());
      final c = Sint.find<_TestController>();
      c.ever<int>(c.count, c.everEvents.add);
      await Future<void>.delayed(Duration.zero);
      c.everEvents.clear();
      Sint.delete<_TestController>();
      c.count.value = 5;
      await Future<void>.delayed(Duration.zero);
      expect(c.everEvents, isEmpty);
    });
  });
}
