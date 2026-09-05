// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

const benchmarkSchemaVersion = 2;

/// Samples are means of timed batches, NOT individual-operation latencies.
class BenchResult {
  BenchResult({
    required this.name,
    required this.iterations,
    required this.rounds,
    required List<double> samples,
    required this.totalOperations,
    required this.warmupOperations,
    required this.configuration,
  }) : samples = List.unmodifiable(samples) {
    if (samples.isEmpty || samples.any((v) => !v.isFinite || v < 0)) {
      throw ArgumentError('Samples must be finite, non-negative and non-empty');
    }
    if (rounds != samples.length || iterations < 1) {
      throw ArgumentError('Invalid round/iteration count');
    }
  }

  final String name;
  final int iterations;
  final int rounds;
  final int totalOperations;
  final int warmupOperations;
  final Map<String, int> configuration;

  /// Unsorted samples preserve execution order to expose warmup/drift.
  final List<double> samples;

  static double median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  double get medianBatchUs => median(samples);
  double get minBatchUs => samples.reduce((a, b) => a < b ? a : b);
  double get maxBatchUs => samples.reduce((a, b) => a > b ? a : b);
  double get madBatchUs =>
      median(samples.map((value) => (value - medianBatchUs).abs()).toList());

  Map<String, Object> toJson() => {
        'schemaVersion': benchmarkSchemaVersion,
        'name': name,
        'metric': 'batch_mean_us_per_operation',
        'iterationsPerRound': iterations,
        'rounds': rounds,
        'totalOperations': totalOperations,
        'warmupOperations': warmupOperations,
        'configuration': configuration,
        'samples': samples,
        'medianBatchUs': medianBatchUs,
        'madBatchUs': madBatchUs,
        'minBatchUs': minBatchUs,
        'maxBatchUs': maxBatchUs,
      };
}

/// Synchronous operations with time-based warmup and batch calibration.
/// Setup/teardown belong outside body unless lifecycle is the named workload.
Future<BenchResult> runBench(
  String name,
  void Function() body, {
  int warmup = 2000,
  int iterations = 1000,
  int? rounds,
  Duration? warmupDuration,
  Duration? minimumBatchDuration,
}) async {
  final full = Platform.environment['SINT_BENCH_FULL'] == 'true';
  final roundCount = rounds ?? (full ? 21 : 7);
  final warmDuration =
      warmupDuration ?? Duration(milliseconds: full ? 200 : 15);
  final batchDuration =
      minimumBatchDuration ?? Duration(milliseconds: full ? 40 : 5);
  if (warmup < 0 ||
      iterations < 1 ||
      roundCount < 1 ||
      warmDuration.isNegative ||
      batchDuration.isNegative) {
    throw ArgumentError('Invalid benchmark configuration');
  }

  var totalOperations = 0;
  var warmOperations = 0;
  final sw = Stopwatch()..start();
  do {
    for (var i = 0; i < warmup; i++) {
      body();
      warmOperations++;
    }
    if (warmup == 0 && sw.elapsed < warmDuration) {
      body();
      warmOperations++;
    }
  } while (sw.elapsed < warmDuration);
  totalOperations += warmOperations;

  var batchIterations = iterations;
  // Count calibration operations so assertions can verify ALL deliveries.
  if (batchDuration > Duration.zero) {
    while (true) {
      sw
        ..reset()
        ..start();
      for (var i = 0; i < batchIterations; i++) {
        body();
      }
      sw.stop();
      totalOperations += batchIterations;
      if (sw.elapsed >= batchDuration || batchIterations >= 16777216) break;
      batchIterations *= 2;
    }
  }

  final samples = <double>[];
  for (var round = 0; round < roundCount; round++) {
    sw
      ..reset()
      ..start();
    for (var i = 0; i < batchIterations; i++) {
      body();
    }
    sw.stop();
    totalOperations += batchIterations;
    samples.add(sw.elapsedTicks * 1000000 / sw.frequency / batchIterations);
  }
  return BenchResult(
    name: name,
    iterations: batchIterations,
    rounds: roundCount,
    samples: samples,
    totalOperations: totalOperations,
    warmupOperations: warmOperations,
    configuration: {
      'minimumWarmupOperations': warmup,
      'minimumWarmupMicroseconds': warmDuration.inMicroseconds,
      'initialBatchIterations': iterations,
      'minimumBatchMicroseconds': batchDuration.inMicroseconds,
      'rounds': roundCount,
    },
  );
}

/// Fixed, bounded batches for destructive lifecycle or asynchronous delivery.
/// Preparation, validation and cleanup are excluded from the timed interval.
/// A null body result denotes synchronous work; a Future is awaited to DELIVERY.
Future<BenchResult> runPreparedBench(
  String name, {
  required int operationsPerBatch,
  required Future<void> Function() prepare,
  required Future<void>? Function() body,
  required void Function() verify,
  required Future<void> Function() cleanup,
  int? rounds,
  int? warmupBatches,
}) async {
  final full = Platform.environment['SINT_BENCH_FULL'] == 'true';
  final measured = rounds ?? (full ? 21 : 7);
  final warmups = warmupBatches ?? (full ? 3 : 1);
  if (operationsPerBatch < 1 || measured < 1 || warmups < 0) {
    throw ArgumentError('Invalid prepared-batch configuration');
  }
  final samples = <double>[];
  for (var batch = 0; batch < warmups + measured; batch++) {
    try {
      await prepare();
      final stopwatch = Stopwatch()..start();
      final completion = body();
      if (completion != null) await completion;
      stopwatch.stop();
      verify();
      if (batch >= warmups) {
        samples.add(stopwatch.elapsedTicks *
            1000000 /
            stopwatch.frequency /
            operationsPerBatch);
      }
    } finally {
      await cleanup();
    }
  }
  return BenchResult(
    name: name,
    iterations: operationsPerBatch,
    rounds: measured,
    samples: samples,
    totalOperations: (warmups + measured) * operationsPerBatch,
    warmupOperations: warmups * operationsPerBatch,
    configuration: {
      'preparedBatches': 1,
      'operationsPerBatch': operationsPerBatch,
      'rounds': measured,
      'warmupBatches': warmups,
    },
  );
}

void printBenchTable(String title, List<BenchResult> results) {
  print('\n$title — batch means in µs/op (not operation latency percentiles)');
  print('| Scenario | Median | MAD | Min | Max |');
  for (final result in results) {
    print('| ${result.name} | ${result.medianBatchUs.toStringAsFixed(4)} | '
        '${result.madBatchUs.toStringAsFixed(4)} | '
        '${result.minBatchUs.toStringAsFixed(4)} | '
        '${result.maxBatchUs.toStringAsFixed(4)} |');
    print('SINT_BENCH_JSON ${jsonEncode(result.toJson())}');
  }
}
