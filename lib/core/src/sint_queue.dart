import 'dart:async';

class SintQueue {
  final List<_Item> _queue = [];
  bool _active = false;

  Future<T> add<T>(Function job) {
    var completer = Completer<T>();
    _queue.add(_Item(completer, job));
    _check();
    return completer.future;
  }

  void cancelAllJobs() {
    for (final item in _queue) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(StateError('Job cancelled'));
      }
    }
    _queue.clear();
  }

  Future<void> _check() async {
    if (_active) return;
    _active = true;
    try {
      while (_queue.isNotEmpty) {
        final item = _queue.removeAt(0);
        if (item.completer.isCompleted) continue;
        try {
          final result = await item.job();
          if (!item.completer.isCompleted) {
            item.completer.complete(result);
          }
        } catch (e, st) {
          // Catch everything (Exception AND Error, e.g. TypeError) so the
          // queue never freezes and the completer always completes.
          if (!item.completer.isCompleted) {
            item.completer.completeError(e, st);
          }
        }
      }
    } finally {
      _active = false;
    }
  }
}

class _Item {
  final dynamic completer;
  final dynamic job;

  _Item(this.completer, this.job);
}
