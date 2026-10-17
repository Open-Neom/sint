import 'package:sint/navigation/sint_navigation.dart';
import 'package:sint/navigation/src/ui/widgets/sint_back_gesture_controller.dart';
import 'package:sint/state_manager/sint_state_manager.dart';

// --- LEGACY GETX ALIASES (Migration to Sint Ecosystem — Removed in SINT 3.0.0) ---

@Deprecated('Use SintController instead. Will be removed in SINT 3.0.0.')
typedef GetxController = SintController;

@Deprecated('Use SintMaterialApp or SintApp instead. Will be removed in SINT 3.0.0.')
typedef GetMaterialApp = SintMaterialApp;

@Deprecated('Use SintCupertinoApp or SintApp instead. Will be removed in SINT 3.0.0.')
typedef GetCupertinoApp = SintCupertinoApp;

@Deprecated('Use SintInformationParser instead. Will be removed in SINT 3.0.0.')
typedef GetInformationParser = SintInformationParser;

@Deprecated('Use SintNavigator instead. Will be removed in SINT 3.0.0.')
typedef GetNavigator = SintNavigator;

@Deprecated('Use SintPage instead. Will be removed in SINT 3.0.0.')
typedef GetPage<T> = SintPage<T>;

@Deprecated('Use SintPageRoute instead. Will be removed in SINT 3.0.0.')
typedef GetPageRoute<T> = SintPageRoute<T>;

@Deprecated('Use SintDelegate instead. Will be removed in SINT 3.0.0.')
typedef GetDelegate = SintDelegate;

@Deprecated('Use SintModalBottomSheetLayout instead. Will be removed in SINT 3.0.0.')
typedef GetModalBottomSheetLayout = SintModalBottomSheetLayout;

@Deprecated('Use SintModalBottomSheetRoute instead. Will be removed in SINT 3.0.0.')
typedef GetModalBottomSheetRoute<T> = SintModalBottomSheetRoute<T>;

@Deprecated('Use SintDialogRoute instead. Will be removed in SINT 3.0.0.')
typedef GetDialogRoute<T> = SintDialogRoute<T>;

@Deprecated('Use SintSnackBar instead. Will be removed in SINT 3.0.0.')
typedef GetSnackBar = SintSnackBar;

@Deprecated('Use SintSnackBarState instead. Will be removed in SINT 3.0.0.')
typedef GetSnackBarState = SintSnackBarState;

@Deprecated('Use SintBackGestureDetector instead. Will be removed in SINT 3.0.0.')
typedef GetBackGestureDetector<T> = SintBackGestureDetector<T>;

@Deprecated('Use SintBackGestureDetectorState instead. Will be removed in SINT 3.0.0.')
typedef GetBackGestureDetectorState<T> = SintBackGestureDetectorState<T>;

@Deprecated('Use SintBackGestureController instead. Will be removed in SINT 3.0.0.')
typedef GetBackGestureController<T> = SintBackGestureController<T>;

@Deprecated('Use SintBuilder instead. Will be removed in SINT 3.0.0.')
typedef GetBuilder<T extends SintController> = SintBuilder<T>;

@Deprecated('Use SintTickerProviderStateMixin instead. Will be removed in SINT 3.0.0.')
typedef GetTickerProviderStateMixin = SintTickerProviderStateMixin;