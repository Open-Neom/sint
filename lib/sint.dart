/// # SINT Framework 1.0.0
/// Extra-light and powerful multi-platform framework.
/// It combines high performance state management, intelligent dependency
/// injection, route management in a practical way and quick translations.
///
/// ## Getting Started
/// ```dart
/// import 'package:sint/sint.dart';
///
/// // Preferred API (no warnings):
/// Sint.find<MyController>();
/// Sint.toNamed('/home');
///
/// // Legacy compatibility (deprecated):
/// Get.find<MyController>(); // ⚠️ Shows deprecation warning
/// ```
///
/// ## Migration from GetX
/// - Replace `get:` with `sint:` in pubspec.yaml
/// - Your existing `Get.` calls will work with warnings
/// - Gradually replace `Get.` with `Sint.` to remove warnings
library;

export 'state_manager/sint_state_manager.dart';
export 'injection/sint_injection.dart';
export 'navigation/sint_navigation.dart';
export 'translation/sint_translation.dart';
export 'core/sint_core.dart';
