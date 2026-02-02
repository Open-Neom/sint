import 'package:flutter/material.dart';
import 'package:sint/injection/src/lifecycle.dart';

typedef WidgetCallback = Widget Function();

typedef VoidCallback = void Function();
typedef Disposer = VoidCallback;
typedef SintStateUpdate = VoidCallback;

typedef InitBuilder<T> = T Function();

typedef SintControllerBuilder<T extends SintLifeCycleMixin> = Widget Function(T controller);
