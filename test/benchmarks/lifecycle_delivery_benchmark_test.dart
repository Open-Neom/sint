@Tags(['benchmark'])
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';
import 'bench_harness.dart';

class CleanupBenchController extends SintController {
  static int started = 0;
  static int closed = 0;
  // This workload isolates synchronous disposal, excluding onReady scheduling.
  @override
  // ignore: must_call_super
  void onInit() {
    started++;
  }

  @override
  void onClose() {
    closed++;
    super.onClose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Sint.reset);

  for (final count in [1000, 4000, 16000]) {
    test('Dispose one route with $count linked controllers', () async {
      late RouterReportManager router;
      late Object route;
      final result = await runPreparedBench(
        'di.route_dispose.per_dependency.count=$count',
        operationsPerBatch: count,
        prepare: () async {
          Sint.reset();
          Sint.isLogEnable = false;
          CleanupBenchController.started = 0;
          CleanupBenchController.closed = 0;
          router = RouterReportManager.instance;
          route = Object();
          router.reportCurrentRoute(route);
          for (var i = 0; i < count; i++) {
            Sint.put(CleanupBenchController(), tag: 'cleanup$i');
          }
          expect(CleanupBenchController.started, count);
        },
        body: () {
          router.reportRouteDispose(route);
          return null;
        },
        verify: () {
          expect(CleanupBenchController.closed, count);
          for (var i = 0; i < count; i++) {
            if (Sint.isRegistered<CleanupBenchController>(tag: 'cleanup$i')) {
              fail('Route disposal retained controller $i');
            }
          }
        },
        cleanup: () async {
          Sint.reset();
        },
      );
      printBenchTable(
          'Route disposal time / $count dependencies, setup excluded',
          [result]);
    });
  }

  for (final count in [1000, 30000]) {
    for (final kind in ['rx', 'native_broadcast_stream']) {
      test('Async delivery $kind, $count events', () async {
        RxInt? rx;
        StreamController<int>? native;
        StreamSubscription<int>? subscription;
        late Completer<void> complete;
        var delivered = 0;
        var checksum = 0;
        final result = await runPreparedBench(
          'state.async.$kind.delivered_events=$count',
          operationsPerBatch: count,
          prepare: () async {
            delivered = 0;
            checksum = 0;
            complete = Completer<void>();
            void receive(int value) {
              delivered++;
              checksum += value;
              if (delivered == count) complete.complete();
            }

            if (kind == 'rx') {
              rx = 0.obs;
              subscription = rx!.listen(receive);
            } else {
              native = StreamController<int>.broadcast();
              subscription = native!.stream.listen(receive);
            }
          },
          body: () {
            if (kind == 'rx') {
              for (var i = 1; i <= count; i++) {
                rx!.value = i;
              }
            } else {
              for (var i = 1; i <= count; i++) {
                native!.add(i);
              }
            }
            return complete.future.timeout(const Duration(seconds: 10));
          },
          verify: () {
            expect(delivered, count);
            expect(checksum, count * (count + 1) ~/ 2);
            if (rx != null) expect(rx!.value, count);
          },
          cleanup: () async {
            await subscription?.cancel();
            rx?.close();
            await native?.close();
            subscription = null;
            rx = null;
            native = null;
          },
        );
        printBenchTable(
            'Enqueue through final asynchronous event delivery; subscription setup excluded',
            [result]);
      });
    }
  }
}
