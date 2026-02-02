import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../sint.dart';

class SintRoot extends StatefulWidget {
  const SintRoot({
    super.key,
    required this.config,
    required this.child,
  });
  final ConfigData config;
  final Widget child;
  @override
  State<SintRoot> createState() => SintRootState();

  static bool get treeInitialized => SintRootState._controller != null;

  static SintRootState of(BuildContext context) {
    // Handles the case where the input context is a navigator element.
    SintRootState? root;
    if (context is StatefulElement && context.state is SintRootState) {
      root = context.state as SintRootState;
    }
    root = context.findRootAncestorStateOfType<SintRootState>() ?? root;
    assert(() {
      if (root == null) {
        throw FlutterError(
          'SintRoot operation requested with a context that does not include a SintRoot.\n'
          'The context used must be that of a '
          'widget that is a descendant of a SintRoot widget.',
        );
      }
      return true;
    }());
    return root!;
  }
}

class SintRootState extends State<SintRoot> with WidgetsBindingObserver {
  static SintRootState? _controller;
  static SintRootState get controller {
    if (_controller == null) {
      throw Exception('SintRoot is not part of the three');
    } else {
      return _controller!;
    }
  }

  late ConfigData config;

  @override
  void initState() {
    config = widget.config;
    SintRootState._controller = this;
    SintEngine.instance.addObserver(this);
    onInit();
    super.initState();
  }

  void onClose() {
    config.onDispose?.call();
    Sint.clearTranslations();
    config.snackBarQueue.disposeControllers();
    RouterReportManager.instance.clearRouteKeys();
    RouterReportManager.dispose();
    Sint.resetInstance(clearRouteBindings: true);
    _controller = null;
    SintEngine.instance.removeObserver(this);
  }

  @override
  void dispose() {
    onClose();
    super.dispose();
  }

  void onInit() {
    if (config.sintPages == null && config.home == null) {
      throw 'You need add pages or home';
    }

    if (config.routerDelegate == null) {
      final newDelegate = SintDelegate.createDelegate(
        pages: config.sintPages ??
            [
              SintPage(
                name: cleanRouteName("/${config.home.runtimeType}"),
                page: () => config.home!,
              ),
            ],
        notFoundRoute: config.unknownRoute,
        navigatorKey: config.navigatorKey,
        navigatorObservers: (config.navigatorObservers == null
            ? <NavigatorObserver>[
                SintNavigationObserver(config.routingCallback, Sint.routing)
              ]
            : <NavigatorObserver>[
                SintNavigationObserver(config.routingCallback, config.routing),
                ...config.navigatorObservers!
              ]),
      );
      config = config.copyWith(routerDelegate: newDelegate);
    }

    if (config.routeInformationParser == null) {
      final newRouteInformationParser =
          SintInformationParser.createInformationParser(
        initialRoute: config.initialRoute ??
            config.sintPages?.first.name ??
            cleanRouteName("/${config.home.runtimeType}"),
      );

      config =
          config.copyWith(routeInformationParser: newRouteInformationParser);
    }

    if (config.locale != null) Sint.locale = config.locale;

    if (config.fallbackLocale != null) {
      Sint.fallbackLocale = config.fallbackLocale;
    }

    if (config.translations != null) {
      Sint.addTranslations(config.translations!.keys);
    } else if (config.translationsKeys != null) {
      Sint.addTranslations(config.translationsKeys!);
    }

    Sint.smartManagement = config.smartManagement;
    config.onInit?.call();

    Sint.isLogEnable = config.enableLog ?? kDebugMode;
    Sint.log = config.logWriterCallback ?? defaultLogWriterCallback;

    if (config.defaultTransition == null) {
      config = config.copyWith(defaultTransition: getThemeTransition());
    }

    Future(() => onReady());
  }

  set parameters(Map<String, String?> newParameters) {
    config = config.copyWith(parameters: newParameters);
  }

  set testMode(bool isTest) {
    config = config.copyWith(testMode: isTest);
    SintTestMode.active = isTest;
  }

  void onReady() {
    config.onReady?.call();
  }

  Transition? getThemeTransition() {
    final platform = context.theme.platform;
    final matchingTransition =
        Sint.theme.pageTransitionsTheme.builders[platform];
    switch (matchingTransition) {
      case CupertinoPageTransitionsBuilder():
        return Transition.cupertino;
      case ZoomPageTransitionsBuilder():
        return Transition.zoom;
      case FadeUpwardsPageTransitionsBuilder():
        return Transition.fade;
      case OpenUpwardsPageTransitionsBuilder():
        return Transition.native;
      default:
        return null;
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    Sint.asap(() {
      final locale = Sint.deviceLocale;
      if (locale != null) {
        Sint.updateLocale(locale);
      }
    });
  }

  void setTheme(ThemeData value) {
    if (config.darkTheme == null) {
      config = config.copyWith(theme: value);
    } else {
      if (value.brightness == Brightness.light) {
        config = config.copyWith(theme: value);
      } else {
        config = config.copyWith(darkTheme: value);
      }
    }
    update();
  }

  void setThemeMode(ThemeMode value) {
    config = config.copyWith(themeMode: value);
    update();
  }

  void restartApp() {
    config = config.copyWith(unikey: UniqueKey());
    update();
  }

  void update() {
    context.visitAncestorElements((element) {
      element.markNeedsBuild();
      return false;
    });
  }

  GlobalKey<NavigatorState> get key => rootDelegate.navigatorKey;

  SintDelegate get rootDelegate => config.routerDelegate as SintDelegate;

  RouteInformationParser<Object> get informationParser =>
      config.routeInformationParser!;

  GlobalKey<NavigatorState>? addKey(GlobalKey<NavigatorState> newKey) {
    rootDelegate.navigatorKey = newKey;
    return key;
  }

  Map<String, SintDelegate> keys = {};

  SintDelegate? nestedKey(String? key) {
    if (key == null) {
      return rootDelegate;
    }
    keys.putIfAbsent(
      key,
      () => SintDelegate(
        showHashOnUrl: true,
        //debugLabel: 'SINT nested key: ${key.toString()}',
        pages: RouteDecoder.fromRoute(key).currentChildren ?? [],
      ),
    );
    return keys[key];
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  String cleanRouteName(String name) {
    name = name.replaceAll('() => ', '');

    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return Uri.tryParse(name)?.toString() ?? name;
  }
}
