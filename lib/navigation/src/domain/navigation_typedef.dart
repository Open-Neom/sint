import 'package:sint/navigation/src/domain/enums/snack_hover_state.dart';
import 'package:sint/navigation/src/domain/enums/snackbar_status.dart';
import 'package:sint/navigation/src/ui/snackbar/snackbar.dart';

typedef OnTap = void Function(SintSnackBar snack);
typedef OnHover = void Function(
    SintSnackBar snack, SnackHoverState snackHoverState);

typedef SnackbarStatusCallback = void Function(SnackbarStatus? status);