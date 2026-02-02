//TODO: Use copyWith, and remove mutate variables
import 'package:flutter/material.dart';

class Routing {
  String current;
  String previous;
  dynamic args;
  String removed;
  Route<dynamic>? route;
  bool? isBack;
  bool? isBottomSheet;
  bool? isDialog;

  Routing({
    this.current = '',
    this.previous = '',
    this.args,
    this.removed = '',
    this.route,
    this.isBack,
    this.isBottomSheet,
    this.isDialog,
  });

  void update(void Function(Routing value) fn) {
    fn(this);
  }
}