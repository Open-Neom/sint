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
    await _currentSnackbar?.close();
    _queue.cancelAllJobs();
    _snackbarList.clear();
  }

  void disposeControllers() {
    if (_currentSnackbar != null) {
      _currentSnackbar?.removeOverlay();
      _currentSnackbar?.controller.dispose();
      _snackbarList.remove(_currentSnackbar);
    }

    _queue.cancelAllJobs();

    for (var element in _snackbarList) {
      element.controller.dispose();
    }
    _snackbarList.clear();
  }

  Future<void> closeCurrentJob() async {
    if (_currentSnackbar == null) return;
    await _currentSnackbar!.close();
  }
}