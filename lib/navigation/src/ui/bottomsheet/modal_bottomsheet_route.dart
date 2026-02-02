import 'package:flutter/material.dart';
import 'package:sint/navigation/src/router/router_report_manager.dart';
import 'package:sint/navigation/src/ui/bottomsheet/modal_bottomsheet_layout.dart';

class SintModalBottomSheetRoute<T> extends PopupRoute<T> {
  SintModalBottomSheetRoute({
    this.builder,
    this.theme,
    this.barrierLabel,
    this.backgroundColor,
    this.isPersistent,
    this.elevation,
    this.shape,
    this.removeTop = true,
    this.clipBehavior,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    required this.isScrollControlled,
    super.settings,
    this.enterBottomSheetDuration = const Duration(milliseconds: 250),
    this.exitBottomSheetDuration = const Duration(milliseconds: 200),
    this.curve,
  }) {
    RouterReportManager.instance.reportCurrentRoute(this);
  }
  final bool? isPersistent;
  final WidgetBuilder? builder;
  final ThemeData? theme;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final Color? modalBarrierColor;
  final bool isDismissible;
  final bool enableDrag;
  // final String name;
  final Duration enterBottomSheetDuration;
  final Duration exitBottomSheetDuration;
  final Curve? curve;
  // remove safearea from top
  final bool removeTop;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 700);

  @override
  bool get barrierDismissible => isDismissible;

  @override
  final String? barrierLabel;

  @override
  Color get barrierColor => modalBarrierColor ?? Colors.black54;

  AnimationController? animationController;

  @override
  void dispose() {
    RouterReportManager.instance.reportRouteDispose(this);
    super.dispose();
  }

  @override
  Animation<double> createAnimation() {
    if (curve != null) {
      return CurvedAnimation(curve: curve!, parent: animationController!.view);
    }
    return animationController!.view;
  }

  @override
  AnimationController createAnimationController() {
    assert(animationController == null);
    animationController =
        BottomSheet.createAnimationController(navigator!.overlay!);
    animationController!.duration = enterBottomSheetDuration;
    animationController!.reverseDuration = exitBottomSheetDuration;
    return animationController!;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final sheetTheme =
        theme?.bottomSheetTheme ?? Theme.of(context).bottomSheetTheme;
    // By definition, the bottom sheet is aligned to the bottom of the page
    // and isn't exposed to the top padding of the MediaQuery.
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: removeTop,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _GetModalBottomSheet<T>(
          route: this,
          backgroundColor: backgroundColor ??
              sheetTheme.modalBackgroundColor ??
              sheetTheme.backgroundColor,
          elevation:
              elevation ?? sheetTheme.modalElevation ?? sheetTheme.elevation,
          shape: shape,
          clipBehavior: clipBehavior,
          isScrollControlled: isScrollControlled,
          enableDrag: enableDrag,
        ),
      ),
    );
    if (theme != null) bottomSheet = Theme(data: theme!, child: bottomSheet);
    return bottomSheet;
  }
}

class _GetModalBottomSheet<T> extends StatefulWidget {
  const _GetModalBottomSheet({
    super.key,
    this.route,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.isScrollControlled = false,
    this.enableDrag = true,
    this.isPersistent = false,
  });
  final bool isPersistent;
  final SintModalBottomSheetRoute<T>? route;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final bool enableDrag;

  @override
  _GetModalBottomSheetState<T> createState() => _GetModalBottomSheetState<T>();
}

class _GetModalBottomSheetState<T> extends State<_GetModalBottomSheet<T>> {
  String _getRouteLabel(MaterialLocalizations localizations) {
    if ((Theme.of(context).platform == TargetPlatform.android) ||
        (Theme.of(context).platform == TargetPlatform.fuchsia)) {
      return localizations.dialogLabel;
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final mediaQuery = MediaQuery.of(context);
    final localizations = MaterialLocalizations.of(context);
    final routeLabel = _getRouteLabel(localizations);

    return AnimatedBuilder(
      animation: widget.route!.animation!,
      builder: (context, child) {
        // Disable the initial animation when accessible navigation is on so
        // that the semantics are added to the tree at the correct time.
        final animationValue = mediaQuery.accessibleNavigation
            ? 1.0
            : widget.route!.animation!.value;
        return Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: routeLabel,
          explicitChildNodes: true,
          child: ClipRect(
            child: CustomSingleChildLayout(
                delegate: SintModalBottomSheetLayout(
                    animationValue, widget.isScrollControlled),
                child: widget.isPersistent == false
                    ? BottomSheet(
                        animationController: widget.route!.animationController,
                        onClosing: () {
                          if (widget.route!.isCurrent) {
                            Navigator.pop(context);
                          }
                        },
                        builder: widget.route!.builder!,
                        backgroundColor: widget.backgroundColor,
                        elevation: widget.elevation,
                        shape: widget.shape,
                        clipBehavior: widget.clipBehavior,
                        enableDrag: widget.enableDrag,
                      )
                    : Scaffold(
                        bottomSheet: BottomSheet(
                          animationController:
                              widget.route!.animationController,
                          onClosing: () {
                            // if (widget.route.isCurrent) {
                            //   Navigator.pop(context);
                            // }
                          },
                          builder: widget.route!.builder!,
                          backgroundColor: widget.backgroundColor,
                          elevation: widget.elevation,
                          shape: widget.shape,
                          clipBehavior: widget.clipBehavior,
                          enableDrag: widget.enableDrag,
                        ),
                      )),
          ),
        );
      },
    );
  }
}

