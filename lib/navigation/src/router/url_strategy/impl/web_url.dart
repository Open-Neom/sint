import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void removeHash() {
  setUrlStrategy(PathUrlStrategy());
}

void setHashUrlStrategy() {
  setUrlStrategy(const HashUrlStrategy());
}

/// Pruning a single browser-history entry is not supported by
/// flutter_web_plugins. Kept side-effect free until a safe web
/// implementation lands; the previous version recursed infinitely.
void removeLastHistoryEntry(String? url) {

}
