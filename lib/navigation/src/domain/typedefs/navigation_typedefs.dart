import 'package:flutter/material.dart';
import 'package:sint/navigation/src/router/sint_page_route.dart';

typedef GetPageBuilder = Widget Function();
typedef GetRouteAwarePageBuilder<T> = Widget Function([SintPageRoute<T>? route]);
