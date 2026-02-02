import 'package:sint/navigation/src/ui/widgets/sint_back_gesture_controller.dart';
import 'package:sint/sint.dart';

// --- LEGACY GETX ALIASES (Migration to Sint Ecosystem) ---

@Deprecated('Use SintController instead. GetxController is deprecated in the Sint ecosystem.')
typedef GetxController = SintController;

@Deprecated('Use SintInformationParser instead. Part of the legacy GetX navigation system.')
typedef GetInformationParser = SintInformationParser;

@Deprecated('Use SintNavigator instead. Part of the legacy GetX navigation system.')
typedef GetNavigator = SintNavigator;

@Deprecated('Use SintPage instead. Part of the legacy GetX navigation system.')
typedef GetPage<T> = SintPage<T>;

@Deprecated('Use SintPageRoute instead. Part of the legacy GetX navigation system.')
typedef GetPageRoute<T> = SintPageRoute<T>;

@Deprecated('Use SintDelegate instead. Part of the legacy GetX navigation system.')
typedef GetDelegate = SintDelegate;

@Deprecated('Use SintModalBottomSheetLayout instead. Part of the legacy GetX UI components.')
typedef GetModalBottomSheetLayout = SintModalBottomSheetLayout;

@Deprecated('Use SintModalBottomSheetRoute instead. Part of the legacy GetX UI components.')
typedef GetModalBottomSheetRoute<T> = SintModalBottomSheetRoute<T>;

@Deprecated('Use SintDialogRoute instead. Part of the legacy GetX UI components.')
typedef GetDialogRoute<T> = SintDialogRoute<T>;

@Deprecated('Use SintSnackBar instead. Part of the legacy GetX UI components.')
typedef GetSnackBar = SintSnackBar;

@Deprecated('Use SintSnackBarState instead. Part of the legacy GetX UI components.')
typedef GetSnackBarState = SintSnackBarState;

@Deprecated('Use SintBackGestureDetector instead. Part of the legacy GetX gesture system.')
typedef GetBackGestureDetector<T> = SintBackGestureDetector<T>;

@Deprecated('Use SintBackGestureDetectorState instead. Part of the legacy GetX gesture system.')
typedef GetBackGestureDetectorState<T> = SintBackGestureDetectorState<T>;

@Deprecated('Use SintBackGestureController instead. Part of the legacy GetX gesture system.')
typedef GetBackGestureController<T> = SintBackGestureController<T>;

@Deprecated('Use SintBuilder instead. Use Sint-based state management widgets.')
typedef GetBuilder<T extends SintController> = SintBuilder<T>;

@Deprecated('Use SintTickerProviderStateMixin instead. Part of the Sint animation and state management system.')
typedef GetTickerProviderStateMixin = SintTickerProviderStateMixin;