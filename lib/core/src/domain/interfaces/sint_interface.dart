import 'package:flutter/foundation.dart';
import 'package:sint/core/src/domain/typedefs/core_typedefs.dart';
import 'package:sint/core/src/domain/enums/smart_management.dart';

import '../../utils/log.dart';

/// SintInterface allows any auxiliary package to be merged into the "SINT"
/// class through extensions
abstract class SintInterface {
  SmartManagement smartManagement = SmartManagement.full;
  bool isLogEnable = kDebugMode;
  LogWriterCallback log = defaultLogWriterCallback;
}
