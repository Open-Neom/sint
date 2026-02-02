import 'package:flutter/widgets.dart';

class SintEngine {
  static WidgetsBinding get instance {
    return WidgetsFlutterBinding.ensureInitialized();
  }
}
