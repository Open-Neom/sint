import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _Counter extends SintController {}

void main() {
  tearDown(Sint.reset);

  test('disposed controllers cannot allocate new listener groups', () {
    final controller = _Counter();
    controller.dispose();
    expect(() => controller.addListenerId('late', () {}), throwsStateError);
  });

  testWidgets('SintBuilder rebuilds only the requested ID', (tester) async {
    final controller = Sint.put(_Counter());
    var leftBuilds = 0;
    var rightBuilds = 0;
    await tester.pumpWidget(Column(children: [
      SintBuilder<_Counter>(
          id: 'left',
          autoRemove: false,
          builder: (_) {
            leftBuilds++;
            return const SizedBox();
          }),
      SintBuilder<_Counter>(
          id: 'right',
          autoRemove: false,
          builder: (_) {
            rightBuilds++;
            return const SizedBox();
          }),
    ]));
    expect([leftBuilds, rightBuilds], [1, 1]);
    controller.update(['left']);
    await tester.pump();
    expect([leftBuilds, rightBuilds], [2, 1]);
    controller.update(['right'], false);
    controller.update(['missing']);
    await tester.pump();
    expect([leftBuilds, rightBuilds], [2, 1]);
    controller.update(['right']);
    await tester.pump();
    expect([leftBuilds, rightBuilds], [2, 2]);
    await tester.pumpWidget(const SizedBox());
    controller.update(['left', 'right']);
    await tester.pump();
    expect([leftBuilds, rightBuilds], [2, 2]);
  });

  testWidgets('Obx detaches inactive branches and cleans up on unmount',
      (tester) async {
    final selectLeft = true.obs;
    final left = 1.obs;
    final right = 10.obs;
    var builds = 0;
    var rendered = 0;
    await tester.pumpWidget(Obx(() {
      builds++;
      rendered = selectLeft.value ? left.value : right.value;
      return const SizedBox();
    }));
    expect([builds, rendered], [1, 1]);
    expect([
      selectLeft.listenersLength,
      left.listenersLength,
      right.listenersLength
    ], [
      1,
      1,
      0
    ]);
    selectLeft.value = false;
    await tester.pump();
    expect([builds, rendered], [2, 10]);
    expect([left.listenersLength, right.listenersLength], [0, 1]);
    left.value++;
    await tester.pump();
    expect(builds, 2);
    right.value++;
    await tester.pump();
    expect([builds, rendered], [3, 11]);
    await tester.pumpWidget(const SizedBox());
    expect([
      selectLeft.listenersLength,
      left.listenersLength,
      right.listenersLength
    ], [
      0,
      0,
      0
    ]);
    selectLeft.close();
    left.close();
    right.close();
  });

  testWidgets('Obx batches a burst into one frame and deduplicates reads',
      (tester) async {
    final value = 0.obs;
    var builds = 0;
    var rendered = 0;
    await tester.pumpWidget(Obx(() {
      builds++;
      rendered = value.value + value.value;
      return const SizedBox();
    }));
    expect(value.listenersLength, 1);
    for (var i = 1; i <= 100; i++) {
      value.value = i;
    }
    expect(builds, 1);
    await tester.pump();
    expect([builds, rendered, value.listenersLength], [2, 200, 1]);
    value.value = 100;
    await tester.pump();
    expect(builds, 2);
    await tester.pumpWidget(const SizedBox());
    expect(value.listenersLength, 0);
    value.close();
  });

  test('closing an Rx cancels every upstream binding outside Obx', () async {
    final first = StreamController<int>();
    final second = StreamController<int>();
    final value = 0.obs;
    value.bindStream(first.stream);
    value.bindStream(second.stream);
    first.add(7);
    await Future<void>.delayed(Duration.zero);
    expect(value.value, 7);
    expect(first.hasListener && second.hasListener, isTrue);
    value.close();
    value.close();
    expect(first.hasListener || second.hasListener, isFalse);
    expect(() => value.bindStream(const Stream<int>.empty()), throwsStateError);
    await first.close();
    await second.close();
  });

  test('upstream onCancel cannot revive an Rx being disposed', () async {
    final value = 0.obs;
    final second = StreamController<int>();
    var cancelled = false;
    final first = StreamController<int>(onCancel: () {
      cancelled = true;
      expect(value.isDisposed, isTrue);
      expect(() => value.bindStream(second.stream), throwsStateError);
    });
    value.bindStream(first.stream);
    value.close();
    expect(cancelled, isTrue);
    expect(second.hasListener, isFalse);
    await first.close();
    unawaited(second.close());
  });

  testWidgets('Obx releases bindings without closing a reusable Rx',
      (tester) async {
    final upstream = StreamController<int>();
    final value = 0.obs;
    await tester.pumpWidget(Obx(() {
      value.bindStream(upstream.stream);
      return const SizedBox();
    }));
    expect(upstream.hasListener, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(upstream.hasListener, isFalse);
    expect(value.isDisposed, isFalse);
    value.close();
    unawaited(upstream.close());
    await tester.pump();
    expect(upstream.isClosed, isTrue);
  });
}
