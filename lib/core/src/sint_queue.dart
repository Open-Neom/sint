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
      item.completer.completeError(StateError('Job cancelled'));
    }
    _queue.clear();
  }

  void _check() async {
    if (!_active && _queue.isNotEmpty) {
      _active = true;
      var item = _queue.removeAt(0);
      try {
        item.completer.complete(await item.job());
      } catch (e) {
        // Catch everything (Exception AND Error, e.g. TypeError) so the
        // queue never freezes and the completer always completes.
        item.completer.completeError(e);
      } finally {
        _active = false;
      }
      _check();
    }
  }
}

class _Item {
  final dynamic completer;
  final dynamic job;

  _Item(this.completer, this.job);
}
