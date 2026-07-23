// SINT v1.4.0 - Reusable benchmark harness
// Methodology: JIT warmup, N rounds, median + p95 statistics.
// ignore_for_file: avoid_print

/// Result of a single benchmark run.
class BenchResult {
  BenchResult({
    required this.name,
    required this.iterations,
    required this.rounds,
    required this.samples,
  });

  final String name;
  final int iterations;
  final int rounds;

  /// µs/op per round, sorted ascending.
  final List<double> samples;

  double get medianUs => _percentile(0.50);
  double get p95Us => _percentile(0.95);
  double get minUs => samples.first;
  double get maxUs => samples.last;

  double _percentile(double p) {
    if (samples.length == 1) return samples.first;
    final idx = (p * (samples.length - 1)).ceil();
    return samples[idx];
  }

  String get row =>
      '| ${name.padRight(38)} | ${medianUs.toStringAsFixed(4).padLeft(10)} | '
      '${p95Us.toStringAsFixed(4).padLeft(10)} | '
      '${minUs.toStringAsFixed(4).padLeft(10)} | '
      '${maxUs.toStringAsFixed(4).padLeft(10)} |';
}

/// Runs [body] with JIT warmup, then [rounds] timed rounds of
/// [iterations] operations each. Reports median and p95 µs/op.
Future<BenchResult> runBench(String name, void Function() body,
    {int warmup = 2000, int iterations = 20000, int rounds = 7}) async {
  // Warmup: get the JIT hot before measuring.
  for (var i = 0; i < warmup; i++) {
    body();
  }

  final samples = <double>[];
  final sw = Stopwatch();
  for (var r = 0; r < rounds; r++) {
    sw
      ..reset()
      ..start();
    for (var i = 0; i < iterations; i++) {
      body();
    }
    sw.stop();
    samples.add(sw.elapsedMicroseconds / iterations);
  }
  samples.sort();

  return BenchResult(
    name: name,
    iterations: iterations,
    rounds: rounds,
    samples: samples,
  );
}

/// Prints a legible table of benchmark results.
void printBenchTable(String title, List<BenchResult> results) {
  print('\n${'=' * 86}');
  print(title);
  print('=' * 86);
  print('| ${'Benchmark'.padRight(38)} | '
      '${'median us/op'.padLeft(10)} | ${'p95 us/op'.padLeft(10)} | '
      '${'min us/op'.padLeft(10)} | ${'max us/op'.padLeft(10)} |');
  print('|${'-' * 40}|${'-' * 12}|${'-' * 12}|${'-' * 12}|${'-' * 12}|');
  for (final r in results) {
    print(r.row);
  }
  print('');
}
