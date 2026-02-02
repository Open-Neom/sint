import 'package:flutter/material.dart';

@immutable
class PathDecoded {
  final RegExp regex;
  final List<String?> keys;
  const PathDecoded(this.regex, this.keys);

  @override
  int get hashCode => regex.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PathDecoded &&
        other.regex == regex; // && listEquals(other.keys, keys);
  }
}