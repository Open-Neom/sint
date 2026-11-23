import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sint/core/src/domain/interfaces/sint_interface.dart';
import 'package:sint/core/src/sint_main.dart';
import 'package:sint/injection/src/domain/extensions/injection_extension.dart';
import 'package:sint/navigation/src/domain/extensions/navigation_extensions.dart';
import 'package:sint/navigation/src/ui/sint_root.dart';
import 'package:sint/state_manager/src/engine/list_notifier.dart';
import 'package:sint/translation/src/domain/extensions/locale_extension.dart';

/// Lightweight runtime diagnostics & Dart VM Service Extension inspector for
/// all four SINT pillars (`S · I · N · T`).
///
/// Designed for zero overhead in production:
/// - Rebuild telemetry is off by default (`isRebuildTrackingEnabled == false`).
/// - VM Service Extensions (`ext.sint.*`) are registered only in debug/profile
///   builds (`!kReleaseMode`) so Flutter DevTools or custom inspectors can
///   query live DI bindings, routes, translations, and `Obx`/`ObxSelect`
///   rebuild hot-spots without extra package dependencies.
class SintDiagnostics {
  SintDiagnostics._();

  static final SintDiagnostics instance = SintDiagnostics._();

  static bool _serviceExtensionsRegistered = false;

  final Map<String, int> _rebuildCounts = <String, int>{};
  int _totalRebuilds = 0;

  /// Enables or disables live `Obx` / `ObxSelect` rebuild telemetry.
  bool enableRebuildTracking = false;

  /// Optional external listener invoked whenever an `Obx` / `ObxSelect` widget
  /// rebuilds (e.g., to feed `sint_sentinel`'s `StateWatchdog` or custom
  /// performance monitors without coupling `sint` to external packages).
  void Function(String label, int rebuildCount)? onRebuild;

  /// Fast `O(1)` flag checked on the `Obx` / `ObxSelect` build hot path.
  @pragma('vm:prefer-inline')
  static bool get isRebuildTrackingEnabled =>
      instance.enableRebuildTracking || instance.onRebuild != null;

  /// Total `Obx` / `ObxSelect` builds recorded since tracking was enabled or
  /// last reset.
  int get totalRebuilds => _totalRebuilds;

  /// Records a single build for a reactive widget identified by [label].
  void recordRebuild(String label) {
    final hook = onRebuild;
    if (!enableRebuildTracking && hook == null) return;
    _totalRebuilds++;
    final count = (_rebuildCounts[label] ?? 0) + 1;
    _rebuildCounts[label] = count;
    hook?.call(label, count);
  }

  /// Returns an unmodifiable map of widget labels to rebuild counts, ordered
  /// descending by rebuild frequency so hot-spots appear first.
  Map<String, int> rebuildStats() {
    if (_rebuildCounts.isEmpty) return const <String, int>{};
    final entries = _rebuildCounts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        return cmp != 0 ? cmp : a.key.compareTo(b.key);
      });
    return Map<String, int>.unmodifiable(<String, int>{
      for (final e in entries) e.key: e.value,
    });
  }

  /// Clears accumulated rebuild counters while preserving
  /// [enableRebuildTracking].
  void resetRebuildStats() {
    _rebuildCounts.clear();
    _totalRebuilds = 0;
  }

  /// Resets all diagnostic state (invoked by `Sint.reset()`).
  void reset() {
    enableRebuildTracking = false;
    onRebuild = null;
    resetRebuildStats();
  }

  /// Returns a JSON-serializable snapshot of Pillar S (State) runtime metrics.
  Map<String, Object?> stateSnapshot() => <String, Object?>{
    'rebuildTrackingEnabled': enableRebuildTracking,
    'totalRebuilds': _totalRebuilds,
    'isBatching': ListNotifier.isBatching,
    'isFrameBatching': ListNotifier.isFrameBatching,
    'hasPendingFrameBatch': ListNotifier.hasPendingFrameBatch,
    'rebuildsByLabel': rebuildStats(),
  };

  /// Returns a JSON-serializable snapshot of Pillar I (Dependency Injection).
  Map<String, Object?> dependenciesSnapshot() {
    final entries = InjectionExtension.debugDescribeDependencies();
    return <String, Object?>{
      'count': entries.length,
      'activeScopes': InjectionExtension.activeScopeCount,
      'dependencies': entries,
    };
  }

  /// Returns a JSON-serializable snapshot of Pillar N (Navigation & Overlays).
  Map<String, Object?> routesSnapshot() {
    if (!SintRoot.treeInitialized) {
      return <String, Object?>{
        'treeInitialized': false,
        'currentRoute': '',
        'previousRoute': '',
        'canBack': false,
        'canPop': Sint.canPop,
        'isDialogOpen': false,
        'isBottomSheetOpen': false,
        'isSnackbarOpen': Sint.isSnackbarOpen,
        'activePages': const <String>[],
      };
    }
    final delegate = SintRootState.controller.rootDelegate;
    final activePages = delegate.activePages
        .map((p) => p.route?.name ?? p.pageSettings?.name ?? '')
        .toList(growable: false);
    return <String, Object?>{
      'treeInitialized': true,
      'currentRoute': Sint.currentRoute,
      'previousRoute': Sint.previousRoute,
      'canBack': Sint.canBack,
      'canPop': Sint.canPop,
      'isDialogOpen': Sint.isDialogOpen ?? false,
      'isBottomSheetOpen': Sint.isBottomSheetOpen ?? false,
      'isSnackbarOpen': Sint.isSnackbarOpen,
      'activePages': activePages,
    };
  }

  /// Returns a JSON-serializable snapshot of Pillar T (Translation).
  Map<String, Object?> localizationSnapshot() {
    final host = LocalesIntl.host;
    final sizes = <String, int>{
      for (final entry in host.translations.entries)
        entry.key: entry.value.length,
    };
    return <String, Object?>{
      'locale': host.peekLocale?.toString(),
      'fallbackLocale': host.peekFallbackLocale?.toString(),
      'loadedLocales': host.loadedLocales.toList(growable: false),
      'lazyLoaderLocales': host.lazyLoaders.keys.toList(growable: false),
      'dictionarySizes': sizes,
    };
  }

  /// Returns a unified JSON-serializable snapshot of all four SINT pillars.
  Map<String, Object?> snapshot() => <String, Object?>{
    'state': stateSnapshot(),
    'injection': dependenciesSnapshot(),
    'navigation': routesSnapshot(),
    'translation': localizationSnapshot(),
  };

  /// Registers Dart VM Service Extensions (`ext.sint.*`) once in debug/profile
  /// mode so Flutter DevTools and external inspectors can query live state.
  void registerServiceExtensions() {
    if (kReleaseMode || _serviceExtensionsRegistered) return;
    _serviceExtensionsRegistered = true;

    void safeRegister(
      String method,
      Future<developer.ServiceExtensionResponse> Function(
        String,
        Map<String, String>,
      )
      handler,
    ) {
      try {
        developer.registerExtension(method, handler);
      } on Object {
        // Ignore on platforms/environments where VM service extensions are
        // unavailable or already registered across hot restarts.
      }
    }

    safeRegister('ext.sint.getSnapshot', (_, _) async {
      return developer.ServiceExtensionResponse.result(jsonEncode(snapshot()));
    });

    safeRegister('ext.sint.getDependencies', (_, _) async {
      return developer.ServiceExtensionResponse.result(
        jsonEncode(dependenciesSnapshot()),
      );
    });

    safeRegister('ext.sint.getRoutes', (_, _) async {
      return developer.ServiceExtensionResponse.result(
        jsonEncode(routesSnapshot()),
      );
    });

    safeRegister('ext.sint.getLocalization', (_, _) async {
      return developer.ServiceExtensionResponse.result(
        jsonEncode(localizationSnapshot()),
      );
    });

    safeRegister('ext.sint.getRebuildStats', (_, params) async {
      final enabledParam = params['enabled'];
      if (enabledParam == 'true') {
        enableRebuildTracking = true;
      } else if (enabledParam == 'false') {
        enableRebuildTracking = false;
      }
      if (params['reset'] == 'true') {
        resetRebuildStats();
      }
      return developer.ServiceExtensionResponse.result(
        jsonEncode(stateSnapshot()),
      );
    });
  }
}

/// Exposes [Sint.diagnostics] on the global `Sint` entrypoint.
extension SintDiagnosticsExtension on SintInterface {
  /// Runtime diagnostics inspector for all four SINT pillars (`S · I · N · T`).
  SintDiagnostics get diagnostics => SintDiagnostics.instance;
}
