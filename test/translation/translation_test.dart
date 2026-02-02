import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart'; // Official entry point [cite: 23]

int times = 30;

void printValue(String value) {
  // ignore: avoid_print
  print(value);
}

/// Benchmark: Native Flutter ValueNotifier
Future<int> valueNotifierBenchmark() {
  final c = Completer<int>();
  final value = ValueNotifier<int>(0);
  final timer = Stopwatch()..start();

  value.addListener(() {
    if (times == value.value) {
      timer.stop();
      printValue("""$times updates | [VALUE_NOTIFIER] time: ${timer.elapsedMicroseconds}us""");
      c.complete(timer.elapsedMicroseconds);
    }
  });

  for (var i = 1; i <= times; i++) {
    value.value = i;
  }
  return c.future;
}

/// Benchmark: SINT Rx (Replacing GetX Value/ever) [cite: 23]
/// Uses .listen() directly on the reactive variable.
Future<int> sintRxBenchmark() {
  final c = Completer<int>();
  final value = 0.obs; // SINT Pillar S reactive variable [cite: 23]
  final timer = Stopwatch()..start();

  // We use .listen() instead of the 'ever' worker for surgical precision
  value.listen((v) {
    if (times == v) {
      timer.stop();
      printValue("""$times updates | [SINT_RX] time: ${timer.elapsedMicroseconds}us""");
      c.complete(timer.elapsedMicroseconds);
    }
  });

  for (var i = 1; i <= times; i++) {
    value.value = i;
  }
  return c.future;
}

/// Benchmark: Standard Dart Stream
Future<int> dartStreamBenchmark() {
  final c = Completer<int>();
  final controller = StreamController<int>();
  final timer = Stopwatch()..start();

  controller.stream.listen((v) {
    if (times == v) {
      timer.stop();
      printValue("""$times updates | [DART_STREAM] time: ${timer.elapsedMicroseconds}us""");
      c.complete(timer.elapsedMicroseconds);
      controller.close();
    }
  });

  for (var i = 1; i <= times; i++) {
    controller.add(i);
  }
  return c.future;
}

void main() {
  test('SINT 1.0.0 vs Native Performance Audit', () async {
    printValue('============================================');
    printValue('PILLAR S: REACTIVE BENCHMARK (HIGH LOAD)');
    printValue('Comparing SINT Rx vs Flutter/Dart Native Tools');

    // Low load warm-up
    times = 30;
    await valueNotifierBenchmark();
    await sintRxBenchmark();
    await dartStreamBenchmark();

    // High load (30,000 updates) to see the efficiency of SINT's pruned core [cite: 10]
    times = 30000;
    printValue('----------- Starting High Load ($times updates) -----------');

    final dartValueTime = await valueNotifierBenchmark();
    final sintRxTime = await sintRxBenchmark();
    final dartStreamTime = await dartStreamBenchmark();

    printValue('----------- Performance Summary -----------');
    printValue('ValueNotifier: $dartValueTime us');
    printValue('Dart Stream:   $dartStreamTime us');
    printValue('SINT Rx:       $sintRxTime us');
    printValue('-----------');

    final fasterThanValue = calculePercentage(dartValueTime, sintRxTime);
    final fasterThanStream = calculePercentage(dartStreamTime, sintRxTime);

    printValue('SINT Rx is $fasterThanValue% faster than ValueNotifier');
    printValue('SINT Rx is $fasterThanStream% faster than Dart Streams');
    printValue('============================================');
  });
}

int calculePercentage(int reference, int target) {
  // Original logic: how much more is the reference compared to the target
  return (reference / target * 100).round() - 100;
}