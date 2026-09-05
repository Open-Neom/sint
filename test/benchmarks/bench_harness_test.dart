import 'package:flutter_test/flutter_test.dart';
import 'bench_harness.dart';

void main() {
  test('prepared batches validate each delivery and clean up even on failure',
      () async {
    final steps = <String>[];
    final result = await runPreparedBench('prepared',
        operationsPerBatch: 4, rounds: 2, warmupBatches: 1, prepare: () async {
      steps.add('prepare');
    }, body: () {
      steps.add('body');
      return Future.value();
    }, verify: () {
      steps.add('verify');
    }, cleanup: () async {
      steps.add('cleanup');
    });
    expect(result.totalOperations, 12);
    expect(result.samples.length, 2);
    expect(steps, [
      for (var i = 0; i < 3; i++) ...['prepare', 'body', 'verify', 'cleanup']
    ]);
    var cleaned = false;
    await expectLater(
        runPreparedBench('throws',
            operationsPerBatch: 1,
            rounds: 1,
            warmupBatches: 0,
            prepare: () async {},
            body: () {
              throw StateError('failure');
            },
            verify: () {},
            cleanup: () async {
              cleaned = true;
            }),
        throwsStateError);
    expect(cleaned, isTrue);
  });

  test('batch statistics preserve samples and handle an even median', () {
    final result = BenchResult(
        name: 'sample',
        iterations: 1,
        rounds: 4,
        samples: [100, 1, 3, 2],
        totalOperations: 4,
        warmupOperations: 0,
        configuration: {});
    expect(result.samples, [100, 1, 3, 2]);
    expect(result.medianBatchUs, 2.5);
    expect(result.madBatchUs, 1);
    expect(result.toJson()['metric'], 'batch_mean_us_per_operation');
    expect(result.toJson().containsKey('p95'), isFalse);
  });

  test('operation accounting includes warmup and each measured batch',
      () async {
    var operations = 0;
    final result = await runBench('count', () {
      operations++;
    },
        warmup: 3,
        iterations: 5,
        rounds: 4,
        warmupDuration: Duration.zero,
        minimumBatchDuration: Duration.zero);
    expect(operations, 23);
    expect(result.totalOperations, operations);
    expect(result.samples.length, 4);
    expect(result.warmupOperations, 3);
  });

  test('invalid measurement configuration is rejected', () {
    expect(runBench('bad', () {}, iterations: 0), throwsArgumentError);
    expect(
        () => BenchResult(
            name: 'bad',
            iterations: 1,
            rounds: 0,
            samples: [],
            totalOperations: 0,
            warmupOperations: 0,
            configuration: {}),
        throwsArgumentError);
  });
}
