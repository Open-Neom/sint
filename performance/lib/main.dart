import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sint/sint.dart';

const autorun = bool.fromEnvironment('SINT_BENCH_AUTORUN');
const measuredFrames = int.fromEnvironment(
  'SINT_BENCH_FRAMES',
  defaultValue: 180,
);
const warmupFrames = int.fromEnvironment('SINT_BENCH_WARMUP', defaultValue: 60);
const listeners = int.fromEnvironment(
  'SINT_BENCH_LISTENERS',
  defaultValue: 100,
);
const updatesPerFrame = int.fromEnvironment(
  'SINT_BENCH_UPDATES',
  defaultValue: 10,
);

void main() {
  if (measuredFrames < 1 ||
      warmupFrames < 1 ||
      listeners < 1 ||
      updatesPerFrame < 1) {
    throw ArgumentError('Benchmark counts must all be positive');
  }
  runApp(const PerformanceApp());
}

class PerformanceApp extends StatefulWidget {
  const PerformanceApp({super.key});
  @override
  State<PerformanceApp> createState() => _PerformanceAppState();
}

class _PerformanceAppState extends State<PerformanceApp> {
  final _rx = 0.obs;
  final _native = ValueNotifier<int>(0);
  final _timings = <FrameTiming>[];
  String _mode = 'rx';
  String _status = 'Ready';
  bool _running = false;
  bool _recording = false;
  int _rebuilds = 0;
  Map<String, Object?>? _report;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_recordTimings);
    if (autorun) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _run();
      });
    }
  }

  void _recordTimings(List<FrameTiming> frames) {
    if (_recording) _timings.addAll(frames);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_recordTimings);
    _rx.close();
    _native.dispose();
    super.dispose();
  }

  void _update() {
    for (var i = 0; i < updatesPerFrame; i++) {
      if (_mode == 'rx') {
        _rx.value++;
      } else {
        _native.value++;
      }
    }
  }

  Future<Map<String, Object?>> _measure(String mode) async {
    setState(() {
      _mode = mode;
      _status = 'Measuring $mode ($measuredFrames frames)';
    });
    await SchedulerBinding.instance.endOfFrame;
    for (var i = 0; i < warmupFrames; i++) {
      _update();
      await SchedulerBinding.instance.endOfFrame;
    }
    // Timing callbacks arrive in batches after rasterization.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _timings.clear();
    _recording = true;
    _rebuilds = 0;
    final rssBefore = ProcessInfo.currentRss;
    var firstVsync = 0;
    var lastVsync = 0;
    final startValue = mode == 'rx' ? _rx.value : _native.value;
    for (var i = 0; i < measuredFrames; i++) {
      _update();
      await SchedulerBinding.instance.endOfFrame;
      final vsync =
          SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
      if (i == 0) firstVsync = vsync;
      lastVsync = vsync;
    }
    final measuredRebuilds = _rebuilds;
    final endValue = mode == 'rx' ? _rx.value : _native.value;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _recording = false;
    final frames = _timings.where((frame) {
      final vsync = frame.timestampInMicroseconds(FramePhase.vsyncStart);
      return vsync >= firstVsync && vsync <= lastVsync;
    }).toList();
    final buildSamples = frames
        .map((frame) => frame.buildDuration.inMicroseconds)
        .toList();
    final rasterSamples = frames
        .map((frame) => frame.rasterDuration.inMicroseconds)
        .toList();
    double percentile(List<int> samples, double fraction) {
      if (samples.isEmpty) return 0;
      final sorted = [...samples]..sort();
      final index = (fraction * sorted.length).ceil() - 1;
      return sorted[index.clamp(0, sorted.length - 1)].toDouble();
    }

    return {
      'scenario': mode == 'rx' ? 'Obx' : 'ValueListenableBuilder',
      'valid':
          endValue - startValue == measuredFrames * updatesPerFrame &&
          measuredRebuilds == measuredFrames * listeners &&
          frames.length == measuredFrames,
      'deliveredValueChanges': endValue - startValue,
      'expectedValueChanges': measuredFrames * updatesPerFrame,
      'rebuilds': measuredRebuilds,
      'expectedRebuilds': measuredFrames * listeners,
      'reportedFrames': frames.length,
      'expectedFrames': measuredFrames,
      'buildMicroseconds': buildSamples,
      'rasterMicroseconds': rasterSamples,
      'buildP50Microseconds': percentile(buildSamples, 0.50),
      'buildP95Microseconds': percentile(buildSamples, 0.95),
      'rasterP95Microseconds': percentile(rasterSamples, 0.95),
      'rssBeforeBytes': rssBefore,
      'rssAfterBytes': ProcessInfo.currentRss,
      'rssMeaning':
          'Process resident memory including engine/assets/caches, not Dart heap or proof of a leak',
    };
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
    });
    try {
      // ABBA order exposes order effects; raw samples from each run are retained.
      final results = <Map<String, Object?>>[];
      for (final mode in ['rx', 'native', 'native', 'rx']) {
        results.add(await _measure(mode));
      }
      final report = <String, Object?>{
        'schemaVersion': 1,
        'kind': 'flutter_frame_timings',
        'valid':
            !kDebugMode && results.every((result) => result['valid'] == true),
        'mode': kReleaseMode
            ? 'release'
            : kProfileMode
            ? 'profile'
            : 'debug',
        'dartVersion': Platform.version,
        'operatingSystem': Platform.operatingSystem,
        'operatingSystemVersion': Platform.operatingSystemVersion,
        'revision': const String.fromEnvironment(
          'SINT_BENCH_REVISION',
          defaultValue: 'unrecorded',
        ),
        'measuredFrames': measuredFrames,
        'warmupFrames': warmupFrames,
        'listeners': listeners,
        'updatesPerFrame': updatesPerFrame,
        'order': 'ABBA',
        'results': results,
        'finishedAtUtc': DateTime.now().toUtc().toIso8601String(),
      };
      const output = String.fromEnvironment('SINT_BENCH_OUTPUT');
      if (output.isNotEmpty) {
        try {
          final file = File(output);
          await file.parent.create(recursive: true);
          await file.writeAsString(
            const JsonEncoder.withIndent('  ').convert(report),
          );
        } on FileSystemException catch (error) {
          // Stdout remains the primary transport when the macOS application
          // sandbox cannot access a requested output path.
          report['outputFileError'] = error.toString();
          stderr.writeln(
            'Could not write $output; full JSON follows on stdout.',
          );
        }
      }
      stdout.writeln('SINT_FRAME_BENCH_JSON ${jsonEncode(report)}');
      stdout.writeln('SINT_FRAME_BENCH_DONE valid=${report['valid']}');
      await stdout.flush();
      if (autorun) exit(report['valid'] == true ? 0 : 1);
      setState(() {
        _report = report;
        _running = false;
        _status = report['valid'] == true
            ? 'Complete — output written to stdout'
            : 'Invalid measurement — inspect counts/mode in stdout';
      });
    } on Object catch (error, stack) {
      stderr.writeln('$error\n$stack');
      if (autorun) exit(1);
      setState(() {
        _status = 'Failed: $error';
        _running = false;
      });
    }
  }

  Widget _tile(int value) {
    _rebuilds++;
    return SizedBox(width: 65, height: 28, child: Text('$value'));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('SINT performance lab')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _running ? null : _run,
              child: const Text(
                'Run matched Obx / ValueListenableBuilder workload',
              ),
            ),
            Text(
              '$listeners widgets · $updatesPerFrame changes/frame · $measuredFrames measured frames',
            ),
            if (kDebugMode)
              const Text(
                'Debug mode: timings are diagnostic and marked invalid.',
              ),
            const SizedBox(height: 16),
            Wrap(
              children: List.generate(
                listeners,
                (index) => _mode == 'rx'
                    ? Obx(() => _tile(_rx.value))
                    : ValueListenableBuilder<int>(
                        valueListenable: _native,
                        builder: (_, value, child) => _tile(value),
                      ),
              ),
            ),
            if (_report != null)
              Text('Valid: ${_report!['valid']} · raw results in console'),
          ],
        ),
      ),
    ),
  );
}
