import 'package:sint/injection/src/lifecycle.dart';

import 'list_notifier.dart';

/// A base controller class that provides state management functionality.
///
/// Extend this class to create a controller that can be used with SINT's
/// state management system. This class provides methods to update the UI
/// when the controller's state changes.
///
/// Example:
/// ```dart
/// class CounterController extends SintController {
///   var count = 0;
///
///   void increment() {
///     count++;
///     update(); // Triggers UI update
///   }
/// }
abstract class SintController extends ListNotifier with SintLifeCycleMixin {
  /// Notifies listeners to update the UI.
  ///
  /// When called without parameters, it will update all ui that depend on
  /// this controller. You can also specify specific widget IDs to update only
  /// those ui.
  ///
  /// Parameters:
  /// - [ids]: Optional list of widget IDs to update. If null, updates all ui.
  /// - [condition]: If false, the update will be skipped.
  ///
  void update([List<Object>? ids, bool condition = true]) {
    if (!condition) {
      return;
    }
    if (ids == null) {
      refresh();
    } else {
      for (final id in ids) {
        refreshGroup(id);
      }
    }
  }

}
