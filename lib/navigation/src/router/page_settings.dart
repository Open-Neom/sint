import 'package:flutter/widgets.dart';

class PageSettings extends RouteSettings {
  PageSettings(
    this.uri, [
    Object? arguments,
  ]) : super(arguments: arguments);

  @override
  String get name => '$uri';

  final Uri uri;

  final params = <String, String>{};

  String get path => uri.path;

  List<String> get paths => uri.pathSegments;

  Map<String, String> get query => uri.queryParameters;

  Map<String, List<String>> get queries => uri.queryParametersAll;

  @override
  String toString() => name;

  PageSettings copy({
    Uri? uri,
    Object? arguments,
  }) {
    return PageSettings(
      uri ?? this.uri,
      arguments ?? this.arguments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PageSettings &&
        other.uri == uri &&
        other.arguments == arguments;
  }

  @override
  int get hashCode => uri.hashCode ^ arguments.hashCode;
}
