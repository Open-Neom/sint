import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/sint_injection.dart';
import 'package:sint/navigation/src/router/sint_test_mode.dart';
import 'package:sint/navigation/src/ui/snackbar/snackbar_controller.dart';
import 'package:sint/translation/src/domain/extensions/locale_extension.dart';

extension SintReset on SintInterface {
  void reset({bool clearRouteBindings = true}) {
    SnackbarController.disposeFallbackQueue();
    Sint.resetInstance(clearRouteBindings: clearRouteBindings);
    Sint.clearTranslations();
    Sint.locale = null;
    Sint.fallbackLocale = null;
    Sint.pathTranslator = null;
    SintTestMode.reset();
  }
}
