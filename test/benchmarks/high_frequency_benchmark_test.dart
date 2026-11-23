@Tags(['benchmark'])
library;

// ignore_for_file: avoid_print

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

import 'bench_harness.dart';

/// High-frequency real-time telemetry benchmark simulating Open Neom's
/// extreme-performance workloads (e.g., 256 Hz EEG streams, DAW playheads,
/// VR sensor ticks, or 100 tok/s on-device LLM streams).
///
/// Workload per frame:
/// - 8 telemetry bursts arrive before a single 60 fps VSync boundary
///   (simulating ~480 Hz / multi-channel 256 Hz sensors).
/// - 50 active reactive listeners/widgets observe the stream.
/// - Compares:
///   1. Raw unbatched `ValueNotifier` (8 × 50 = 400 dispatches/frame)
///   2. Unbatched `Rx` (8 × 50 = 400 dispatches/frame)
///   3. `Sint.frameBatch` coalesced to VSync (1 × 50 = 50 dispatches/frame)
///   4. `FrameThrottledRx` (`.throttledToFrame()`) coalesced to VSync
void main() {
  setUp(Sint.reset);
  tearDown(Sint.reset);

  test('High-Frequency 256Hz->60fps Telemetry Coalescing Benchmark (50 subscribers × 60 frames)', () async {
    const frames = 60;
    const burstsPerFrame = 8;
    const subscribers = 50;

    // 1. Baseline: Flutter ValueNotifier (unbatched)
    final vn = ValueNotifier<int>(0);
    var vnDelivered = 0;
    var vnDispatches = 0;
    final vnListeners = <VoidCallback>[];
    for (var i = 0; i < subscribers; i++) {
      void fn() {
        vnDispatches++;
        vnDelivered += vn.value;
      }

      vnListeners.add(fn);
      vn.addListener(fn);
    }
    var vnTick = 0;
    final vnResult = await runBench(
      'ValueNotifier (unbatched 8 bursts/frame × 50 subs)',
      () {
        vnDispatches = 0;
        for (var f = 0; f < frames; f++) {
          for (var b = 0; b < burstsPerFrame; b++) {
            vn.value = ++vnTick;
          }
        }
      },
      warmup: 5,
      iterations: 10,
    );
    for (final fn in vnListeners) {
      vn.removeListener(fn);
    }
    vn.dispose();
    expect(vnDispatches, frames * burstsPerFrame * subscribers);

    // 2. Unbatched SINT Rx
    final rawRx = 0.obs;
    var rawDelivered = 0;
    var rawDispatches = 0;
    final rawDisposers = <Disposer>[];
    for (var i = 0; i < subscribers; i++) {
      rawDisposers.add(
        rawRx.addListener(() {
          rawDispatches++;
          rawDelivered += rawRx.peek;
        }),
      );
    }
    var rawTick = 0;
    final rawRxResult = await runBench(
      'SINT Rx (unbatched 8 bursts/frame × 50 subs)',
      () {
        rawDispatches = 0;
        for (var f = 0; f < frames; f++) {
          for (var b = 0; b < burstsPerFrame; b++) {
            rawRx.value = ++rawTick;
          }
        }
      },
      warmup: 5,
      iterations: 10,
    );
    for (final d in rawDisposers) {
      d();
    }
    rawRx.close();
    expect(rawDispatches, frames * burstsPerFrame * subscribers);

    // 3. SINT 2.3 Sint.frameBatch (VSync-aligned coalescing)
    VoidCallback? pendingBatchFlush;
    ListNotifier.frameScheduler = (cb) => pendingBatchFlush = cb;
    final batchRx = 0.obs;
    var batchDelivered = 0;
    var batchDispatches = 0;
    final batchDisposers = <Disposer>[];
    for (var i = 0; i < subscribers; i++) {
      batchDisposers.add(
        batchRx.addListener(() {
          batchDispatches++;
          batchDelivered += batchRx.peek;
        }),
      );
    }
    var batchTick = 0;
    final frameBatchResult = await runBench(
      'SINT 2.3 Sint.frameBatch (VSync 1 flush/frame × 50 subs)',
      () {
        batchDispatches = 0;
        for (var f = 0; f < frames; f++) {
          for (var b = 0; b < burstsPerFrame; b++) {
            Sint.frameBatch(() {
              batchRx.value = ++batchTick;
            });
          }
          pendingBatchFlush?.call();
          pendingBatchFlush = null;
        }
      },
      warmup: 5,
      iterations: 10,
    );
    for (final d in batchDisposers) {
      d();
    }
    batchRx.close();
    ListNotifier.resetFrameBatch();
    expect(batchDispatches, frames * subscribers);

    // 4. SINT 2.3 FrameThrottledRx (.throttledToFrame())
    VoidCallback? pendingThrottleFlush;
    ListNotifier.frameScheduler = (cb) => pendingThrottleFlush = cb;
    final srcRx = 0.obs;
    final throttled = srcRx.throttledToFrame();
    var throttledDelivered = 0;
    var throttledDispatches = 0;
    final throttledDisposers = <Disposer>[];
    for (var i = 0; i < subscribers; i++) {
      throttledDisposers.add(
        throttled.addListener(() {
          throttledDispatches++;
          throttledDelivered += throttled.peek;
        }),
      );
    }
    var throttledTick = 0;
    final throttledResult = await runBench(
      'SINT 2.3 FrameThrottledRx (VSync 1 flush/frame × 50 subs)',
      () {
        throttledDispatches = 0;
        for (var f = 0; f < frames; f++) {
          for (var b = 0; b < burstsPerFrame; b++) {
            srcRx.value = ++throttledTick;
          }
          pendingThrottleFlush?.call();
          pendingThrottleFlush = null;
        }
      },
      warmup: 5,
      iterations: 10,
    );
    for (final d in throttledDisposers) {
      d();
    }
    throttled.dispose();
    srcRx.close();
    ListNotifier.resetFrameBatch();
    expect(throttledDispatches, frames * subscribers);

    // Guard against dead-code elimination.
    expect(vnDelivered, greaterThan(0));
    expect(rawDelivered, greaterThan(0));
    expect(batchDelivered, greaterThan(0));
    expect(throttledDelivered, greaterThan(0));

    final batchSpeedup =
        vnResult.medianBatchUs / frameBatchResult.medianBatchUs;
    final throttledSpeedup =
        vnResult.medianBatchUs / throttledResult.medianBatchUs;

    print(
      '\n[SINT 2.3 High-Frequency Telemetry Benchmark — 60 frames × 8 bursts/frame × 50 subs]\n'
      '  ValueNotifier (unbatched, 24,000 dispatches)     : ${vnResult.medianBatchUs.toStringAsFixed(1)} µs\n'
      '  SINT Rx (unbatched, 24,000 dispatches)           : ${rawRxResult.medianBatchUs.toStringAsFixed(1)} µs\n'
      '  SINT 2.3 Sint.frameBatch (VSync, 3,000 disp.)    : ${frameBatchResult.medianBatchUs.toStringAsFixed(1)} µs (${batchSpeedup.toStringAsFixed(2)}x vs ValueNotifier)\n'
      '  SINT 2.3 FrameThrottledRx (VSync, 3,000 disp.)   : ${throttledResult.medianBatchUs.toStringAsFixed(1)} µs (${throttledSpeedup.toStringAsFixed(2)}x vs ValueNotifier)\n',
    );
  });
}
