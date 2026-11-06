import 'package:sint/injection/src/lifecycle.dart';

/// Base class for long-lived, application-wide services in Pillar I (Injection).
///
/// Unlike `SintController` (whose lifecycle is tied to routes unless marked
/// `permanent: true` or `fenix: true`), a [SintService] defaults to
/// **`permanent: true`** when registered via `Sint.put`, `Sint.putAsync`, or
/// `Sint.lazyPut`, surviving route pops and `Sint.deleteAll(force: false)`
/// until `Sint.delete<MyService>(force: true)` or `Sint.reset()` is called.
///
/// ```dart
/// class AuthService extends SintService {
///   Future<AuthService> init() async {
///     await restoreSession();
///     return this;
///   }
/// }
///
/// await Sint.putAsync(() => AuthService().init());
/// ```
abstract class SintService with SintLifeCycleMixin {}
