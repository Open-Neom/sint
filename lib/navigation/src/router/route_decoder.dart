import 'package:flutter/foundation.dart';
import '../../../sint.dart';

class RouteDecoder {
  const RouteDecoder(
    this.currentTreeBranch,
    this.pageSettings,
  );
  final List<SintPage> currentTreeBranch;
  final PageSettings? pageSettings;

  factory RouteDecoder.fromRoute(String location) {
    var uri = Uri.parse(location);
    final args = PageSettings(uri);
    final decoder =
        (Sint.rootController.rootDelegate).matchRoute(location, arguments: args);
    decoder.route = decoder.route?.copyWith(
      completer: null,
      arguments: args,
      parameters: args.params,
    );
    return decoder;
  }

  SintPage? get route =>
      currentTreeBranch.isEmpty ? null : currentTreeBranch.last;

  SintPage routeOrUnknown(SintPage onUnknow) =>
      currentTreeBranch.isEmpty ? onUnknow : currentTreeBranch.last;

  set route(SintPage? getPage) {
    if (getPage == null) return;
    if (currentTreeBranch.isEmpty) {
      currentTreeBranch.add(getPage);
    } else {
      currentTreeBranch[currentTreeBranch.length - 1] = getPage;
    }
  }

  List<SintPage>? get currentChildren => route?.children;

  Map<String, String> get parameters => pageSettings?.params ?? {};

  dynamic get args {
    return pageSettings?.arguments;
  }

  T? arguments<T>() {
    final args = pageSettings?.arguments;
    if (args is T) {
      return pageSettings?.arguments as T;
    } else {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RouteDecoder &&
        listEquals(other.currentTreeBranch, currentTreeBranch) &&
        other.pageSettings == pageSettings;
  }

  @override
  int get hashCode => currentTreeBranch.hashCode ^ pageSettings.hashCode;

  @override
  String toString() =>
      'RouteDecoder(currentTreeBranch: $currentTreeBranch, pageSettings: $pageSettings)';
}
