
import 'package:sint/state_manager/src/domain/typedefs/state_typedefs.dart';

class NotifyData {
  const NotifyData(
      {required this.updater,
        required this.disposers,
        this.throwException = true});
  final SintStateUpdate updater;
  final List<VoidCallback> disposers;
  final bool throwException;
}