import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

/// It replaces the Flutter Navigator, but needs no context.
/// You can to use navigator.push(YourRoute()) rather
/// Navigator.push(context, YourRoute());
NavigatorState? get navigator => NavigationExtension(Sint).key.currentState;

extension NavigationExtension on SintInterface {
  /// **Navigation.push()** shortcut.<br><br>
  ///
  /// Pushes a new `page` to the stack
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, SINT will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  Future<T?>? to<T extends Object?>(Widget Function() page,
      {bool? opaque,
        Transition? transition,
        Curve? curve,
        Duration? duration,
        String? id,
        String? routeName,
        bool fullscreenDialog = false,
        dynamic arguments,
        List<BindingsInterface> bindings = const [],
        bool preventDuplicates = true,
        bool? popGesture,
        bool showCupertinoParallax = true,
        double Function(BuildContext context)? gestureWidth,
        bool rebuildStack = true,
        PreventDuplicateHandlingMode preventDuplicateHandlingMode =
            PreventDuplicateHandlingMode.reorderRoutes}) {
    return searchDelegate(id).to(
      page,
      opaque: opaque,
      transition: transition,
      curve: curve,
      duration: duration,
      id: id,
      routeName: routeName,
      fullscreenDialog: fullscreenDialog,
      arguments: arguments,
      bindings: bindings,
      preventDuplicates: preventDuplicates,
      popGesture: popGesture,
      showCupertinoParallax: showCupertinoParallax,
      gestureWidth: gestureWidth,
      rebuildStack: rebuildStack,
      preventDuplicateHandlingMode: preventDuplicateHandlingMode,
    );
  }

  /// **Navigation.pushNamed()** shortcut.<br><br>
  ///
  /// Pushes a new named `page` to the stack.
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// By default, SINT will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
  Future<T?>? toNamed<T>(
      String page, {
        dynamic arguments,
        dynamic id,
        bool preventDuplicates = true,
        Map<String, String>? parameters,
      }) {

    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    return searchDelegate(id).toNamed(
      page,
      arguments: arguments,
      id: id,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
    );
  }

  /// **Navigation.pushReplacementNamed()** shortcut.<br><br>
  ///
  /// Pop the current named `page` in the stack and push a new one in its place
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// By default, SINT will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
  Future<T?>? offNamed<T>(
      String page, {
        dynamic arguments,
        String? id,
        Map<String, String>? parameters,
      }) {

    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return searchDelegate(id).offNamed(
      page,
      arguments: arguments,
      id: id,
      parameters: parameters,
    );
  }

  /// **Navigation.popUntil()** shortcut.<br><br>
  ///
  /// Calls pop several times in the stack until [predicate] returns true
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// [predicate] can be used like this:
  /// `Sint.until((route) => Sint.currentRoute == '/home')`so when you get to home page,
  ///
  /// or also like this:
  /// `Sint.until((route) => !Sint.isDialogOpen())`, to make sure the
  /// dialog is closed
  void until(bool Function(SintPage<dynamic>) predicate, {String? id}) {
    return searchDelegate(id).backUntil(predicate);
  }

  /// **Navigation.pushNamedAndRemoveUntil()** shortcut.<br><br>
  ///
  /// Push the given named `page`, and then pop several pages in the stack
  /// until [predicate] returns true
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// [predicate] can be used like this:
  /// `Sint.offNamedUntil(page, ModalRoute.withName('/home'))`
  /// to pop router in stack until home,
  /// or like this:
  /// `Sint.offNamedUntil((route) => !Sint.isDialogOpen())`,
  /// to make sure the dialog is closed
  ///
  /// Note: Always put a slash on the route name ('/page1'), to avoid unexpected errors
  Future<T?>? offNamedUntil<T>(
      String page,
      bool Function(SintPage<dynamic>)? predicate, {
        String? id,
        dynamic arguments,
        Map<String, String>? parameters,
      }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    return searchDelegate(id).offNamedUntil<T>(
      page,
      predicate: predicate,
      id: id,
      arguments: arguments,
      parameters: parameters,
    );
  }

  /// **Navigation.popAndPushNamed()** shortcut.<br><br>
  ///
  /// Pop the current named page and pushes a new `page` to the stack
  /// in its place
  ///
  /// You can send any type of value to the other route in the [arguments].
  /// It is very similar to `offNamed()` but use a different approach
  ///
  /// The `offNamed()` pop a page, and goes to the next. The
  /// `offAndToNamed()` goes to the next page, and removes the previous one.
  /// The route transition animation is different.
  Future<T?>? offAndToNamed<T>(
      String page, {
        dynamic arguments,
        String? id,
        dynamic result,
        Map<String, String>? parameters,
      }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return searchDelegate(id).backAndtoNamed(
      page,
      arguments: arguments,
      result: result,
    );
  }

  /// **Navigation.removeRoute()** shortcut.<br><br>
  ///
  /// Remove a specific [route] from the stack
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  void removeRoute(String name, {String? id}) {
    return searchDelegate(id).removeRoute(name);
  }

  /// **Navigation.pushNamedAndRemoveUntil()** shortcut.<br><br>
  ///
  /// Push a named `page` and pop several pages in the stack
  /// until [predicate] returns true. [predicate] is optional
  ///
  /// It has the advantage of not needing context, so you can
  /// call from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [predicate] can be used like this:
  /// `Sint.until((route) => Sint.currentRoute == '/home')`so when you get to home page,
  /// or also like
  /// `Sint.until((route) => !Sint.isDialogOpen())`, to make sure the dialog
  /// is closed
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
  Future<T?>? offAllNamed<T>(
      String newRouteName, {
        dynamic arguments,
        String? id,
        Map<String, String>? parameters,
      }) {
    if (parameters != null) {
      final uri = Uri(path: newRouteName, queryParameters: parameters);
      newRouteName = uri.toString();
    }

    return searchDelegate(id).offAllNamed<T>(
      newRouteName,
      arguments: arguments,
      id: id,
      parameters: parameters,
    );
  }

  /// Returns true if a Snackbar, Dialog or BottomSheet is currently OPEN
  bool get isOverlaysOpen =>
      (isSnackbarOpen || isDialogOpen! || isBottomSheetOpen!);

  /// Returns true if there is no Snackbar, Dialog or BottomSheet open
  bool get isOverlaysClosed =>
      (!isSnackbarOpen && !isDialogOpen! && !isBottomSheetOpen!);

  /// **Navigation.popUntil()** shortcut.<br><br>
  ///
  /// Pop the current page, snackbar, dialog or bottomsheet in the stack
  ///
  /// if your set [closeOverlays] to true, Sint.back() will close the
  /// currently open snackbar/dialog/bottomsheet AND the current page
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  void back<T>({
    T? result,
    bool canPop = true,
    int times = 1,
    String? id,
  }) {
    if (times < 1) {
      times = 1;
    }

    if (times > 1) {
      var count = 0;
      return searchDelegate(id).backUntil((route) => count++ == times);
    } else {
      if (canPop) {
        if (searchDelegate(id).canBack == true) {
          return searchDelegate(id).back<T>(result);
        }
      } else {
        return searchDelegate(id).back<T>(result);
      }
    }
  }

  /// Pop the current page, snackbar, dialog or bottomsheet in the stack
  ///
  /// if your set [closeOverlays] to true, Sint.back() will close the
  /// currently open snackbar/dialog/bottomsheet AND the current page
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  void backLegacy<T>({
    T? result,
    bool closeOverlays = false,
    bool canPop = true,
    int times = 1,
    String? id,
  }) {
    if (closeOverlays) {
      closeAllOverlays();
    }

    if (times < 1) {
      times = 1;
    }

    if (times > 1) {
      var count = 0;
      return searchDelegate(id).navigatorKey.currentState?.popUntil((route) {
        return count++ == times;
      });
    } else {
      if (canPop) {
        if (searchDelegate(id).navigatorKey.currentState?.canPop() == true) {
          return searchDelegate(id).navigatorKey.currentState?.pop<T>(result);
        }
      } else {
        return searchDelegate(id).navigatorKey.currentState?.pop<T>(result);
      }
    }
  }

  void closeAllDialogsAndBottomSheets(
      String? id,
      ) {
    // It can not be divided, because dialogs and bottomsheets can not be consecutive
    while ((isDialogOpen! && isBottomSheetOpen!)) {
      closeOverlay(id: id);
    }
  }

  void closeAllDialogs({
    String? id,
  }) {
    while ((isDialogOpen!)) {
      closeOverlay(id: id);
    }
  }

  /// Close the currently open dialog, returning a [result], if provided
  void closeDialog<T>({String? id, T? result}) {
    // Stop if there is no dialog open
    if (isDialogOpen == null || !isDialogOpen!) return;

    closeOverlay(id: id, result: result);
  }

  void closeBottomSheet<T>({String? id, T? result}) {
    // Stop if there is no bottomsheet open
    if (isBottomSheetOpen == null || !isBottomSheetOpen!) return;

    closeOverlay(id: id, result: result);
  }

  /// Close the current overlay returning the [result], if provided
  void closeOverlay<T>({
    String? id,
    T? result,
  }) {
    searchDelegate(id).navigatorKey.currentState?.pop(result);
  }

  void closeAllBottomSheets({
    String? id,
  }) {
    while ((isBottomSheetOpen!)) {
      searchDelegate(id).navigatorKey.currentState?.pop();
    }
  }

  void closeAllOverlays() {
    closeAllDialogsAndBottomSheets(null);
    closeAllSnackbars();
  }

  /// **Navigation.popUntil()** (with predicate) shortcut .<br><br>
  ///
  /// Close as many router as defined by [times]
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  void close<T extends Object>({
    bool closeAll = true,
    bool closeSnackbar = true,
    bool closeDialog = true,
    bool closeBottomSheet = true,
    String? id,
    T? result,
  }) {
    void handleClose(bool closeCondition, Function closeAllFunction,
        Function closeSingleFunction,
        [bool? isOpenCondition]) {
      if (closeCondition) {
        if (closeAll) {
          closeAllFunction();
        } else if (isOpenCondition == true) {
          closeSingleFunction();
        }
      }
    }

    handleClose(closeSnackbar, closeAllSnackbars, closeCurrentSnackbar);
    handleClose(closeDialog, closeAllDialogs, closeOverlay, isDialogOpen);
    handleClose(closeBottomSheet, closeAllBottomSheets, closeOverlay,
        isBottomSheetOpen);
  }

  /// **Navigation.pushReplacement()** shortcut .<br><br>
  ///
  /// Pop the current page and pushes a new `page` to the stack
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], define a Tween [curve],
  /// and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, SINT will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  Future<T?>? off<T>(
      Widget Function() page, {
        bool? opaque,
        Transition? transition,
        Curve? curve,
        bool? popGesture,
        String? id,
        String? routeName,
        dynamic arguments,
        List<BindingsInterface> bindings = const [],
        bool fullscreenDialog = false,
        bool preventDuplicates = true,
        Duration? duration,
        double Function(BuildContext context)? gestureWidth,
      }) {
    routeName ??= "/${page.runtimeType.toString()}";
    routeName = _cleanRouteName(routeName);
    if (preventDuplicates && routeName == currentRoute) {
      return null;
    }
    return searchDelegate(id).off(
      page,
      opaque: opaque ?? true,
      transition: transition,
      curve: curve,
      popGesture: popGesture,
      id: id,
      routeName: routeName,
      arguments: arguments,
      bindings: bindings,
      fullscreenDialog: fullscreenDialog,
      preventDuplicates: preventDuplicates,
      duration: duration,
      gestureWidth: gestureWidth,
    );
  }

  Future<T?> offUntil<T>(
      Widget Function() page,
      bool Function(SintPage) predicate, [
        Object? arguments,
        String? id,
      ]) {
    return searchDelegate(id).offUntil(
      page,
      predicate,
      arguments,
    );
  }

  ///
  /// Push a `page` and pop several pages in the stack
  /// until [predicate] returns true. [predicate] is optional
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], a [curve] and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [predicate] can be used like this:
  /// `Sint.until((route) => Sint.currentRoute == '/home')`so when you get to home page,
  /// or also like
  /// `Sint.until((route) => !Sint.isDialogOpen())`, to make sure the dialog
  /// is closed
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, SINT will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  Future<T?>? offAll<T>(
      Widget Function() page, {
        bool Function(SintPage<dynamic>)? predicate,
        bool? opaque,
        bool? popGesture,
        String? id,
        String? routeName,
        dynamic arguments,
        List<BindingsInterface> bindings = const [],
        bool fullscreenDialog = false,
        Transition? transition,
        Curve? curve,
        Duration? duration,
        double Function(BuildContext context)? gestureWidth,
      }) {
    routeName ??= "/${page.runtimeType.toString()}";
    routeName = _cleanRouteName(routeName);
    return searchDelegate(id).offAll<T>(
      page,
      predicate: predicate,
      opaque: opaque ?? true,
      popGesture: popGesture,
      id: id,
      //  routeName routeName,
      arguments: arguments,
      bindings: bindings,
      fullscreenDialog: fullscreenDialog,
      transition: transition,
      curve: curve,
      duration: duration,
      gestureWidth: gestureWidth,
    );
  }

  /// Takes a route [name] String generated by [to], [off], [offAll]
  /// (and similar context navigation methods), cleans the extra chars and
  /// accommodates the format.
  /// TODO: check for a more "appealing" URL naming convention.
  /// `() => MyHomeScreenView` becomes `/my-home-screen-view`.
  String _cleanRouteName(String name) {
    name = name.replaceAll('() => ', '');

    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return Uri.tryParse(name)?.toString() ?? name;
  }

  Future<void> updateLocale(Locale l) async {
    Sint.locale = l;
    await forceAppUpdate();
  }

  /// As a rule, Flutter knows which widget to update,
  /// so this command is rarely needed. We can mention situations
  /// where you use const so that ui are not updated with setState,
  /// but you want it to be forcefully updated when an event like
  /// language change happens. using context to make the widget dirty
  /// for performRebuild() is a viable solution.
  /// However, in situations where this is not possible, or at least,
  /// is not desired by the developer, the only solution for updating
  /// ui that Flutter does not want to update is to use reassemble
  /// to forcibly rebuild all ui. Attention: calling this function will
  /// reconstruct the application from the sketch, use this with caution.
  /// Your entire application will be rebuilt, and touch events will not
  /// work until the end of rendering.
  Future<void> forceAppUpdate() async {
    await engine.performReassemble();
  }

  void appUpdate() => rootController.update();

  void changeTheme(ThemeData theme) {
    rootController.setTheme(theme);
  }

  void changeThemeMode(ThemeMode themeMode) {
    rootController.setThemeMode(themeMode);
  }

  GlobalKey<NavigatorState>? addKey(GlobalKey<NavigatorState> newKey) {
    return rootController.addKey(newKey);
  }

  SintDelegate? nestedKey(String? key) {
    return rootController.nestedKey(key);
  }

  SintDelegate searchDelegate(String? k) {
    SintDelegate key;
    if (k == null) {
      key = Sint.rootController.rootDelegate;
    } else {
      if (!keys.containsKey(k)) {
        throw 'Route id ($k) not found';
      }
      key = keys[k]!;
    }

    // if (_key.listenersLength == 0 && !testMode) {
    //   throw """You are trying to use contextless navigation without
    //   a GetMaterialApp or Sint.key.
    //   If you are testing your app, you can use:
    //   [Sint.testMode = true], or if you are running your app on
    //   a physical device or emulator, you must exchange your [MaterialApp]
    //   for a [GetMaterialApp].
    //   """;
    // }

    return key;
  }

  /// give name from current route
  String get currentRoute => routing.current;

  /// give name from previous route
  String get previousRoute => routing.previous;

  /// check if snackbar is open
  bool get isSnackbarOpen =>
      SnackbarController.isSnackbarBeingShown; //routing.isSnackbar;

  void closeAllSnackbars() {
    SnackbarController.cancelAllSnackbars();
  }

  Future<void> closeCurrentSnackbar() async {
    await SnackbarController.closeCurrentSnackbar();
  }

  /// check if dialog is open
  bool? get isDialogOpen => routing.isDialog;

  /// check if bottomsheet is open
  bool? get isBottomSheetOpen => routing.isBottomSheet;

  /// check a raw current route
  Route<dynamic>? get rawRoute => routing.route;

  /// check if default opaque route is enable
  bool get isOpaqueRouteDefault => defaultOpaqueRoute;

  /// give access to currentContext
  BuildContext? get context => key.currentContext;

  /// give access to current Overlay Context
  BuildContext? get overlayContext {
    BuildContext? overlay;
    key.currentState?.overlay?.context.visitChildElements((element) {
      overlay = element;
    });
    return overlay;
  }

  /// give access to Theme.of(context)
  ThemeData get theme {
    var theme = ThemeData.fallback();
    if (context != null) {
      theme = Theme.of(context!);
    }
    return theme;
  }

  /// The current null safe [WidgetsBinding]
  WidgetsBinding get engine {
    return WidgetsFlutterBinding.ensureInitialized();
  }

  /// The window to which this binding is bound.
  ui.PlatformDispatcher get window => engine.platformDispatcher;

  Locale? get deviceLocale => window.locale;

  ///The number of device pixels for each logical pixel.
  double get pixelRatio => window.implicitView!.devicePixelRatio;

  Size get size => window.implicitView!.physicalSize / pixelRatio;

  ///The horizontal extent of this size.
  double get width => size.width;

  ///The vertical extent of this size
  double get height => size.height;

  ///The distance from the top edge to the first unpadded pixel,
  ///in physical pixels.
  double get statusBarHeight => window.implicitView!.padding.top;

  ///The distance from the bottom edge to the first unpadded pixel,
  ///in physical pixels.
  double get bottomBarHeight => window.implicitView!.padding.bottom;

  ///The system-reported text scale.
  double get textScaleFactor => window.textScaleFactor;

  /// give access to TextTheme.of(context)
  TextTheme get textTheme => theme.textTheme;

  /// give access to Mediaquery.of(context)
  MediaQueryData get mediaQuery => MediaQuery.of(context!);

  /// Check if dark mode theme is enable
  bool get isDarkMode => (theme.brightness == Brightness.dark);

  /// Check if dark mode theme is enable on platform on android Q+
  bool get isPlatformDarkMode =>
      (ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark);

  /// give access to Theme.of(context).iconTheme.color
  Color? get iconColor => theme.iconTheme.color;

  /// give access to FocusScope.of(context)
  FocusNode? get focusScope => FocusManager.instance.primaryFocus;

  // /// give access to Immutable MediaQuery.of(context).size.height
  // double get height => MediaQuery.of(context).size.height;

  // /// give access to Immutable MediaQuery.of(context).size.width
  // double get width => MediaQuery.of(context).size.width;

  GlobalKey<NavigatorState> get key => rootController.key;

  Map<String, SintDelegate> get keys => rootController.keys;

  SintRootState get rootController => SintRootState.controller;

  ConfigData get _getxController => SintRootState.controller.config;

  bool? get defaultPopGesture => _getxController.defaultPopGesture;
  bool get defaultOpaqueRoute => _getxController.defaultOpaqueRoute;

  Transition? get defaultTransition => _getxController.defaultTransition;

  Duration get defaultTransitionDuration {
    return _getxController.defaultTransitionDuration;
  }

  Curve get defaultTransitionCurve => _getxController.defaultTransitionCurve;

  Curve get defaultDialogTransitionCurve {
    return _getxController.defaultDialogTransitionCurve;
  }

  Duration get defaultDialogTransitionDuration {
    return _getxController.defaultDialogTransitionDuration;
  }

  Routing get routing => _getxController.routing;

  bool get _shouldUseMock => SintTestMode.active && !SintRoot.treeInitialized;

  /// give current arguments
  dynamic get arguments {
    return args();
  }

  T args<T>() {
    if (_shouldUseMock) {
      return SintTestMode.arguments as T;
    }
    return rootController.rootDelegate.arguments<T>();
  }

  // set parameters(Map<String, String?> newParameters) {
  //   rootController.parameters = newParameters;
  // }

  // @Deprecated('Use GetTestMode.active=true instead')
  set testMode(bool isTest) => SintTestMode.active = isTest;

  // @Deprecated('Use GetTestMode.active instead')
  bool get testMode => SintTestMode.active;

  Map<String, String?> get parameters {
    if (_shouldUseMock) {
      return SintTestMode.parameters;
    }

    return rootController.rootDelegate.parameters;
  }

  /// Casts the stored router delegate to a desired type
  TDelegate? delegate<TDelegate extends RouterDelegate<TPage>, TPage>() =>
      _getxController.routerDelegate as TDelegate?;
}
