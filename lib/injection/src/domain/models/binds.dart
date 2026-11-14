import 'package:flutter/material.dart';
import 'package:sint/injection/src/bind.dart';
import 'package:sint/injection/src/ui/multi_binder.dart';

class Binds extends StatelessWidget {
  final List<Bind<dynamic>> binds;
  final Widget child;

  Binds({
    super.key,
    required this.binds,
    required this.child,
  }) : assert(binds.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    var fastPathAll = true;
    for (var i = 0; i < binds.length; i++) {
      if (!binds[i].canFlattenIntoMultiBinder) {
        fastPathAll = false;
        break;
      }
    }
    if (fastPathAll) {
      return MultiBinder(
        binds: binds,
        child: child,
      );
    }

    // Mixed path: group contiguous flattenable runs into single MultiBinder
    // elements while preserving exact order for custom Bind.builder entries.
    Widget current = child;
    List<Bind<dynamic>>? pendingFlat;
    for (var i = binds.length - 1; i >= 0; i--) {
      final entry = binds[i];
      if (entry.canFlattenIntoMultiBinder) {
        (pendingFlat ??= <Bind<dynamic>>[]).add(entry);
      } else {
        if (pendingFlat != null && pendingFlat.isNotEmpty) {
          current = MultiBinder(
            binds: pendingFlat.reversed.toList(growable: false),
            child: current,
          );
          pendingFlat = null;
        }
        current = entry.copyWithChild(current);
      }
    }
    if (pendingFlat != null && pendingFlat.isNotEmpty) {
      current = MultiBinder(
        binds: pendingFlat.reversed.toList(growable: false),
        child: current,
      );
    }
    return current;
  }
}
