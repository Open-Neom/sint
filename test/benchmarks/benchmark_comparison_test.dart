import 'package:flutter_test/flutter_test.dart';
import '../../tool/compare_benchmarks.dart';

Map<String, dynamic> report(List<double> samples, {String machine = 'same'}) =>
    {
      'schemaVersion': 2,
      'valid': true,
      'metadata': {
        for (final key in comparableMetadata)
          key: key == 'machineId' ? machine : 'fixed'
      },
      'results': [
        {
          'name': 'work',
          'metric': 'batch_mean_us_per_operation',
          'configuration': {'rounds': 7},
          'samples': samples,
        }
      ],
    };

void main() {
  test('regression needs to exceed chosen budget and observed noise', () {
    final baseline = report([1, 1, 1, 1, 1, 1, 1]);
    expect(
        compareReports(baseline, report([2, 2, 2, 2, 2, 2, 2]),
            regressionBudget: 0.05)['regressions'],
        1);
    expect(
        compareReports(
            baseline, report([1.01, 1.01, 1.01, 1.01, 1.01, 1.01, 1.01]),
            regressionBudget: 0.05)['regressions'],
        0);
    expect(
        compareReports(report([0.5, 0.7, 0.8, 1, 1.2, 1.3, 1.5]),
            report([0.6, 0.8, 1, 1.1, 1.3, 1.4, 1.6]),
            regressionBudget: 0.05)['regressions'],
        0);
  });

  test('cross-machine and incomplete reports are rejected', () {
    final baseline = report([1, 1, 1]);
    expect(
        () => compareReports(baseline, report([1, 1, 1], machine: 'other'),
            regressionBudget: 0.05),
        throwsArgumentError);
    expect(
        () => compareReports(baseline, report([1, 1, 1])..['valid'] = false,
            regressionBudget: 0.05),
        throwsArgumentError);
    expect(
        () => compareReports(baseline, report([1, 1, 1])..['results'] = [],
            regressionBudget: 0.05),
        throwsArgumentError);
  });
}
