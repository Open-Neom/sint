import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sint/core/src/domain/typedefs/core_typedefs.dart';
import 'package:sint/core/src/domain/enums/smart_management.dart';
import 'package:sint/injection/src/bind.dart';
import 'package:sint/navigation/src/domain/models/routing.dart';
import 'package:sint/navigation/src/domain/models/sint_snackbar_style.dart';
import 'package:sint/navigation/src/router/index.dart';
import 'package:sint/navigation/src/ui/snackbar/snackbar_queue.dart';
import 'package:sint/translation/src/domain/interfaces/translations.dart';

class ConfigData {
  final ValueChanged<Routing?>? routingCallback;
  final Transition? defaultTransition;
  final VoidCallback? onInit;
  final VoidCallback? onReady;
  final VoidCallback? onDispose;
  final bool? enableLog;
  final LogWriterCallback? logWriterCallback;
  final SmartManagement smartManagement;
  final List<Bind> binds;
  final Duration? transitionDuration;
  final bool? defaultGlobalState;
  final List<SintPage>? sintPages;
  final SintPage? unknownRoute;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final BackButtonDispatcher? backButtonDispatcher;
  final List<NavigatorObserver>? navigatorObservers;
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final Map<String, Map<String, String>>? translationsKeys;
  final Translations? translations;
  final Locale? locale;
  final Locale? fallbackLocale;
  final String? initialRoute;
  final CustomTransition? customTransition;

  /// **DEPRECATED** — Use [initialRoute] + [sintPages] instead.
  @Deprecated('Use initialRoute + sintPages instead')
  final Widget? home;

  final bool testMode;
  final Key? unikey;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;
  final bool? defaultPopGesture;
  final bool defaultOpaqueRoute;
  final Duration defaultTransitionDuration;
  final Curve defaultTransitionCurve;
  final Curve defaultDialogTransitionCurve;
  final Duration defaultDialogTransitionDuration;
  final Routing routing;
  final Map<String, String?> parameters;
  final SintSnackBarStyle? snackBarStyle;
  final SnackBarQueue snackBarQueue = SnackBarQueue();

  ConfigData({
    required this.routingCallback,
    required this.defaultTransition,
    required this.onInit,
    required this.onReady,
    required this.onDispose,
    required this.enableLog,
    required this.logWriterCallback,
    required this.smartManagement,
    required this.binds,
    required this.transitionDuration,
    required this.defaultGlobalState,
    required this.sintPages,
    required this.unknownRoute,
    required this.routeInformationProvider,
    required this.routeInformationParser,
    required this.routerDelegate,
    required this.backButtonDispatcher,
    required this.navigatorObservers,
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
    required this.translationsKeys,
    required this.translations,
    required this.locale,
    required this.fallbackLocale,
    required this.initialRoute,
    required this.customTransition,
    required this.home,
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.unikey,
    this.testMode = false,
    this.defaultOpaqueRoute = true,
    this.defaultTransitionDuration = const Duration(milliseconds: 300),
    this.defaultTransitionCurve = Curves.easeOutQuad,
    this.defaultDialogTransitionCurve = Curves.easeOutQuad,
    this.defaultDialogTransitionDuration = const Duration(milliseconds: 300),
    this.parameters = const {},
    required this.defaultPopGesture,
    this.snackBarStyle,
    Routing? routing,
  }) : routing = routing ?? Routing();

  ConfigData copyWith({
    ValueChanged<Routing?>? routingCallback,
    Transition? defaultTransition,
    VoidCallback? onInit,
    VoidCallback? onReady,
    VoidCallback? onDispose,
    bool? enableLog,
    LogWriterCallback? logWriterCallback,
    SmartManagement? smartManagement,
    List<Bind>? binds,
    Duration? transitionDuration,
    bool? defaultGlobalState,
    List<SintPage>? pages,
    SintPage? unknownPage,
    RouteInformationProvider? routeInformationProvider,
    RouteInformationParser<Object>? routeInformationParser,
    RouterDelegate<Object>? routerDelegate,
    BackButtonDispatcher? backButtonDispatcher,
    List<NavigatorObserver>? navigatorObservers,
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
    Map<String, Map<String, String>>? translationsKeys,
    Translations? translations,
    Locale? locale,
    Locale? fallbackLocale,
    String? initialRoute,
    CustomTransition? customTransition,
    Widget? home,
    bool? testMode,
    Key? unikey,
    ThemeData? theme,
    ThemeData? darkTheme,
    ThemeMode? themeMode,
    bool? defaultPopGesture,
    bool? defaultOpaqueRoute,
    Duration? defaultTransitionDuration,
    Curve? defaultTransitionCurve,
    Curve? defaultDialogTransitionCurve,
    Duration? defaultDialogTransitionDuration,
    SintSnackBarStyle? snackBarStyle,
    Routing? routing,
    Map<String, String?>? parameters,
  }) {
    return ConfigData(
      routingCallback: routingCallback ?? this.routingCallback,
      defaultTransition: defaultTransition ?? this.defaultTransition,
      onInit: onInit ?? this.onInit,
      onReady: onReady ?? this.onReady,
      onDispose: onDispose ?? this.onDispose,
      enableLog: enableLog ?? this.enableLog,
      logWriterCallback: logWriterCallback ?? this.logWriterCallback,
      smartManagement: smartManagement ?? this.smartManagement,
      binds: binds ?? this.binds,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      defaultGlobalState: defaultGlobalState ?? this.defaultGlobalState,
      sintPages: pages ?? sintPages,
      unknownRoute: unknownPage ?? unknownRoute,
      routeInformationProvider:
      routeInformationProvider ?? this.routeInformationProvider,
      routeInformationParser:
      routeInformationParser ?? this.routeInformationParser,
      routerDelegate: routerDelegate ?? this.routerDelegate,
      backButtonDispatcher: backButtonDispatcher ?? this.backButtonDispatcher,
      navigatorObservers: navigatorObservers ?? this.navigatorObservers,
      navigatorKey: navigatorKey ?? this.navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey ?? this.scaffoldMessengerKey,
      translationsKeys: translationsKeys ?? this.translationsKeys,
      translations: translations ?? this.translations,
      locale: locale ?? this.locale,
      fallbackLocale: fallbackLocale ?? this.fallbackLocale,
      initialRoute: initialRoute ?? this.initialRoute,
      customTransition: customTransition ?? this.customTransition,
      // ignore: deprecated_member_use_from_same_package
      home: home ?? this.home, // Kept for backward compat until SINT 2.0
      testMode: testMode ?? this.testMode,
      unikey: unikey ?? this.unikey,
      theme: theme ?? this.theme,
      darkTheme: darkTheme ?? this.darkTheme,
      themeMode: themeMode ?? this.themeMode,
      defaultPopGesture: defaultPopGesture ?? this.defaultPopGesture,
      defaultOpaqueRoute: defaultOpaqueRoute ?? this.defaultOpaqueRoute,
      defaultTransitionDuration:
      defaultTransitionDuration ?? this.defaultTransitionDuration,
      defaultTransitionCurve:
      defaultTransitionCurve ?? this.defaultTransitionCurve,
      defaultDialogTransitionCurve:
      defaultDialogTransitionCurve ?? this.defaultDialogTransitionCurve,
      defaultDialogTransitionDuration: defaultDialogTransitionDuration ??
          this.defaultDialogTransitionDuration,
      snackBarStyle: snackBarStyle ?? this.snackBarStyle,
      routing: routing ?? this.routing,
      parameters: parameters ?? this.parameters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ConfigData &&
        other.routingCallback == routingCallback &&
        other.defaultTransition == defaultTransition &&
        other.onInit == onInit &&
        other.onReady == onReady &&
        other.onDispose == onDispose &&
        other.enableLog == enableLog &&
        other.logWriterCallback == logWriterCallback &&
        other.smartManagement == smartManagement &&
        listEquals(other.binds, binds) &&
        other.transitionDuration == transitionDuration &&
        other.defaultGlobalState == defaultGlobalState &&
        listEquals(other.sintPages, sintPages) &&
        other.unknownRoute == unknownRoute &&
        other.routeInformationProvider == routeInformationProvider &&
        other.routeInformationParser == routeInformationParser &&
        other.routerDelegate == routerDelegate &&
        other.backButtonDispatcher == backButtonDispatcher &&
        listEquals(other.navigatorObservers, navigatorObservers) &&
        other.navigatorKey == navigatorKey &&
        other.scaffoldMessengerKey == scaffoldMessengerKey &&
        mapEquals(other.translationsKeys, translationsKeys) &&
        other.translations == translations &&
        other.locale == locale &&
        other.fallbackLocale == fallbackLocale &&
        other.initialRoute == initialRoute &&
        other.customTransition == customTransition &&
        // ignore: deprecated_member_use_from_same_package
        other.home == home &&
        other.testMode == testMode &&
        other.unikey == unikey &&
        other.theme == theme &&
        other.darkTheme == darkTheme &&
        other.themeMode == themeMode &&
        other.defaultPopGesture == defaultPopGesture &&
        other.defaultOpaqueRoute == defaultOpaqueRoute &&
        other.defaultTransitionDuration == defaultTransitionDuration &&
        other.defaultTransitionCurve == defaultTransitionCurve &&
        other.defaultDialogTransitionCurve == defaultDialogTransitionCurve &&
        other.defaultDialogTransitionDuration ==
            defaultDialogTransitionDuration &&
        other.routing == routing &&
        other.snackBarStyle == snackBarStyle &&
        mapEquals(other.parameters, parameters);
  }

  @override
  int get hashCode {
    return routingCallback.hashCode ^
    defaultTransition.hashCode ^
    onInit.hashCode ^
    onReady.hashCode ^
    onDispose.hashCode ^
    enableLog.hashCode ^
    logWriterCallback.hashCode ^
    smartManagement.hashCode ^
    binds.hashCode ^
    transitionDuration.hashCode ^
    defaultGlobalState.hashCode ^
    sintPages.hashCode ^
    unknownRoute.hashCode ^
    routeInformationProvider.hashCode ^
    routeInformationParser.hashCode ^
    routerDelegate.hashCode ^
    backButtonDispatcher.hashCode ^
    navigatorObservers.hashCode ^
    navigatorKey.hashCode ^
    scaffoldMessengerKey.hashCode ^
    translationsKeys.hashCode ^
    translations.hashCode ^
    locale.hashCode ^
    fallbackLocale.hashCode ^
    initialRoute.hashCode ^
    customTransition.hashCode ^
    // ignore: deprecated_member_use_from_same_package
    home.hashCode ^
    testMode.hashCode ^
    unikey.hashCode ^
    theme.hashCode ^
    darkTheme.hashCode ^
    themeMode.hashCode ^
    defaultPopGesture.hashCode ^
    defaultOpaqueRoute.hashCode ^
    defaultTransitionDuration.hashCode ^
    defaultTransitionCurve.hashCode ^
    defaultDialogTransitionCurve.hashCode ^
    defaultDialogTransitionDuration.hashCode ^
    routing.hashCode ^
    snackBarStyle.hashCode ^
    parameters.hashCode;
  }
}