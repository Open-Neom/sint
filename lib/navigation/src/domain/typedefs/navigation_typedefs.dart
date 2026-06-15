import 'package:flutter/material.dart';
// import 'sint_page_route.dart';

typedef GetPageBuilder = Widget Function();
typedef GetRouteAwarePageBuilder<T> = Widget Function([PageRoute<T>? route]);
