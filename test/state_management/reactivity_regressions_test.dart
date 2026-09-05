import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class AuditController extends SintController {}

Future<void> flushEvents() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('self-removing listener must not skip the next subscriber', () {
    final rx = 0.obs;
    final calls = <String>[];
    late VoidCallback removeFirst;
    removeFirst = rx.addListener(() {
      calls.add('first');
      removeFirst();
    });
    rx.addListener(() => calls.add('second'));
    rx.value = 1;
    expect(calls, ['first', 'second']);
  });

  test('removing all listeners during notification must not throw', () {
    final rx = 0.obs;
    late VoidCallback removeFirst;
    late VoidCallback removeSecond;
    removeFirst = rx.addListener(() {
      removeFirst();
      removeSecond();
    });
    removeSecond = rx.addListener(() {});
    expect(() => rx.value = 1, returnsNormally);
  });

  test('new stream subscriber receives updates after last subscriber cancels',
      () async {
    final rx = 0.obs;
    final original = <int>[];
    final first = rx.listen(original.add);
    rx.value = 1;
    await flushEvents();
    expect(original, [1]);
    await first.cancel();

    final subsequent = <int>[];
    final second = rx.listen(subsequent.add);
    rx.value = 2;
    await flushEvents();
    await second.cancel();
    expect(subsequent, [2]);
  });

  test(
      'closing Rx with an active stream listener completes without async errors',
      () async {
    final rx = 0.obs;
    final finished = Completer<void>();
    rx.listen((_) {}, onDone: finished.complete);
    rx.close();
    await finished.future;
    await flushEvents();
  });

  test('ever worker can subscribe after once worker auto-cancels', () async {
    final rx = 0.obs;
    final controller = AuditController();
    final firstEvents = <int>[];
    controller.once(rx, firstEvents.add);
    rx.value = 1;
    await flushEvents();
    expect(firstEvents, [1]);

    final nextEvents = <int>[];
    controller.ever(rx, nextEvents.add);
    rx.value = 2;
    await flushEvents();
    controller.onDelete();
    expect(nextEvents, [2]);
  });

  testWidgets('SintListener callback replacement retains Rx event delivery',
      (tester) async {
    final rx = 0.obs;
    final previous = <int>[];
    final updated = <int>[];
    await tester.pumpWidget(SintListener<int>(
      rx: rx,
      listener: previous.add,
      child: const SizedBox(),
    ));
    rx.value = 1;
    await tester.pump();
    expect(previous, [1]);

    await tester.pumpWidget(SintListener<int>(
      rx: rx,
      listener: updated.add,
      child: const SizedBox(),
    ));
    rx.value = 2;
    await tester.pump();
    expect(updated, [2]);
  });

  testWidgets(
      'SintListener must replace different Rx sources with equal values',
      (tester) async {
    final oldRx = 0.obs;
    final newRx = 0.obs;
    final events = <int>[];
    void callback(int value) => events.add(value);
    await tester.pumpWidget(SintListener<int>(
      rx: oldRx,
      listener: callback,
      child: const SizedBox(),
    ));
    await tester.pumpWidget(SintListener<int>(
      rx: newRx,
      listener: callback,
      child: const SizedBox(),
    ));
    newRx.value = 7;
    await tester.pump();
    expect(events, [7]);
  });

  test('RxList assignAll snapshots lazy iterables before clearing backing data',
      () {
    final values = <int>[1, 2, 3, 4].obs;
    values.assignAll(values.where((value) => value.isEven));
    expect(values.toList(), [2, 4]);
  });

  test(
      'standard List assignAll preserves values when source aliases destination',
      () {
    final values = <int>[1, 2, 3];
    values.assignAll(values);
    expect(values, [1, 2, 3]);
  });

  test('RxMap assignAll emits only one notification per logical assignment',
      () {
    final values = <String, int>{'a': 1}.obs;
    var calls = 0;
    values.addListener(() => calls++);
    values.assignAll({'b': 2});
    expect(values.value, {'b': 2});
    expect(calls, 1);
  });

  test('removing a pending listener skips it without skipping its successor',
      () {
    final rx = 0.obs;
    final calls = <String>[];
    late VoidCallback removeSecond;
    rx.addListener(() {
      calls.add('first');
      removeSecond();
    });
    removeSecond = rx.addListener(() => calls.add('removed'));
    rx.addListener(() => calls.add('last'));
    rx.value = 1;
    expect(calls, ['first', 'last']);
    expect(rx.listenersLength, 2);
  });

  test('listeners added during a notification wait for the next notification',
      () {
    final rx = 0.obs;
    final calls = <String>[];
    var added = false;
    rx.addListener(() {
      calls.add('first');
      if (!added) {
        added = true;
        rx.addListener(() => calls.add('new'));
      }
    });
    rx.addListener(() => calls.add('second'));
    rx.value = 1;
    expect(calls, ['first', 'second']);
    calls.clear();
    rx.value = 2;
    expect(calls, ['first', 'second', 'new']);
  });

  test('nested notifications keep pending listeners and compact after dispatch',
      () {
    final rx = 0.obs;
    final calls = <String>[];
    late VoidCallback remove;
    remove = rx.addListener(() {
      calls.add('first:${rx.value}');
      remove();
      rx.value = 2;
    });
    rx.addListener(() => calls.add('second:${rx.value}'));
    rx.value = 1;
    expect(calls, ['first:1', 'second:2', 'second:2']);
    expect(rx.listenersLength, 1);
  });

  test('throwing callbacks still restore notification bookkeeping', () {
    final rx = 0.obs;
    late VoidCallback remove;
    remove = rx.addListener(() {
      remove();
      throw StateError('callback failed');
    });
    var calls = 0;
    rx.addListener(() => calls++);
    expect(() => rx.value = 1, throwsStateError);
    rx.value = 2;
    expect(calls, 1);
    expect(rx.listenersLength, 1);
  });

  test('old disposers cannot remove a newly registered identical callback', () {
    final rx = 0.obs;
    var calls = 0;
    void callback() => calls++;
    final oldDisposer = rx.addListener(callback);
    rx.removeListener(callback);
    final newDisposer = rx.addListener(callback);
    oldDisposer();
    oldDisposer();
    rx.value = 1;
    expect(calls, 1);
    newDisposer();
    rx.close();
    oldDisposer();
    newDisposer();
    rx.close();
    expect(rx.listenersLength, 0);
    expect(() => rx.addListener(callback), throwsStateError);
  });

  test('duplicate callback registrations have independent disposers', () {
    final rx = 0.obs;
    var calls = 0;
    void callback() => calls++;
    final removeFirst = rx.addListener(callback);
    final removeSecond = rx.addListener(callback);
    removeSecond();
    rx.value = 1;
    expect(calls, 1);
    removeFirst();
    expect(rx.listenersLength, 0);
  });

  test('closing during dispatch skips pending listeners safely', () async {
    final rx = 0.obs;
    var calls = 0;
    rx.addListener(rx.close);
    rx.addListener(() => calls++);
    final done = Completer<void>();
    rx.listen((_) => calls++, onDone: done.complete);
    rx.value = 1;
    await done.future;
    expect(calls, 0);
    expect(rx.listenersLength, 0);
  });

  test(
      'multiple subscriptions share one bridge and reconnect without duplicates',
      () async {
    final rx = 0.obs;
    final firstEvents = <int>[];
    final secondEvents = <int>[];
    final first = rx.listen(firstEvents.add);
    final second = rx.listen(secondEvents.add);
    expect(rx.listenersLength, 1);
    await first.cancel();
    rx.value = 1;
    await flushEvents();
    expect(firstEvents, isEmpty);
    expect(secondEvents, [1]);
    await second.cancel();
    expect(rx.listenersLength, 0);
    final thirdEvents = <int>[];
    final third = rx.listen(thirdEvents.add);
    rx.value = 2;
    await flushEvents();
    expect(thirdEvents, [2]);
    await third.cancel();
    rx.close();
  });

  test('assignAll preserves contents if its iterable throws while being read',
      () {
    final rx = <int>[1, 2].obs;
    Iterable<int> failedSource() sync* {
      yield 3;
      throw StateError('source failed');
    }

    var calls = 0;
    rx.addListener(() => calls++);
    expect(() => rx.assignAll(failedSource()), throwsStateError);
    expect(rx.toList(), [1, 2]);
    expect(calls, 0);
  });

  test('assignAll consumes list views and deduplicates equal lazy iterables',
      () {
    final rx = <int>[1, 2, 3].obs;
    var calls = 0;
    rx.addListener(() => calls++);
    rx.assignAll(rx.map((value) => value));
    expect(calls, 0);
    rx.assignAll(rx.reversed);
    expect(rx.toList(), [3, 2, 1]);
    expect(calls, 1);
  });
}
