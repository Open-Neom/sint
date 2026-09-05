import 'dart:convert';
import 'dart:io';

const benchmarkFiles = [
  'test/benchmarks/p0_benchmark_test.dart',
  'test/benchmarks/route_benchmark_test.dart',
  'test/benchmarks/infrastructure_benchmark_test.dart',
  'test/benchmarks/lifecycle_delivery_benchmark_test.dart',
];

// One checked result per timed test; update this when extending the matrix.
const expectedScenarioCount = 41;

Future<String> command(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw StateError('$executable $arguments\n${result.stderr}');
  }
  return (result.stdout as String).trim();
}

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln(
        'dart run tool/benchmark_runner.dart [--full] [--output=build/benchmarks/run.json] [--machine-id=NAME]\n'
        'Runs serial flutter-test JIT batches, without coverage. --full increases warmup/round duration.\n'
        'Run baseline and candidate on the same idle host/SDK; repeat in alternating order.');
    return;
  }
  String option(String name, String fallback) => arguments
      .firstWhere((arg) => arg.startsWith('$name='),
          orElse: () => '$name=$fallback')
      .substring(name.length + 1);
  final outputPath = option('--output', 'build/benchmarks/run.json');
  final full = arguments.contains('--full');
  final flutter =
      jsonDecode(await command('flutter', ['--version', '--machine']));
  final manifest = <String, String>{};
  for (final file in [
    'test/benchmarks/bench_harness.dart',
    ...benchmarkFiles
  ]) {
    manifest[file] = await command('git', ['hash-object', file]);
  }
  String revision;
  String changes;
  try {
    revision = await command('git', ['rev-parse', 'HEAD']);
    changes = await command('git', ['status', '--porcelain']);
  } catch (_) {
    revision = 'unavailable';
    changes = 'unavailable';
  }
  final metadata = {
    'machineId': option('--machine-id', Platform.localHostname),
    'operatingSystem': Platform.operatingSystem,
    'operatingSystemVersion': Platform.operatingSystemVersion,
    'processors': Platform.numberOfProcessors,
    'dartVersion': Platform.version,
    'flutterRevision': flutter['frameworkRevision'],
    'flutterVersion': flutter['frameworkVersion'],
    'engineRevision': flutter['engineRevision'],
    'mode': 'flutter_test_vm_jit_no_coverage',
    'full': full,
    'harnessManifest': manifest,
    'gitCommit': revision,
    'gitStatus': changes,
    'startedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'command': [
      'flutter',
      'test',
      '--no-pub',
      '--machine',
      '--concurrency=1',
      ...benchmarkFiles
    ],
  };
  final file = File(outputPath);
  await file.parent.create(recursive: true);
  final log = File('$outputPath.log').openWrite();
  final results = <Map<String, dynamic>>[];
  final process = await Process.start('flutter',
      ['test', '--no-pub', '--machine', '--concurrency=1', ...benchmarkFiles],
      environment: {'SINT_BENCH_FULL': full.toString()});
  final stderrDone = process.stderr.transform(utf8.decoder).forEach((line) {
    log.write(line);
    stderr.write(line);
  });
  await for (final line in process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())) {
    log.writeln(line);
    try {
      final event = jsonDecode(line);
      final message = event is Map ? event['message'] : null;
      if (message is String && message.startsWith('SINT_BENCH_JSON ')) {
        final result =
            Map<String, dynamic>.from(jsonDecode(message.substring(16)));
        results.add(result);
        stdout.writeln(
            '${result['name']}: ${result['medianBatchUs']} batch-mean µs/op');
      } else if (event is Map && event['type'] == 'error') {
        stderr.writeln(event['error']);
      }
    } on FormatException {
      // Flutter may emit initialization status outside the test JSON protocol.
    }
  }
  final testExitCode = await process.exitCode;
  await stderrDone;
  await log.close();
  final valid = testExitCode == 0 &&
      results.length == expectedScenarioCount &&
      results.map((result) => result['name']).toSet().length == results.length;
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 2,
    'valid': valid,
    'metadata': metadata,
    'results': results,
    'finishedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'testExitCode': testExitCode,
  }));
  stdout.writeln('Saved $outputPath and $outputPath.log. Valid: $valid');
  if (!valid) exitCode = 1;
}
