import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/sint_injection.dart';
import 'package:sint/translation/src/domain/extensions/locale_extension.dart';

extension SintReset on SintInterface {
  void reset({bool clearRouteBindings = true}) {
    Sint.resetInstance(clearRouteBindings: clearRouteBindings);
    Sint.clearTranslations();
  }
}
