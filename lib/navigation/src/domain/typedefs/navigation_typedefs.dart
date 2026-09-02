import 'package:flutter/material.dart';

typedef SintPageBuilder = Widget Function();
typedef SintRouteAwarePageBuilder<T> = Widget Function([PageRoute<T>? route]);

@Deprecated('Use SintPageBuilder instead. Part of the legacy GetX navigation system.')
typedef GetPageBuilder = SintPageBuilder;

@Deprecated('Use SintRouteAwarePageBuilder instead. Part of the legacy GetX navigation system.')
typedef GetRouteAwarePageBuilder<T> = SintRouteAwarePageBuilder<T>;
