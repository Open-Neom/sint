import 'package:flutter/material.dart';

typedef SintPageBuilder = Widget Function();
typedef SintRouteAwarePageBuilder<T> = Widget Function([PageRoute<T>? route]);

@Deprecated('Use SintPageBuilder instead. Will be removed in SINT 3.0.0.')
typedef GetPageBuilder = SintPageBuilder;

@Deprecated('Use SintRouteAwarePageBuilder instead. Will be removed in SINT 3.0.0.')
typedef GetRouteAwarePageBuilder<T> = SintRouteAwarePageBuilder<T>;
