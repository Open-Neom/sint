import 'dart:ui' as ui;

import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/sint_injection.dart';
import 'package:sint/navigation/src/domain/enums/transition.dart';
import 'package:sint/navigation/src/domain/interfaces/custom_transition.dart';
import 'package:sint/navigation/src/domain/models/config_data.dart';
import 'package:sint/navigation/src/domain/models/routing.dart';
import 'package:sint/navigation/src/domain/models/sint_snackbar_style.dart';
import 'package:sint/navigation/src/router/sint_page.dart';
import 'package:sint/navigation/src/ui/sint_material_app.dart';
import 'package:sint/navigation/src/ui/sint_root.dart';
import 'package:sint/translation/sint_translation.dart';

/// The design-system host used by [SintApp].
enum SintDesign {
  /// Uses Cupertino on iOS and Material on all other target platforms.
  ///
  /// On the web, Flutter reports the browser's target platform. Use [material]
  /// or [cupertino] to keep the same presentation across browser platforms.
  auto,

  /// Uses standalone `material_ui` on every platform.
  material,

  /// Uses standalone `cupertino_ui` on every platform.
  cupertino,
}

const _legacyThemeNotice =
    'theme accepts SDK ThemeData, which is incompatible with standalone '
    'material_ui.ThemeData and cupertino_ui.CupertinoThemeData. '
    'Use materialTheme and/or cupertinoTheme. The legacy theme parameter '
    'will be removed in a future major release.';

/// A SINT application with standalone Material and Cupertino design systems.
///
/// [design] selects the host. In [SintDesign.auto], iOS uses [cupertinoTheme]
/// and other target platforms use [materialTheme]. Both hosts share one
/// [SintRoot], dependency registry, router and translation configuration.
/// Selecting a host does not convert the widgets used by application pages.
///
/// [theme] is a migration-only alternative: providing an SDK theme preserves
/// the existing [SintMaterialApp] host, including on iOS. It cannot be combined
/// with standalone theme arguments or an explicit Cupertino design.
///
/// During incremental migration, [enableLegacyCompatibility] supplies Flutter's
/// temporary compatibility bridges and an SDK ScaffoldMessenger to descendants,
/// including the [builder] callback. Bridges map common theme values and
/// localization data; they do not convert public types or every component theme.
class SintApp extends StatelessWidget {
  const SintApp({
    super.key,
    this.design = SintDesign.auto,
    @Deprecated(_legacyThemeNotice) this.theme,
    this.materialTheme,
    this.materialDarkTheme,
    this.materialHighContrastTheme,
    this.materialHighContrastDarkTheme,
    this.materialThemeMode,
    this.cupertinoTheme,
    this.materialScaffoldMessengerKey,
    this.enableLegacyCompatibility = true,
    this.navigatorKey,
    this.initialRoute,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.textDirection,
    this.locale,
    this.fallbackLocale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.debugShowMaterialGrid = false,
    this.shortcuts,
    this.actions,
    this.scrollBehavior,
    this.restorationScopeId,
    this.customTransition,
    this.translationsKeys,
    this.translations,
    this.routingCallback,
    this.defaultTransition,
    this.opaqueRoute,
    this.onInit,
    this.onReady,
    this.onDispose,
    this.enableLog = kDebugMode,
    this.logWriterCallback,
    this.popGesture,
    this.smartManagement = SmartManagement.full,
    this.binds = const [],
    this.transitionDuration,
    this.defaultGlobalState,
    this.sintPages,
    this.unknownRoute,
    this.snackBarStyle,
    this.translateEndpoints = false,
  }) : routeInformationProvider = null,
       routeInformationParser = null,
       routerDelegate = null,
       routerConfig = null,
       backButtonDispatcher = null;

  /// Creates a host using SINT routing or an explicitly supplied router.
  ///
  /// A [routerConfig] cannot be combined with separate router arguments.
  const SintApp.router({
    super.key,
    this.design = SintDesign.auto,
    @Deprecated(_legacyThemeNotice) this.theme,
    this.materialTheme,
    this.materialDarkTheme,
    this.materialHighContrastTheme,
    this.materialHighContrastDarkTheme,
    this.materialThemeMode,
    this.cupertinoTheme,
    this.materialScaffoldMessengerKey,
    this.enableLegacyCompatibility = true,
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.routerConfig,
    this.backButtonDispatcher,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.textDirection,
    this.locale,
    this.fallbackLocale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.debugShowMaterialGrid = false,
    this.shortcuts,
    this.actions,
    this.scrollBehavior,
    this.restorationScopeId,
    this.customTransition,
    this.translationsKeys,
    this.translations,
    this.routingCallback,
    this.defaultTransition,
    this.opaqueRoute,
    this.onInit,
    this.onReady,
    this.onDispose,
    this.enableLog = kDebugMode,
    this.logWriterCallback,
    this.popGesture,
    this.smartManagement = SmartManagement.full,
    this.binds = const [],
    this.transitionDuration,
    this.defaultGlobalState,
    this.sintPages,
    this.unknownRoute,
    this.snackBarStyle,
    this.translateEndpoints = false,
  }) : navigatorKey = null,
       initialRoute = null;

  final SintDesign design;

  /// An SDK theme that temporarily selects the legacy Material host.
  @Deprecated(_legacyThemeNotice)
  final legacy.ThemeData? theme;

  final material.ThemeData? materialTheme;
  final material.ThemeData? materialDarkTheme;
  final material.ThemeData? materialHighContrastTheme;
  final material.ThemeData? materialHighContrastDarkTheme;
  final material.ThemeMode? materialThemeMode;
  final cupertino.CupertinoThemeData? cupertinoTheme;
  final GlobalKey<material.ScaffoldMessengerState>?
  materialScaffoldMessengerKey;
  final bool enableLegacyCompatibility;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? initialRoute;
  final List<NavigatorObserver> navigatorObservers;
  final TransitionBuilder? builder;
  final String title;
  final GenerateAppTitle? onGenerateTitle;
  final Color? color;
  final TextDirection? textDirection;
  final Locale? locale;
  final Locale? fallbackLocale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool showPerformanceOverlay;
  final bool checkerboardRasterCacheImages;
  final bool checkerboardOffscreenLayers;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final bool debugShowMaterialGrid;
  final Map<LogicalKeySet, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final ScrollBehavior? scrollBehavior;
  final String? restorationScopeId;
  final CustomTransition? customTransition;
  final Map<String, Map<String, String>>? translationsKeys;
  final Translations? translations;
  final ValueChanged<Routing?>? routingCallback;
  final Transition? defaultTransition;
  final bool? opaqueRoute;
  final VoidCallback? onInit;
  final VoidCallback? onReady;
  final VoidCallback? onDispose;
  final bool? enableLog;
  final LogWriterCallback? logWriterCallback;
  final bool? popGesture;
  final SmartManagement smartManagement;
  final List<Bind> binds;
  final Duration? transitionDuration;
  final bool? defaultGlobalState;
  final List<SintPage>? sintPages;
  final SintPage? unknownRoute;
  final SintSnackBarStyle? snackBarStyle;
  final bool translateEndpoints;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final RouterConfig<Object>? routerConfig;
  final BackButtonDispatcher? backButtonDispatcher;

  bool get _useCupertino => switch (design) {
    SintDesign.auto => defaultTargetPlatform == TargetPlatform.iOS,
    SintDesign.material => false,
    SintDesign.cupertino => true,
  };

  void _validateConfiguration() {
    if (routerConfig != null &&
        (routerDelegate != null ||
            routeInformationParser != null ||
            routeInformationProvider != null ||
            backButtonDispatcher != null)) {
      throw FlutterError(
        'SintApp.router: routerConfig cannot be combined with separate '
        'routerDelegate, routeInformationParser, routeInformationProvider '
        'or backButtonDispatcher arguments.',
      );
    }
    // ignore: deprecated_member_use_from_same_package
    if (theme != null &&
        (materialTheme != null ||
            materialDarkTheme != null ||
            materialHighContrastTheme != null ||
            materialHighContrastDarkTheme != null ||
            materialThemeMode != null ||
            cupertinoTheme != null ||
            materialScaffoldMessengerKey != null ||
            design == SintDesign.cupertino)) {
      throw FlutterError(
        'SintApp: legacy theme cannot be combined with standalone theme '
        'arguments, materialScaffoldMessengerKey or SintDesign.cupertino. '
        'Remove theme and supply materialTheme and/or cupertinoTheme to '
        'use the standalone host.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _validateConfiguration();
    // ignore: deprecated_member_use_from_same_package
    if (theme != null) return _buildLegacy();

    final useCupertino = _useCupertino;
    return SintRoot(
      config: ConfigData(
        backButtonDispatcher:
            routerConfig?.backButtonDispatcher ?? backButtonDispatcher,
        binds: binds,
        customTransition: customTransition,
        defaultGlobalState: defaultGlobalState,
        defaultTransition: defaultTransition,
        enableLog: enableLog,
        fallbackLocale: fallbackLocale,
        sintPages: sintPages,
        home: null,
        initialRoute: initialRoute,
        locale: locale,
        logWriterCallback: logWriterCallback,
        navigatorKey: navigatorKey,
        navigatorObservers: navigatorObservers,
        onDispose: onDispose,
        onInit: onInit,
        onReady: onReady,
        routeInformationParser:
            routerConfig?.routeInformationParser ?? routeInformationParser,
        routeInformationProvider:
            routerConfig?.routeInformationProvider ?? routeInformationProvider,
        routerDelegate: routerConfig?.routerDelegate ?? routerDelegate,
        routingCallback: routingCallback,
        scaffoldMessengerKey: null,
        smartManagement: smartManagement,
        transitionDuration: transitionDuration,
        translations: translations,
        translationsKeys: translationsKeys,
        unknownRoute: unknownRoute,
        defaultPopGesture: popGesture,
        defaultOpaqueRoute: opaqueRoute ?? true,
        snackBarStyle: snackBarStyle,
        translateEndpoints: translateEndpoints,
        materialTheme: materialTheme,
        materialDarkTheme: materialDarkTheme,
        materialHighContrastTheme: materialHighContrastTheme,
        materialHighContrastDarkTheme: materialHighContrastDarkTheme,
        materialThemeMode: materialThemeMode ?? material.ThemeMode.system,
        cupertinoTheme: cupertinoTheme,
        materialScaffoldMessengerKey: materialScaffoldMessengerKey,
        useStandaloneDesign: true,
        useCupertinoDesign: useCupertino,
      ),
      child: Builder(builder: _buildStandalone),
    );
  }

  Widget _buildStandalone(BuildContext context) {
    final config = SintRoot.of(context).config;
    // Custom delegates go first so applications can override a default type.
    final delegates = <LocalizationsDelegate<dynamic>>[
      ...?localizationsDelegates,
      ...material.GlobalMaterialLocalizations.delegates,
    ];
    if (config.useCupertinoDesign) {
      return cupertino.CupertinoApp.router(
        key: config.unikey,
        routerConfig: routerConfig,
        routerDelegate: routerConfig == null ? config.routerDelegate : null,
        routeInformationParser: routerConfig == null
            ? config.routeInformationParser
            : null,
        routeInformationProvider: routerConfig == null
            ? config.routeInformationProvider
            : null,
        backButtonDispatcher: routerConfig == null
            ? config.backButtonDispatcher
            : null,
        builder: (context, child) => _buildAppContents(context, child, config),
        title: title,
        onGenerateTitle: onGenerateTitle,
        color: color,
        theme: config.cupertinoTheme,
        locale: Sint.locale ?? locale,
        localizationsDelegates: delegates,
        localeListResolutionCallback: localeListResolutionCallback,
        localeResolutionCallback: localeResolutionCallback,
        supportedLocales: supportedLocales,
        showPerformanceOverlay: showPerformanceOverlay,
        checkerboardRasterCacheImages: checkerboardRasterCacheImages,
        checkerboardOffscreenLayers: checkerboardOffscreenLayers,
        showSemanticsDebugger: showSemanticsDebugger,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        shortcuts: shortcuts,
        actions: actions,
        restorationScopeId: restorationScopeId,
        scrollBehavior: scrollBehavior,
      );
    }
    return material.MaterialApp.router(
      key: config.unikey,
      routerConfig: routerConfig,
      routerDelegate: routerConfig == null ? config.routerDelegate : null,
      routeInformationParser: routerConfig == null
          ? config.routeInformationParser
          : null,
      routeInformationProvider: routerConfig == null
          ? config.routeInformationProvider
          : null,
      backButtonDispatcher: routerConfig == null
          ? config.backButtonDispatcher
          : null,
      builder: (context, child) => _buildAppContents(context, child, config),
      title: title,
      onGenerateTitle: onGenerateTitle,
      color: color,
      theme: config.materialTheme,
      darkTheme: config.materialDarkTheme,
      highContrastTheme: config.materialHighContrastTheme,
      highContrastDarkTheme: config.materialHighContrastDarkTheme,
      themeMode: config.materialThemeMode ?? material.ThemeMode.system,
      scaffoldMessengerKey: config.materialScaffoldMessengerKey,
      locale: Sint.locale ?? locale,
      localizationsDelegates: delegates,
      localeListResolutionCallback: localeListResolutionCallback,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales,
      debugShowMaterialGrid: debugShowMaterialGrid,
      showPerformanceOverlay: showPerformanceOverlay,
      checkerboardRasterCacheImages: checkerboardRasterCacheImages,
      checkerboardOffscreenLayers: checkerboardOffscreenLayers,
      showSemanticsDebugger: showSemanticsDebugger,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      shortcuts: shortcuts,
      actions: actions,
      restorationScopeId: restorationScopeId,
      scrollBehavior:
          scrollBehavior ??
          (kIsWeb
              ? const material.MaterialScrollBehavior().copyWith(
                  scrollbars: true,
                  dragDevices: {
                    ui.PointerDeviceKind.touch,
                    ui.PointerDeviceKind.mouse,
                    ui.PointerDeviceKind.trackpad,
                  },
                )
              : null),
    );
  }

  Widget _buildAppContents(
    BuildContext context,
    Widget? child,
    ConfigData config,
  ) {
    Widget contents = Directionality(
      textDirection:
          textDirection ??
          (rtlLanguages.contains(Sint.locale?.languageCode)
              ? TextDirection.rtl
              : Directionality.of(context)),
      child: Builder(
        builder: (context) =>
            builder?.call(context, child) ?? child ?? const SizedBox.shrink(),
      ),
    );
    if (enableLegacyCompatibility) {
      // These are explicitly temporary migration utilities provided by Flutter.
      // Keep them here until consumers have migrated their legacy subtrees.
      // ignore: deprecated_member_use
      contents = material.MaterialUiCompatibilityBridge(
        // ignore: deprecated_member_use
        child: cupertino.CupertinoUiCompatibilityBridge(
          child: legacy.ScaffoldMessenger(child: contents),
        ),
      );
    }
    if (config.useCupertinoDesign) {
      // Cupertino pages may still contain Material widgets or SINT's legacy
      // Material overlays. Supply their theme without creating another app,
      // navigator or SINT root. Cupertino remains the selected application host.
      final brightness =
          cupertino.CupertinoTheme.of(context).brightness ??
          MediaQuery.platformBrightnessOf(context);
      final materialTheme = brightness == Brightness.dark
          ? config.materialDarkTheme ??
                config.materialTheme ??
                material.ThemeData.dark()
          : config.materialTheme ?? material.ThemeData.light();
      contents = material.Theme(
        data: materialTheme,
        child: material.ScaffoldMessenger(
          key: config.materialScaffoldMessengerKey,
          child: contents,
        ),
      );
    }
    return contents;
  }

  Widget _buildLegacy() {
    // Preserve the SDK host for the transitional theme parameter. A legacy
    // ThemeData is never cast or passed to a standalone MaterialApp.
    if (routerConfig == null &&
        routerDelegate == null &&
        routeInformationParser == null &&
        routeInformationProvider == null &&
        backButtonDispatcher == null) {
      return SintMaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: initialRoute,
        // ignore: deprecated_member_use_from_same_package
        theme: theme,
        builder: builder,
        title: title,
        onGenerateTitle: onGenerateTitle,
        color: color,
        textDirection: textDirection,
        locale: locale,
        fallbackLocale: fallbackLocale,
        localizationsDelegates: localizationsDelegates,
        localeListResolutionCallback: localeListResolutionCallback,
        localeResolutionCallback: localeResolutionCallback,
        supportedLocales: supportedLocales,
        debugShowMaterialGrid: debugShowMaterialGrid,
        showPerformanceOverlay: showPerformanceOverlay,
        checkerboardRasterCacheImages: checkerboardRasterCacheImages,
        checkerboardOffscreenLayers: checkerboardOffscreenLayers,
        showSemanticsDebugger: showSemanticsDebugger,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        shortcuts: shortcuts,
        scrollBehavior: scrollBehavior,
        actions: actions,
        customTransition: customTransition,
        translationsKeys: translationsKeys,
        translations: translations,
        routingCallback: routingCallback,
        defaultTransition: defaultTransition,
        opaqueRoute: opaqueRoute,
        onInit: onInit,
        onReady: onReady,
        onDispose: onDispose,
        enableLog: enableLog,
        logWriterCallback: logWriterCallback,
        popGesture: popGesture,
        smartManagement: smartManagement,
        binds: binds,
        transitionDuration: transitionDuration,
        defaultGlobalState: defaultGlobalState,
        sintPages: sintPages,
        navigatorObservers: navigatorObservers,
        unknownRoute: unknownRoute,
        snackBarStyle: snackBarStyle,
        translateEndpoints: translateEndpoints,
      );
    }
    return SintMaterialApp.router(
      // ignore: deprecated_member_use_from_same_package
      theme: theme,
      routeInformationProvider:
          routerConfig?.routeInformationProvider ?? routeInformationProvider,
      routeInformationParser:
          routerConfig?.routeInformationParser ?? routeInformationParser,
      routerDelegate: routerConfig?.routerDelegate ?? routerDelegate,
      backButtonDispatcher:
          routerConfig?.backButtonDispatcher ?? backButtonDispatcher,
      builder: builder,
      title: title,
      onGenerateTitle: onGenerateTitle,
      color: color,
      textDirection: textDirection,
      locale: locale,
      fallbackLocale: fallbackLocale,
      localizationsDelegates: localizationsDelegates,
      localeListResolutionCallback: localeListResolutionCallback,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales,
      debugShowMaterialGrid: debugShowMaterialGrid,
      showPerformanceOverlay: showPerformanceOverlay,
      checkerboardRasterCacheImages: checkerboardRasterCacheImages,
      checkerboardOffscreenLayers: checkerboardOffscreenLayers,
      showSemanticsDebugger: showSemanticsDebugger,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      shortcuts: shortcuts,
      scrollBehavior: scrollBehavior,
      actions: actions,
      customTransition: customTransition,
      translationsKeys: translationsKeys,
      translations: translations,
      routingCallback: routingCallback,
      defaultTransition: defaultTransition,
      opaqueRoute: opaqueRoute,
      onInit: onInit,
      onReady: onReady,
      onDispose: onDispose,
      enableLog: enableLog,
      logWriterCallback: logWriterCallback,
      popGesture: popGesture,
      smartManagement: smartManagement,
      binds: binds,
      transitionDuration: transitionDuration,
      defaultGlobalState: defaultGlobalState,
      sintPages: sintPages,
      navigatorObservers: navigatorObservers,
      unknownRoute: unknownRoute,
      snackBarStyle: snackBarStyle,
      translateEndpoints: translateEndpoints,
    );
  }
}
