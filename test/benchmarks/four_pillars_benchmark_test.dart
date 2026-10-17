@Tags(['benchmark'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

import 'bench_harness.dart';

class _CoarseCartModel extends ChangeNotifier {
  int _items = 1;
  int _price = 10;
  int _tax = 2;
  int _discount = 1;

  int get items => _items;
  set items(int v) {
    if (_items != v) {
      _items = v;
      notifyListeners();
    }
  }

  int get price => _price;
  set price(int v) {
    if (_price != v) {
      _price = v;
      notifyListeners();
    }
  }

  int get tax => _tax;
  set tax(int v) {
    if (_tax != v) {
      _tax = v;
      notifyListeners();
    }
  }

  int get discount => _discount;
  set discount(int v) {
    if (_discount != v) {
      _discount = v;
      notifyListeners();
    }
  }

  int get total => (_items * _price) + _tax - _discount;
}

class _FourPillarController extends SintController {
  _FourPillarController(this.sharedMultiplier);

  final RxInt sharedMultiplier;
  final items = 1.obs;
  final price = 10.obs;
  final tax = 2.obs;
  final discount = 1.obs;

  late final subtotal = computed(() => items.value * price.value);
  late final finalTotal = computed(
    () => (subtotal.value + tax.value - discount.value) * sharedMultiplier.value,
  );
}

class _ImmutableCartState {
  const _ImmutableCartState({
    required this.items,
    required this.price,
    required this.tax,
    required this.discount,
    required this.profileName,
  });

  final int items;
  final int price;
  final int tax;
  final int discount;
  final String profileName;

  int get total => (items * price) + tax - discount;

  _ImmutableCartState copyWith({
    int? items,
    int? price,
    int? tax,
    int? discount,
    String? profileName,
  }) =>
      _ImmutableCartState(
        items: items ?? this.items,
        price: price ?? this.price,
        tax: tax ?? this.tax,
        discount: discount ?? this.discount,
        profileName: profileName ?? this.profileName,
      );
}

int _simulateWidgetRebuildWork(int seed) {
  var acc = seed;
  for (var i = 0; i < 16; i++) {
    acc = (acc * 31 + i) & 0x7fffffff;
  }
  return acc;
}

void main() {
  tearDown(Sint.reset);

  group('4-Pillar SOTA Benchmark Suite (S · I · N · T)', () {
    test(
      'Pillar S: 20-Widget Screen Transaction — SINT 2.0 (Fine-Grained batch+computed) vs Coarse ChangeNotifier (Provider) vs Immutable Stream (BLoC)',
      () async {
        // 1. SINT 2.0: 19 unrelated signals + 4 transaction signals + 1 Computed total
        final unrelatedSignals = List<RxInt>.generate(19, (i) => i.obs);
        final items = 1.obs;
        final price = 10.obs;
        final tax = 2.obs;
        final discount = 1.obs;
        final total = Sint.computed(
          () => (items.value * price.value) + tax.value - discount.value,
        );

        var sintRebuilds = 0;
        var sintChecksum = 0;
        for (final rx in unrelatedSignals) {
          rx.addListener(() {
            sintRebuilds++;
            sintChecksum ^= _simulateWidgetRebuildWork(rx.peek);
          });
        }
        total.addListener(() {
          sintRebuilds++;
          sintChecksum ^= _simulateWidgetRebuildWork(total.peek);
        });

        var step = 0;
        final sintResult = await runBench(
          'four_pillars.s.sint_batched_20_widgets',
          () {
            step++;
            Sint.batch(() {
              items.value = (step & 7) + 1;
              price.value = ((step >> 1) & 15) + 10;
              tax.value = (step & 3) + 1;
              discount.value = (step & 1);
            });
          },
        );

        var unbatchedStep = 0;
        final unbatchedResult = await runBench(
          'four_pillars.s.sint_unbatched_20_widgets',
          () {
            unbatchedStep++;
            items.value = (unbatchedStep & 7) + 1;
            price.value = ((unbatchedStep >> 1) & 15) + 10;
            tax.value = (unbatchedStep & 3) + 1;
            discount.value = (unbatchedStep & 1);
          },
        );

        // 2. Coarse ChangeNotifier (Provider pattern): 20 widgets listening to the model
        final coarse = _CoarseCartModel();
        var coarseRebuilds = 0;
        var coarseChecksum = 0;
        for (var w = 0; w < 20; w++) {
          coarse.addListener(() {
            coarseRebuilds++;
            coarseChecksum ^= _simulateWidgetRebuildWork(coarse.total + w);
          });
        }

        var coarseStep = 0;
        final coarseResult = await runBench(
          'four_pillars.s.coarse_change_notifier_20_widgets',
          () {
            coarseStep++;
            coarse.items = (coarseStep & 7) + 1;
            coarse.price = ((coarseStep >> 1) & 15) + 10;
            coarse.tax = (coarseStep & 3) + 1;
            coarse.discount = (coarseStep & 1);
          },
        );

        // 3. Immutable State Stream (BLoC / Cubit sync emission pattern): 20 widget listeners
        var currentState = const _ImmutableCartState(
          items: 1,
          price: 10,
          tax: 2,
          discount: 1,
          profileName: 'Serzen',
        );
        final streamListeners = <void Function(_ImmutableCartState)>[
          for (var w = 0; w < 20; w++)
            (state) {
              coarseChecksum ^= _simulateWidgetRebuildWork(state.total + w);
            },
        ];
        void emit(_ImmutableCartState next) {
          currentState = next;
          for (var i = 0; i < streamListeners.length; i++) {
            streamListeners[i](next);
          }
        }

        var streamStep = 0;
        final streamResult = await runBench(
          'four_pillars.s.immutable_state_emit_20_widgets',
          () {
            streamStep++;
            emit(currentState.copyWith(items: (streamStep & 7) + 1));
            emit(currentState.copyWith(price: ((streamStep >> 1) & 15) + 10));
            emit(currentState.copyWith(tax: (streamStep & 3) + 1));
            emit(currentState.copyWith(discount: (streamStep & 1)));
          },
        );

        expect(sintRebuilds, greaterThan(0));
        expect(coarseRebuilds, greaterThan(0));
        expect(sintChecksum, isNot(0));
        expect(coarseChecksum, isNot(0));

        total.dispose();
        items.close();
        price.close();
        tax.close();
        discount.close();
        for (final rx in unrelatedSignals) {
          rx.close();
        }
        coarse.dispose();

        printBenchTable(
          'Pillar S — 20-Widget Screen 4-Field Transaction (SINT Batched vs SINT Unbatched vs ChangeNotifier vs Immutable State Copy)',
          [sintResult, unbatchedResult, coarseResult, streamResult],
        );
      },
    );

    test('Pillar N: SINT 2.0 Multi-Level Trie vs Linear RegExp Router (500 shared-prefix routes)', () async {
      final pages = <SintPage<dynamic>>[
        SintPage(name: '/', page: () => const SizedBox()),
        for (var i = 0; i < 500; i++)
          SintPage(
            name: '/api/v2/module$i/item/:id',
            page: () => const SizedBox(),
          ),
      ];
      final parser = RouteParser(routes: pages);

      // Equivalent linear compiled-regex table (traditional 1st-gen router / unindexed shared prefix)
      final linearPatterns = <({RegExp regex, String name})>[
        for (var i = 0; i < 500; i++)
          (
            regex: RegExp('^/api/v2/module$i/item/([^/]+)\$'),
            name: '/api/v2/module$i/item/:id',
          ),
      ];

      const targetUrl = '/api/v2/module499/item/42?lang=es';
      var trieHits = 0;
      final trieResult = await runBench(
        'four_pillars.n.sint_trie_500',
        () {
          final match = parser.matchRoute(targetUrl);
          if (match.route?.parameters?['id'] == '42') {
            trieHits++;
          }
        },
      );

      var linearHits = 0;
      final linearResult = await runBench(
        'four_pillars.n.linear_regex_500',
        () {
          final uri = Uri.parse(targetUrl);
          for (var i = 0; i < linearPatterns.length; i++) {
            final m = linearPatterns[i].regex.firstMatch(uri.path);
            if (m != null && m.group(1) == '42') {
              linearHits++;
              break;
            }
          }
        },
      );

      expect(trieHits, trieResult.totalOperations);
      expect(linearHits, linearResult.totalOperations);

      printBenchTable(
        'Pillar N — 500 Shared-Prefix Routes (/api/v2/module499/item/42)',
        [trieResult, linearResult],
      );
    });

    test('Integrated 4-Pillar Full Cycle (N Route + I DI Find + S Batch/Computed + T i18n)', () async {
      Sint.clearTranslations();
      Sint.addTranslations({
        'es_ES': {
          'order_summary': 'Item @id: @total MXN',
        },
      });
      Sint.locale = const Locale('es', 'ES');

      final sharedMultiplier = 1.obs;
      Sint.put(_FourPillarController(sharedMultiplier));
      final pages = <SintPage<dynamic>>[
        SintPage(name: '/', page: () => const SizedBox()),
        for (var i = 0; i < 100; i++)
          SintPage(
            name: '/shop/category$i/item/:id',
            page: () => const SizedBox(),
          ),
      ];
      final parser = RouteParser(routes: pages);

      var validCycles = 0;
      var step = 0;

      final fullCycleResult = await runBench(
        'four_pillars.integrated.full_cycle',
        () {
          step++;
          // 1. Pillar N: Match deep route with parameters
          final match = parser.matchRoute('/shop/category99/item/77');
          final itemId = match.route?.parameters?['id'] ?? '';

          // 2. Pillar I: O(1) Type-keyed controller resolution
          final c = Sint.find<_FourPillarController>();

          // 3. Pillar S: Batched state mutation + memoized Computed read
          Sint.batch(() {
            c.items.value = (step & 7) + 1;
            c.price.value = ((step >> 1) & 7) + 10;
          });
          final currentTotal = c.finalTotal.value;

          // 4. Pillar T: Parameterized translation resolution
          final label = 'order_summary'.trParams({
            'id': itemId,
            'total': '$currentTotal',
          });
          if (label.startsWith('Item 77:')) {
            validCycles++;
          }
        },
      );

      expect(validCycles, fullCycleResult.totalOperations);
      sharedMultiplier.close();

      printBenchTable(
        'Integrated S·I·N·T Full Cycle (Route Match + DI Find + Batch/Computed + i18n)',
        [fullCycleResult],
      );
    });
  });
}
