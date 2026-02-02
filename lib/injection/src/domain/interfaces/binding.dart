import 'package:sint/injection/src/bind.dart';
import 'package:sint/injection/src/domain/interfaces/bindings_interface.dart';

/// [Binding] should be extended.
/// When using `SintMaterialApp`, all `SintPage`s and navigation
/// methods (like Sint.to()) have a `binding` property that takes an
/// instance of Bindings to manage the
/// dependencies() (via Sint.put()) for the Route you are opening.
abstract class Binding extends BindingsInterface<List<Bind>> {}