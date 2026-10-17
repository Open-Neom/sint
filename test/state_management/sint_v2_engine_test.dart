import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

void main() {
  tearDown(Sint.reset);

  group('SINT 2.0 — Incremental Obx Subscription Reconciliation', () {
    testWidgets(
      'Obx dynamically unsubscribes from inactive conditional branches and retains active ones',
      (tester) async {
        final useBranchA = true.obs;
        final branchA = 'Alpha'.obs;
        final branchB = 'Beta'.obs;
        var buildCount = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Obx(() {
              buildCount++;
              return Text(useBranchA.value ? branchA.value : branchB.value);
            }),
          ),
        );

        expect(find.text('Alpha'), findsOneWidget);
        expect(buildCount, 1);
        expect(useBranchA.listenersLength, 1);
        expect(branchA.listenersLength, 1);
        expect(branchB.listenersLength, 0);

        // Steady-state update on branchA keeps exact subscription counts.
        branchA.value = 'Alpha 2';
        await tester.pump();
        expect(find.text('Alpha 2'), findsOneWidget);
        expect(buildCount, 2);
        expect(useBranchA.listenersLength, 1);
        expect(branchA.listenersLength, 1);
        expect(branchB.listenersLength, 0);

        // Switching to branchB unsubscribes branchA and subscribes branchB.
        useBranchA.value = false;
        await tester.pump();
        expect(find.text('Beta'), findsOneWidget);
        expect(buildCount, 3);
        expect(useBranchA.listenersLength, 1);
        expect(branchA.listenersLength, 0);
        expect(branchB.listenersLength, 1);

        // Updating inactive branchA must NOT trigger a rebuild.
        branchA.value = 'Alpha 3';
        await tester.pump();
        expect(buildCount, 3);

        // Updating active branchB triggers a rebuild.
        branchB.value = 'Beta 2';
        await tester.pump();
        expect(find.text('Beta 2'), findsOneWidget);
        expect(buildCount, 4);
      },
    );
  });

  group('SINT 2.0 — Synchronous Batching (Sint.batch)', () {
    test('coalesces multiple updates on the same Rx and across nested batches', () {
      final counter = 0.obs;
      final observed = <int>[];
      counter.addListener(() => observed.add(counter.value));

      final result = Sint.batch(() {
        counter.value = 1;
        counter.value = 2;
        Sint.batch(() {
          counter.value = 3;
          counter.value = 4;
        });
        expect(observed, isEmpty);
        counter.value = 5;
        return 'done';
      });

      expect(result, 'done');
      expect(observed, [5]);
    });
  });

  group('SINT 2.0 — Memoized Derived State (Sint.computed / Computed<T>)', () {
    test('memoizes derived values and suppresses notifications when output is equal', () {
      final count = 2.obs;
      var computeRuns = 0;
      var notifications = 0;

      final isEven = Sint.computed<bool>(() {
        computeRuns++;
        return count.value.isEven;
      });
      isEven.addListener(() => notifications++);

      expect(isEven.value, isTrue);
      expect(computeRuns, 1);
      expect(notifications, 0);

      // 2 -> 4: still even, so downstream listeners are NOT notified.
      count.value = 4;
      expect(isEven.value, isTrue);
      expect(computeRuns, 2);
      expect(notifications, 0);

      // 4 -> 5: changes to odd, so downstream listeners ARE notified once.
      count.value = 5;
      expect(isEven.value, isFalse);
      expect(computeRuns, 3);
      expect(notifications, 1);

      isEven.close();
      expect(count.listenersLength, 0);
    });

    test('coalesces diamond dependencies inside Sint.batch into a single evaluation', () {
      final firstName = 'Ada'.obs;
      final lastName = 'Lovelace'.obs;
      var computeRuns = 0;
      final observed = <String>[];

      final fullName = Sint.computed<String>(() {
        computeRuns++;
        return '${firstName.value} ${lastName.value}';
      });
      final greeting = Sint.computed<String>(() => 'Hello, ${fullName.value}!');
      greeting.addListener(() => observed.add(greeting.value));

      expect(fullName.value, 'Ada Lovelace');
      expect(greeting.value, 'Hello, Ada Lovelace!');
      expect(computeRuns, 1);

      Sint.batch(() {
        firstName.value = 'Grace';
        lastName.value = 'Hopper';
      });

      expect(computeRuns, 2);
      expect(fullName.value, 'Grace Hopper');
      expect(greeting.value, 'Hello, Grace Hopper!');
      expect(observed, ['Hello, Grace Hopper!']);

      greeting.close();
      fullName.close();
    });

    testWidgets('Computed integrates seamlessly with Obx', (tester) async {
      final price = 10.obs;
      final quantity = 2.obs;
      final total = Sint.computed(() => price.value * quantity.value);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(() => Text('Total: ${total.value}')),
        ),
      );

      expect(find.text('Total: 20'), findsOneWidget);

      Sint.batch(() {
        price.value = 15;
        quantity.value = 3;
      });
      await tester.pump();

      expect(find.text('Total: 45'), findsOneWidget);
      total.close();
    });
  });

  group('SINT 2.0 — Collection Semantics Unification (RxMap & RxSet)', () {
    test('RxMap.addAll fires at most one notification', () {
      final map = <String, int>{'a': 1}.obs;
      var notifications = 0;
      map.addListener(() => notifications++);

      map.addAll({'b': 2, 'c': 3, 'd': 4});
      expect(notifications, 1);
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});

      // Adding identical entries fires 0 notifications.
      map.addAll({'b': 2, 'c': 3});
      expect(notifications, 1);
    });

    test('Set.obs wraps set by reference and RxSet.addAll / assignAll coalesce notifications', () {
      final raw = <String>{'x', 'y'};
      final rxSet = raw.obs;
      expect(identical(rxSet.value, raw), isTrue);

      var notifications = 0;
      rxSet.addListener(() => notifications++);

      // Adding already-present elements does not notify.
      rxSet.addAll(['x', 'y']);
      expect(notifications, 0);

      // Adding new elements notifies once.
      rxSet.addAll(['y', 'z']);
      expect(notifications, 1);
      expect(rxSet, {'x', 'y', 'z'});

      // Self-assignAll and identical content assignAll do not clear or notify.
      rxSet.assignAll(rxSet);
      rxSet.assignAll(['z', 'y', 'x']);
      expect(notifications, 1);
      expect(rxSet, {'x', 'y', 'z'});

      // Replacing with new items notifies once.
      rxSet.assignAll(['a', 'b']);
      expect(notifications, 2);
      expect(rxSet, {'a', 'b'});

      // assign(single) notifies once only when changed.
      rxSet.assign('only');
      expect(notifications, 3);
      expect(rxSet, {'only'});
      rxSet.assign('only');
      expect(notifications, 3);
    });
  });

  group('SINT 2.0 — Multi-Level Prefix Route Indexing & PathDecoded Reuse', () {
    test('SintPage.copyWith reuses compiled PathDecoded when name is unchanged', () {
      final page = SintPage(name: '/users/:id', page: () => const SizedBox());
      final copy = page.copyWith(title: 'User Profile');
      expect(identical(page.path, copy.path), isTrue);

      final renamed = page.copyWith(name: '/accounts/:id');
      expect(identical(page.path, renamed.path), isFalse);
    });

    test('RouteParser multi-level literal trie preserves precedence and registration order', () {
      final parser = RouteParser(
        routes: [
          SintPage(name: '/', page: () => const SizedBox()),
          SintPage(name: '/api', page: () => const SizedBox()),
          SintPage(name: '/api/v1', page: () => const SizedBox()),
          SintPage(name: '/api/:version/items', page: () => const SizedBox()),
          SintPage(name: '/api/v1/items', page: () => const SizedBox()),
          SintPage(name: '/api/v2/users', page: () => const SizedBox()),
        ],
      );

      // '/api/:version/items' was registered BEFORE '/api/v1/items', so
      // within rank 0 ('api'), first-registered wins.
      final itemsMatch = parser.matchRoute('/api/v1/items');
      expect(itemsMatch.route?. parameters?['version'], 'v1');

      // Deep literal route '/api/v2/users' resolves via multi-level trie.
      final usersMatch = parser.matchRoute('/api/v2/users');
      expect(usersMatch.route?.name, '/api/v2/users');
    });
  });

  group('SINT 2.0 — Sint.untrack, rx.peek & Scoped SintController Lifecycle', () {
    test('Sint.untrack and rx.peek read values without subscribing Computed or Obx', () {
      final tracked = 2.obs;
      final untracked = 10.obs;
      final peeked = 100.obs;
      var evaluations = 0;

      final derived = Sint.computed(() {
        evaluations++;
        final u = Sint.untrack(() => untracked.value);
        return tracked.value + u + peeked.peek;
      });

      expect(derived.value, 112);
      expect(evaluations, 1);

      // Mutating untracked or peeked sources does NOT recompute `derived`.
      untracked.value = 20;
      peeked.value = 200;
      expect(evaluations, 1);
      expect(derived.value, 112);

      // Mutating tracked source recomputes using the latest untracked/peeked values.
      tracked.value = 5;
      expect(evaluations, 2);
      expect(derived.value, 225);

      derived.dispose();
    });

    test('SintController.computed, everSync, and autoDispose clean up on onClose', () {
      final globalCounter = 1.obs;
      final controller = _TestScopedController(globalCounter);
      controller.onStart();

      expect(controller.localRx.value, 0);
      expect(controller.doubled.value, 2);
      expect(controller.syncEvents, isEmpty);

      Sint.batch(() {
        globalCounter.value = 3;
        globalCounter.value = 5;
      });

      // Coalesced batch fires everSync once with 5, and updates scoped computed.
      expect(controller.syncEvents, [5]);
      expect(controller.doubled.value, 10);

      // Closing the controller disposes scoped computed, everSync, and autoDisposed Rx.
      controller.onDelete();
      expect(controller.doubled.isDisposed, isTrue);
      expect(controller.localRx.isDisposed, isTrue);
      expect(globalCounter.listenersLength, 0);

      globalCounter.value = 9;
      expect(controller.syncEvents, [5]);
    });
  });
}

class _TestScopedController extends SintController {
  _TestScopedController(this.externalRx);

  final RxInt externalRx;
  late final localRx = autoDispose(0.obs);
  late final doubled = computed(() => externalRx.value * 2);
  final syncEvents = <int>[];

  @override
  void onInit() {
    super.onInit();
    everSync(externalRx, syncEvents.add);
  }
}
