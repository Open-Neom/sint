import 'impl/stub_url.dart'
    if (dart.library.js_interop) 'impl/web_url.dart'
    if (dart.library.io) 'impl/io_url.dart';

void setUrlStrategy() {
  removeHash();
}

void removeLastHistory(String? url) {
  removeLastHistoryEntry(url);
}

/// Public, explicit control over the web URL strategy (1.5.0).
///
/// Call [SintUrlStrategy.setPath] or [SintUrlStrategy.setHash] in `main()`
/// BEFORE `runApp()` — Flutter requires the strategy to be set before the
/// engine initializes its router. When a strategy was configured this way,
/// SintDelegate's constructor respects it and does not override it.
class SintUrlStrategy {
  SintUrlStrategy._();

  static bool _configured = false;

  /// Whether a URL strategy was already configured (either explicitly via
  /// this class or by the delegate's legacy fallback).
  static bool get isSet => _configured;

  /// Path-based URLs (`/home` instead of `/#/home`). No-op off-web.
  static void setPath() {
    setUrlStrategy();
    _configured = true;
  }

  /// Hash-based URLs (`/#/home`). No-op off-web.
  static void setHash() {
    setHashUrlStrategy();
    _configured = true;
  }

  /// Marks the strategy as configured. For internal use (SintDelegate's
  /// legacy auto-configuration) — prefer [setPath] / [setHash].
  static void markConfigured() {
    _configured = true;
  }
}
