// SintQueue regression tests (1.3.1 hotfixes):
// a) A job throwing an Error (not just Exception) must not freeze the queue.
// b) cancelAllJobs() must complete pending futures instead of leaving
//    them hanging forever.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sint/core/src/sint_queue.dart';

void main() {
  group('SintQueue (regression 1.3.1)', () {
    test('a job throwing an Error does not freeze the queue', () async {
      final queue = SintQueue();

      final first = queue.add<int>(() => throw TypeError());
      await expectLater(first, throwsA(isA<TypeError>()));

      // With the old `on Exception catch`, the queue froze here forever.
      final second = await queue
          .add(() => 42)
          .timeout(const Duration(seconds: 2));
      expect(second, 42);
    });

    test('a job throwing an Exception still completes with error', () async {
      final queue = SintQueue();

      await expectLater(
        queue.add(() => throw Exception('boom')),
        throwsException,
      );

      final second =
          await queue.add(() => 'ok').timeout(const Duration(seconds: 2));
      expect(second, 'ok');
    });

    test('cancelAllJobs completes pending futures with StateError', () async {
      final queue = SintQueue();

      // Occupy the queue with an active job gated on a completer.
      final gate = Completer<void>();
      final active = queue.add(() => gate.future);

      final pending1 = queue.add(() => 1);
      final pending2 = queue.add(() => 2);

      queue.cancelAllJobs();

      await expectLater(
        pending1.timeout(const Duration(seconds: 2)),
        throwsStateError,
      );
      await expectLater(
        pending2.timeout(const Duration(seconds: 2)),
        throwsStateError,
      );

      // The already-active job is untouched and completes normally.
      gate.complete();
      await active.timeout(const Duration(seconds: 2));
    });
  });
}
