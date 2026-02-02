import 'dart:developer' as developer;
import '../sint_main.dart';

/// default logger from SINT
void defaultLogWriterCallback(String value, {bool isError = false}) {
  if (isError || Sint.isLogEnable) developer.log(value, name: 'SINT');
}
