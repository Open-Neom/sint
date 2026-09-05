import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const comparableMetadata = [
  'machineId',
  'operatingSystem',
  'operatingSystemVersion',
  'processors',
  'dartVersion',
  'flutterRevision',
  'engineRevision',
  'mode',
  'full',
  'harnessManifest',
];

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final index = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[index]
      : (sorted[index - 1] + sorted[index]) / 2;
}

/// A conservative MAD-based noise envelope, not a statistical confidence test.
/// A caller must choose a practical regression budget for this workload.
Map<String, dynamic> compareReports(
  Map<String, dynamic> baseline,
  Map<String, dynamic> candidate, {
  required double regressionBudget,
  double noiseMultiplier = 3,
}) {
  if (!regressionBudget.isFinite ||
      regressionBudget < 0 ||
      !noiseMultiplier.isFinite ||
      noiseMultiplier < 0) {
    throw ArgumentError(
        'Budget/noise multiplier must be finite and non-negative');
  }
  for (final report in [baseline, candidate]) {
    if (report['schemaVersion'] != 2 || report['valid'] != true) {
      throw ArgumentError(
          'Only complete, valid schema-2 reports can be compared');
    }
  }
  for (final key in comparableMetadata) {
    final before = (baseline['metadata'] as Map)[key];
    final after = (candidate['metadata'] as Map)[key];
    if (before == null ||
        after == null ||
        jsonEncode(before) != jsonEncode(after)) {
      throw ArgumentError('Incomparable environment/harness: $key');
    }
  }
  Map<String, Map<String, dynamic>> scenarios(Map<String, dynamic> report) {
    final result = <String, Map<String, dynamic>>{};
    for (final raw in report['results'] as List) {
      final value = Map<String, dynamic>.from(raw as Map);
      final name = value['name'] as String;
      if (result.containsKey(name)) {
        throw ArgumentError('Duplicate scenario: $name');
      }
      result[name] = value;
    }
    return result;
  }

  final before = scenarios(baseline);
  final after = scenarios(candidate);
  if (before.isEmpty ||
      before.length != after.length ||
      !before.keys.every(after.containsKey)) {
    throw ArgumentError('Scenario sets differ; no silent partial comparison');
  }
  final rows = <Map<String, dynamic>>[];
  for (final name in before.keys) {
    final a = before[name]!;
    final b = after[name]!;
    if (a['metric'] != 'batch_mean_us_per_operation' ||
        b['metric'] != a['metric'] ||
        jsonEncode(a['configuration']) != jsonEncode(b['configuration'])) {
      throw ArgumentError('Incomparable configuration: $name');
    }
    List<double> samples(Map<String, dynamic> entry) {
      final values =
          (entry['samples'] as List).map((v) => (v as num).toDouble()).toList();
      if (values.length < 3 || values.any((v) => !v.isFinite || v < 0)) {
        throw ArgumentError('Insufficient/invalid samples for $name');
      }
      return values;
    }

    final aSamples = samples(a);
    final bSamples = samples(b);
    final aMedian = _median(aSamples);
    final bMedian = _median(bSamples);
    if (aMedian <= 0 || bMedian <= 0) {
      throw ArgumentError('Timer resolution insufficient for $name');
    }
    final aMad = _median(aSamples.map((v) => (v - aMedian).abs()).toList());
    final bMad = _median(bSamples.map((v) => (v - bMedian).abs()).toList());
    final noiseFraction = noiseMultiplier * (aMad + bMad) / aMedian;
    final delta = bMedian / aMedian - 1;
    final effectiveBudget = math.max(regressionBudget, noiseFraction);
    rows.add({
      'name': name,
      'baselineMedianBatchUs': aMedian,
      'candidateMedianBatchUs': bMedian,
      'relativeChange': delta,
      'noiseEnvelopeFraction': noiseFraction,
      'requestedBudgetFraction': regressionBudget,
      'effectiveBudgetFraction': effectiveBudget,
      'status': delta > effectiveBudget
          ? 'regression'
          : delta < -effectiveBudget
              ? 'improvement'
              : 'within_budget_or_noise',
    });
  }
  return {
    'method':
        'median batch means; max(user budget, MAD noise envelope), not a confidence interval',
    'rows': rows,
    'regressions': rows.where((row) => row['status'] == 'regression').length,
  };
}

Future<void> main(List<String> arguments) async {
  if (arguments.length < 3 || arguments.contains('--help')) {
    stdout.writeln(
        'dart run tool/compare_benchmarks.dart BEFORE.json AFTER.json --budget=FRACTION [--noise-multiplier=3] [--fail-on-regression]\n'
        'Budget must be chosen explicitly. Same host, SDK, harness and workloads are required.\n'
        'Example --budget=0.05 expresses a project-selected 5% budget, not a universal threshold.');
    if (!arguments.contains('--help')) exitCode = 64;
    return;
  }
  try {
    final budgetOption =
        arguments.firstWhere((arg) => arg.startsWith('--budget='));
    final noise = arguments.firstWhere(
        (arg) => arg.startsWith('--noise-multiplier='),
        orElse: () => '--noise-multiplier=3');
    final report = compareReports(
      jsonDecode(await File(arguments[0]).readAsString()),
      jsonDecode(await File(arguments[1]).readAsString()),
      regressionBudget: double.parse(budgetOption.split('=').last),
      noiseMultiplier: double.parse(noise.split('=').last),
    );
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
    if (arguments.contains('--fail-on-regression') &&
        report['regressions'] != 0) {
      exitCode = 1;
    }
  } on Object catch (error) {
    stderr.writeln('Comparison refused: $error');
    exitCode = 2;
  }
}
