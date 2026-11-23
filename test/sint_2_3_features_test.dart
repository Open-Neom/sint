import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _TelemetryPacket {
  const _TelemetryPacket({
    required this.sampleIndex,
    required this.alphaPower,
    required this.channelLabel,
  });

  final int sampleIndex;
  final double alphaPower;
  final String channelLabel;
}

class _TelemetryController extends SintController {
  final rawHz = 0.obs;
  late final FrameThrottledRx<int> uiHz = frameThrottled(rawHz);
}

class _DummyRepo {}

void main() {
  setUp(() {
    Sint.reset();
    Sint.clearTranslations();
  });

  tearDown(() {
    Sint.reset();
    Sint.clearTranslations();
  });

  group('Sint.frameBatch (VSync-aligned coalescing)', () {
    test('coalesces 256 rapid mutations across ticks into 1 single flush via custom scheduler', () {
      final scheduledCallbacks = <VoidCallback>[];
      ListNotifier.frameScheduler = scheduledCallbacks.add;

      final eegSample = 0.0.obs;
      final peakDb = (-60.0).obs;
      var eegNotifies = 0;
      var peakNotifies = 0;

      final d1 = eegSample.addListener(() => eegNotifies++);
      final d2 = peakDb.addListener(() => peakNotifies++);
      addTearDown(() {
        d1();
        d2();
      });

      // Simulate 256 Hz telemetry arriving across 16 separate callbacks in one frame.
      for (var i = 1; i <= 256; i++) {
        Sint.frameBatch(() {
          eegSample.value = i * 0.25;
          peakDb.value = -60.0 + (i % 48);
        });
      }

      // No listeners notified yet, only 1 VSync flush scheduled.
      expect(eegNotifies, 0);
      expect(peakNotifies, 0);
      expect(ListNotifier.hasPendingFrameBatch, isTrue);
      expect(scheduledCallbacks.length, 1);

      // Flush on VSync boundary.
      scheduledCallbacks.single();

      expect(eegNotifies, 1);
      expect(peakNotifies, 1);
      expect(eegSample.value, 64.0);
      expect(peakDb.value, -60.0 + (256 % 48));
      expect(ListNotifier.hasPendingFrameBatch, isFalse);
    });

    test('Sint.flushFrameBatch() flushes pending updates immediately', () {
      final scheduled = <VoidCallback>[];
      ListNotifier.frameScheduler = scheduled.add;

      final count = 0.obs;
      var notifies = 0;
      final disposer = count.addListener(() => notifies++);
      addTearDown(disposer);

      Sint.frameBatch(() {
        count.value = 1;
        count.value = 2;
        count.value = 3;
      });
      expect(notifies, 0);

      Sint.flushFrameBatch();
      expect(notifies, 1);
      expect(count.value, 3);
      expect(ListNotifier.hasPendingFrameBatch, isFalse);

      // Firing the stale scheduled callback later is a safe no-op.
      scheduled.single();
      expect(notifies, 1);
    });

    testWidgets(
      'coalesces 100 mutations into 1 Obx rebuild on the next real Flutter frame',
      (tester) async {
        final playheadMs = 0.obs;
        var builds = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Obx(() {
              builds++;
              return Text('${playheadMs.value}');
            }),
          ),
        );

        expect(builds, 1);
        expect(find.text('0'), findsOneWidget);

        for (var i = 1; i <= 100; i++) {
          Sint.frameBatch(() {
            playheadMs.value = i * 16;
          });
        }

        // Before pumping the VSync frame, Obx has not rebuilt yet.
        expect(builds, 1);

        await tester.pump();

        expect(builds, 2);
        expect(find.text('1600'), findsOneWidget);
      },
    );
  });

  group('FrameThrottledRx & SintController.frameThrottled', () {
    test('coalesces bursts to 1 emit per frame and skips no-op jitter', () {
      final scheduled = <VoidCallback>[];
      ListNotifier.frameScheduler = scheduled.add;

      final source = 0.obs;
      final throttled = source.throttledToFrame();
      addTearDown(throttled.dispose);

      var emits = 0;
      final received = <int>[];
      final disposer = throttled.addListener(() {
        emits++;
        received.add(throttled.value);
      });
      addTearDown(disposer);

      // High-frequency burst: 1..50 in a single frame.
      for (var i = 1; i <= 50; i++) {
        source.value = i;
      }
      expect(emits, 0);
      expect(scheduled.length, 1);

      scheduled.removeLast()();
      expect(emits, 1);
      expect(received, [50]);

      // Sub-frame jitter returning to the last emitted value (50 -> 99 -> 50)
      // must emit 0 notifications!
      source.value = 99;
      source.value = 50;
      expect(scheduled.length, 1);
      scheduled.removeLast()();
      expect(emits, 1);
      expect(received, [50]);
    });

    test('skips frame scheduling while unobserved (zero listeners)', () {
      final scheduled = <VoidCallback>[];
      ListNotifier.frameScheduler = scheduled.add;

      final source = 0.obs;
      final throttled = Sint.frameThrottled(source);
      addTearDown(throttled.dispose);

      source.value = 42;
      expect(scheduled, isEmpty);
      expect(throttled.value, 42);
    });

    test('direct assignment throws UnsupportedError', () {
      final throttled = 0.obs.throttledToFrame();
      addTearDown(throttled.dispose);

      expect(() => throttled.value = 1, throwsUnsupportedError);
      expect(() => throttled(1), throwsUnsupportedError);
      expect(throttled(), 0);
    });

    test('flushes in the same frame when upstream uses Sint.frameBatch', () {
      final scheduled = <VoidCallback>[];
      ListNotifier.frameScheduler = scheduled.add;

      final source = 0.obs;
      final throttled = source.throttledToFrame();
      addTearDown(throttled.dispose);

      var emits = 0;
      final disposer = throttled.addListener(() => emits++);
      addTearDown(disposer);

      Sint.frameBatch(() {
        source.value = 7;
        source.value = 14;
      });
      expect(emits, 0);
      expect(scheduled.length, 1);

      // One single VSync flush updates both source and throttled without a 1-frame lag.
      scheduled.removeLast()();
      expect(emits, 1);
      expect(throttled.value, 14);
    });

    test(
      'SintController.frameThrottled auto-disposes on controller.onClose',
      () {
        final controller = Sint.put(_TelemetryController());
        expect(controller.uiHz.isDisposed, isFalse);

        Sint.delete<_TelemetryController>();
        expect(controller.uiHz.isDisposed, isTrue);
      },
    );
  });

  group('ObxSelect<T>', () {
    testWidgets(
      'rebuilds only when selected slice changes and ignores unrelated mutations',
      (tester) async {
        final packet = const _TelemetryPacket(
          sampleIndex: 0,
          alphaPower: 1.0,
          channelLabel: 'Fp1',
        ).obs;

        var labelBuilds = 0;
        var powerBuilds = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                ObxSelect<String>(
                  debugLabel: 'channel-label',
                  selector: () => packet.value.channelLabel,
                  builder: (label) {
                    labelBuilds++;
                    return Text('ch:$label');
                  },
                ),
                ObxSelect<double>(
                  debugLabel: 'alpha-power',
                  selector: () => packet.value.alphaPower,
                  equals: (prev, next) => (prev - next).abs() < 0.05,
                  builder: (power) {
                    powerBuilds++;
                    return Text('p:${power.toStringAsFixed(2)}');
                  },
                ),
              ],
            ),
          ),
        );

        expect(labelBuilds, 1);
        expect(powerBuilds, 1);

        // Mutate sampleIndex and sub-threshold alpha jitter (delta = 0.01 < 0.05).
        packet.value = const _TelemetryPacket(
          sampleIndex: 1,
          alphaPower: 1.01,
          channelLabel: 'Fp1',
        );
        await tester.pump();

        expect(labelBuilds, 1);
        expect(powerBuilds, 1);

        // Exceed custom equals threshold for alphaPower; label stays unchanged.
        packet.value = const _TelemetryPacket(
          sampleIndex: 2,
          alphaPower: 1.50,
          channelLabel: 'Fp1',
        );
        await tester.pump();

        expect(labelBuilds, 1);
        expect(powerBuilds, 2);
        expect(find.text('p:1.50'), findsOneWidget);

        // Now change channelLabel.
        packet.value = const _TelemetryPacket(
          sampleIndex: 3,
          alphaPower: 1.50,
          channelLabel: 'Oz',
        );
        await tester.pump();

        expect(labelBuilds, 2);
        expect(powerBuilds, 2);
        expect(find.text('ch:Oz'), findsOneWidget);
      },
    );

    testWidgets(
      'respects ancestor SintScope overrides inside selector & builder',
      (tester) async {
        final globalValue = 'global'.obs;
        final scopedValue = 'scoped'.obs;
        Sint.put<RxString>(globalValue, tag: 'label');

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SintScope(
              overrides: [
                SintOverride.value<RxString>(scopedValue, tag: 'label'),
              ],
              child: ObxSelect<String>(
                selector: () => Sint.find<RxString>(tag: 'label').value,
                builder: (value) => Text(value),
              ),
            ),
          ),
        );

        expect(find.text('scoped'), findsOneWidget);

        scopedValue.value = 'scoped-v2';
        await tester.pump();
        expect(find.text('scoped-v2'), findsOneWidget);
      },
    );
  });

  group('SintDiagnostics (Sint.diagnostics)', () {
    testWidgets(
      'tracks Obx & ObxSelect rebuilds sorted descending and reports 4-pillar snapshot',
      (tester) async {
        Sint.put(_DummyRepo(), tag: 'primary', permanent: true);
        Sint.addTranslations({
          'en_US': {'hello': 'Hello'},
          'es_MX': {'hello': 'Hola'},
        });
        Sint.locale = const Locale('es', 'MX');

        final hot = 0.obs;
        final cold = 0.obs;

        Sint.diagnostics.enableRebuildTracking = true;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                Obx(() => Text('hot:${hot.value}'), debugLabel: 'hot-meter'),
                ObxSelect<int>(
                  debugLabel: 'cold-badge',
                  selector: () => cold.value,
                  builder: (v) => Text('cold:$v'),
                ),
              ],
            ),
          ),
        );

        hot.value = 1;
        await tester.pump();
        hot.value = 2;
        await tester.pump();

        final stats = Sint.diagnostics.rebuildStats();
        expect(stats.keys.toList(), ['hot-meter', 'cold-badge']);
        expect(stats['hot-meter'], 3);
        expect(stats['cold-badge'], 1);
        expect(Sint.diagnostics.totalRebuilds, 4);

        final snap = Sint.diagnostics.snapshot();
        expect(
          snap.keys,
          containsAll(['state', 'injection', 'navigation', 'translation']),
        );

        final state = snap['state']! as Map<String, Object?>;
        expect(state['rebuildTrackingEnabled'], isTrue);
        expect(state['totalRebuilds'], 4);

        final injection = snap['injection']! as Map<String, Object?>;
        expect(injection['count'], 1);
        final deps = injection['dependencies']! as List<Map<String, Object?>>;
        expect(deps.single['tag'], 'primary');
        expect(deps.single['permanent'], isTrue);
        expect(deps.single['instantiated'], isTrue);

        final translation = snap['translation']! as Map<String, Object?>;
        expect(translation['locale'], 'es_MX');
        final sizes = translation['dictionarySizes']! as Map<String, int>;
        expect(sizes['en_US'], 1);
        expect(sizes['es_MX'], 1);

        Sint.diagnostics.resetRebuildStats();
        expect(Sint.diagnostics.totalRebuilds, 0);
        expect(Sint.diagnostics.rebuildStats(), isEmpty);
        expect(Sint.diagnostics.enableRebuildTracking, isTrue);

        Sint.reset();
        expect(Sint.diagnostics.enableRebuildTracking, isFalse);
      },
    );

    testWidgets(
      'reports live navigation stack in routesSnapshot() inside SintApp',
      (tester) async {
        await tester.pumpWidget(
          SintApp(
            initialRoute: '/home',
            sintPages: [
              SintPage(name: '/home', page: () => const Text('Home')),
              SintPage(name: '/detail', page: () => const Text('Detail')),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final initialNav = Sint.diagnostics.routesSnapshot();
        expect(initialNav['treeInitialized'], isTrue);
        expect(initialNav['currentRoute'], '/home');
        expect(initialNav['activePages'], ['/home']);

        Sint.toNamed('/detail');
        await tester.pumpAndSettle();

        final detailNav = Sint.diagnostics.routesSnapshot();
        expect(detailNav['currentRoute'], '/detail');
        expect(detailNav['canBack'], isTrue);
        expect(detailNav['activePages'], ['/home', '/detail']);
      },
    );

    testWidgets(
      'onRebuild hook streams Obx rebuilds even when enableRebuildTracking is false (sint_sentinel bridge)',
      (tester) async {
        final events = <(String, int)>[];
        Sint.diagnostics.onRebuild = (label, count) =>
            events.add((label, count));

        final counter = 0.obs;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Obx(
              () => Text('${counter.value}'),
              debugLabel: 'sentinel-target',
            ),
          ),
        );

        counter.value = 1;
        await tester.pump();
        counter.value = 2;
        await tester.pump();

        expect(events, [
          ('sentinel-target', 1),
          ('sentinel-target', 2),
          ('sentinel-target', 3),
        ]);

        Sint.reset();
        expect(Sint.diagnostics.onRebuild, isNull);
      },
    );
  });

  group(
    'Ecosystem Ergonomics (Sint.findOrPut & Headless-Safe Route Getters)',
    () {
      test('Sint.findOrPut registers once, avoids invoking builder when present, and honors SintScope', () async {
        var creations = 0;
        final first = Sint.findOrPut<_DummyRepo>(() {
          creations++;
          return _DummyRepo();
        });
        final second = Sint.findOrPut<_DummyRepo>(() {
          creations++;
          return _DummyRepo();
        });

        expect(identical(first, second), isTrue);
        expect(creations, 1);

        final scoped = _DummyRepo();
        await SintScope.run(
          overrides: [SintOverride.value<_DummyRepo>(scoped)],
          body: () {
            final resolved = Sint.findOrPut<_DummyRepo>(() {
              creations++;
              return _DummyRepo();
            });
            expect(identical(resolved, scoped), isTrue);
            expect(creations, 1);
          },
        );
      });

      test('Sint.find missing throws typed StateError (only_throw_errors)', () {
        expect(() => Sint.find<_DummyRepo>(), throwsStateError);
      });

      test('route argument & parameter getters return safe defaults without SintRoot', () {
        expect(Sint.arguments, isNull);
        expect(Sint.argumentsAs<String>(), isNull);
        expect(Sint.parameters, isEmpty);
        expect(Sint.pathParams, isEmpty);
        expect(Sint.queryParams, isEmpty);
        expect(Sint.routeParam, isNull);
        expect(Sint.pathParam('id'), isNull);
        expect(Sint.queryParam('tab'), isNull);
        expect(Sint.queryParamOrDefault('sort', 'recent'), 'recent');
      });

      testWidgets(
        'Sint.argumentsAs<T>() returns typed value on match and null on type mismatch',
        (tester) async {
          await tester.pumpWidget(
            SintApp(
              initialRoute: '/home',
              sintPages: [
                SintPage(name: '/home', page: () => const Text('Home')),
                SintPage(name: '/item', page: () => const Text('Item')),
              ],
            ),
          );
          await tester.pumpAndSettle();

          Sint.toNamed(
            '/item',
            arguments: const _TelemetryPacket(
              sampleIndex: 7,
              alphaPower: 2.5,
              channelLabel: 'Cz',
            ),
          );
          await tester.pumpAndSettle();

          final packet = Sint.argumentsAs<_TelemetryPacket>();
          expect(packet, isNotNull);
          expect(packet!.channelLabel, 'Cz');
          expect(Sint.argumentsAs<String>(), isNull);
        },
      );
    },
  );
}
