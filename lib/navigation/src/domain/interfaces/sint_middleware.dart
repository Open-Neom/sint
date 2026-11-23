import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:sint/navigation/src/router/route_decoder.dart';

/// The Page Middlewares.
/// The Functions will be called in this order
/// (( [redirect] -> [onPageCalled] -> [onBindingsStart] ->
/// [onPageBuildStart] -> [onPageBuilt] -> [onPageDispose] ))
abstract class SintMiddleware {
  SintMiddleware({this.priority = 0});

  /// The Order of the Middlewares to run.
  ///
  /// {@tool snippet}
  /// This Middewares will be called in this order.
  /// ```dart
  /// final middlewares = [
  ///   SintMiddleware(priority: 2),
  ///   SintMiddleware(priority: 5),
  ///   SintMiddleware(priority: 4),
  ///   SintMiddleware(priority: -8),
  /// ];
  /// ```
  ///  -8 => 2 => 4 => 5
  /// {@end-tool}
  final int priority;

  /// This function will be called when the page of
  /// the called route is being searched for.
  /// It take RouteSettings as a result an redirect to the new settings or
  /// give it null and there will be no redirecting.
  /// {@tool snippet}
  /// ```dart
  /// RouteSettings? redirect(String? route) {
  ///   final authService = Sint.find<AuthService>();
  ///   return authService.authed.value ? null : const RouteSettings(name: '/login');
  /// }
  /// ```
  /// {@end-tool}
  RouteSettings? redirect(String? route) => null;

  /// Similar to [redirect], invoked when the Navigator 2.0 router delegate
  /// evaluates a route transition (supports synchronous or asynchronous guards).
  ///
  /// By default, delegates to [redirect] so synchronous `RouteSettings? redirect(String? route)`
  /// guards work out of the box in both Navigator 1.0 and Navigator 2.0 (`SintApp` / `SintMaterialApp`).
  ///
  /// If this returns `null`, navigation is cancelled and no new route is pushed.
  /// {@tool snippet}
  /// ```dart
  /// @override
  /// FutureOr<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
  ///   final authService = Sint.find<AuthService>();
  ///   return (await authService.isLoggedIn())
  ///       ? route
  ///       : RouteDecoder.fromRoute('/login');
  /// }
  /// ```
  /// {@end-tool}
  FutureOr<RouteDecoder?> redirectDelegate(RouteDecoder route) {
    final currentName = route.pageSettings?.name ?? route.route?.name;
    final redirected = redirect(currentName);
    final nextName = redirected?.name;
    if (nextName != null && nextName.isNotEmpty && nextName != currentName) {
      return RouteDecoder.fromRoute(nextName, redirected?.arguments);
    }
    return route;
  }

  /// This function will be called when this Page is called
  /// you can use it to change something about the page or give it new page
  /// {@tool snippet}
  /// ```dart
  /// SintPage onPageCalled(SintPage page) {
  ///   final authService = Sint.find<AuthService>();
  ///   return page.copyWith(title: 'Welcome ${authService.userName}');
  /// }
  /// ```
  /// {@end-tool}
  dynamic onPageCalled(dynamic page) => page;

  /// This function will be called right before the [BindingsInterface] are initialize.
  /// Here you can change [BindingsInterface] for this page
  /// {@tool snippet}
  /// ```dart
  /// List<BindingsInterface> onBindingsStart(List<BindingsInterface> bindings) {
  ///   final authService = Sint.find<AuthService>();
  ///   if (authService.isAdmin) {
  ///     bindings.add(AdminBinding());
  ///   }
  ///   return bindings;
  /// }
  /// ```
  /// {@end-tool}
  List<R>? onBindingsStart<R>(List<R>? bindings) => bindings;

  /// This function will be called right after the [BindingsInterface] are initialize.
  Widget Function()? onPageBuildStart(Widget Function()? page) => page;

  /// This function will be called right after the
  /// SintPage.page function is called and will give you the result
  /// of the function. and take the widget that will be showed.
  Widget onPageBuilt(Widget page) => page;

  void onPageDispose() {}
}
