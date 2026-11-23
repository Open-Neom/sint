import 'dart:async';

import 'package:sint/core/src/sint_queue.dart';
import 'package:sint/navigation/src/ui/snackbar/snackbar_controller.dart';

class SnackBarQueue {
  final _queue = SintQueue();
  final _snackbarList = <SnackbarController>[];

  SnackbarController? get _currentSnackbar {
    if (_snackbarList.isEmpty) return null;
    return _snackbarList.first;
  }

  bool get isJobInProgress => _snackbarList.isNotEmpty;

  Future<void> addJob(SnackbarController job) async {
    _snackbarList.add(job);
    try {
      final data = await _queue.add(job.showOverlay);
      _snackbarList.remove(job);
      return data;
    } on StateError {
      // The job was cancelled via cancelAllJobs() before it ran.
      // Cancellation is a normal control flow, not an error to surface.
      _snackbarList.remove(job);
    }
  }

  Future<void> cancelAllJobs() async {
    final current = _currentSnackbar;
    _queue.cancelAllJobs();
    _snackbarList.clear();
    await current?.close();
  }

  void disposeControllers() {
    final current = _currentSnackbar;
    if (current != null) {
      current.removeOverlay();
      _snackbarList.remove(current);
    }

    _queue.cancelAllJobs();

    for (final element in List<SnackbarController>.from(_snackbarList)) {
      element.removeOverlay();
    }
    _snackbarList.clear();
  }

  Future<void> closeCurrentJob() async {
    if (_currentSnackbar == null) return;
    await _currentSnackbar!.close();
  }
}
