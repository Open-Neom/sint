import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/src/lifecycle.dart';
import 'package:sint/injection/src/domain/typedefs/injection_typedefs.dart';
import 'package:sint/injection/src/domain/models/instance_info.dart';
import 'package:sint/injection/src/domain/models/route_dependency.dart';
import 'package:sint/navigation/src/router/router_report_manager.dart';

extension InjectionExtension on SintInterface {
  T call<T>() => find<T>();

  /// Active factories indexed by opaque handles for legacy string-key callers.
  static final Map<String, _InstanceBuilderFactory> _singl = {};
  static final Map<String, Set<_InstanceBuilderFactory>> _legacySingl = {};
  static int _nextHandle = 0;

  /// Type-keyed injection registry (O5a - SINT 1.6.0)
  /// Provides O(1) type-identity lookups, eliminating string concatenation
  /// overhead and dart2js minification collision risk.
  static final Map<Type, Map<String?, _InstanceBuilderFactory>> _typeSingl = {};

  /// Exposes the registered dependency keys for internal use (e.g. selective cleanup).
  static Iterable<String> get registeredKeys => _singl.values.map((factory) =>
      _legacySingl[factory.legacyKey]!.length == 1
          ? factory.legacyKey
          : factory.handle);

  /// Resolves the actual registered type, including disambiguated handles.
  static Type? registeredTypeForKey(String key) =>
      _factoryForKey(key)?.registeredType;

  /// Keeps an instance across a navigation reset without making it permanent.
  /// Existing route and Binder disposal callbacks no longer own this instance.
  static void detachInstanceFromOwners(String key) {
    final factory = _factoryForKey(key);
    if (factory != null) {
      factory.generation = Object();
      factory.isDirty = false;
    }
  }

  /// Captures the current generation for the widget that owns its lifetime.
  RouteDependency? captureInstanceLifecycle<S>({String? tag}) {
    final factory = _typeSingl[S]?[tag];
    return factory == null
        ? null
        : _routeDependency(factory, factory.generation);
  }

  /// Captures the currently registered generation for legacy route reporters.
  static RouteDependency? routeDependencyForKey(String key) {
    final factory = _factoryForKey(key);
    return factory == null
        ? null
        : _routeDependency(factory, factory.generation);
  }

  static RouteDependency _routeDependency(
          _InstanceBuilderFactory factory, Object? generation) =>
      RouteDependency(
        markAsDirty: () {
          if (identical(factory.generation, generation) && !factory.permanent) {
            factory.isDirty = true;
          }
        },
        delete: () =>
            identical(factory.generation, generation) &&
            _deleteFactory(factory),
      );

  static _InstanceBuilderFactory? _factoryForKey(String key) {
    // A Dart type name cannot begin with '@', so handles cannot be confused
    // with the historical type.toString() + tag format.
    if (key.startsWith('@sint/')) return _singl[key];
    final matches = _legacySingl[key];
    if (matches == null || matches.isEmpty) return null;
    if (matches.length > 1) {
      throw StateError('Ambiguous dependency key "$key". Use a type and tag '
          'or a handle from InjectionExtension.registeredKeys.');
    }
    return matches.single;
  }

  static void _unregister(_InstanceBuilderFactory factory) {
    final tags = _typeSingl[factory.registeredType];
    if (identical(tags?[factory.tag], factory)) {
      tags!.remove(factory.tag);
      if (tags.isEmpty) _typeSingl.remove(factory.registeredType);
    }
    _singl.remove(factory.handle);
    final legacy = _legacySingl[factory.legacyKey];
    legacy?.remove(factory);
    if (legacy?.isEmpty ?? false) _legacySingl.remove(factory.legacyKey);
  }

  ///
  S put<S>(
    S dependency, {
    String? tag,
    bool permanent = false,
  }) {
    _insert(
        isSingleton: true,
        name: tag,
        permanent: permanent,
        builder: (() => dependency));
    return find<S>(tag: tag);
  }

  /// Creates a new Instance<S> lazily from the `<S>builder()` callback.
  ///
  /// The first time you call `Sint.find()`, the `builder()` callback will create
  /// the Instance and persisted as a Singleton (like you would
  /// use `Sint.put()`).
  ///
  /// Using `Sint.smartManagement` as [SmartManagement.keepFactory] has
  /// the same outcome as using `fenix:true` :
  /// The internal register of `builder()` will remain in memory to recreate
  /// the Instance if the Instance has been removed with `Sint.delete()`.
  /// Therefore, future calls to `Sint.find()` will return the same Instance.
  ///
  /// If you need to make use of SintController's life-cycle
  /// (`onInit(), onStart(), onClose()`) [fenix] is a great choice to mix with
  /// `SintBuilder()` and `SINT()` ui, and/or `SintMaterialApp` Navigation.
  ///
  /// You could use `Sint.lazyPut(fenix:true)` in your app's `main()` instead
  /// of `Bindings()` for each `SintPage`.
  /// And the memory management will be similar.
  ///
  /// Subsequent calls to `Sint.lazyPut()` with the same parameters
  /// (<[S]> and optionally [tag] will **not** override the original).
  void lazyPut<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool fenix = false,
    bool permanent = false,
  }) {
    _insert(
      isSingleton: true,
      name: tag,
      permanent: permanent,
      builder: builder,
      fenix: fenix,
    );
  }

  /// Creates a new Class Instance [S] from the builder callback[S].
  /// Every time [find]<[S]>() is used, it calls the builder method to generate
  /// a new Instance [S].
  /// It also registers each `instance.onClose()` with the current
  /// Route `Sint.reference` to keep the lifecycle active.
  /// Is important to know that the instances created are only stored per Route.
  /// So, if you call `Sint.delete<T>()` the "instance factory" used in this
  /// method (`Sint.spawn<T>()`) will be removed, but NOT the instances
  /// already created by it.
  ///
  /// Example:
  ///
  /// ```Sint.spawn(() => Repl());
  /// Repl a = find();
  /// Repl b = find();
  /// print(a==b); (false)```
  void spawn<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = true,
  }) {
    _insert(
      isSingleton: false,
      name: tag,
      builder: builder,
      permanent: permanent,
    );
  }

  /// Registers a dependency that requires **async initialization**.
  ///
  /// The [asyncBuilder] is executed immediately and the instance is stored
  /// once the Future completes. After `await putAsync(...)`, the instance
  /// is available via `Sint.find<S>()` like any other singleton.
  ///
  /// Useful for: SharedPreferences, database connections, HTTP clients, etc.
  ///
  /// ```dart
  /// await Sint.putAsync<SharedPreferences>(
  ///   () => SharedPreferences.getInstance(),
  /// );
  /// // Later:
  /// final prefs = Sint.find<SharedPreferences>();
  /// ```
  Future<S> putAsync<S>(
    Future<S> Function() asyncBuilder, {
    String? tag,
    bool permanent = false,
  }) async {
    final instance = await asyncBuilder();
    return put<S>(instance, tag: tag, permanent: permanent);
  }

  /// Injects the Instance [S] builder into the `_singleton` HashMap.
  void _insert<S>({
    required InstanceBuilderCallback<S> builder,
    bool? isSingleton,
    String? name,
    bool fenix = false,
    bool permanent = false,
  }) {
    final key = _getKey(S, name);

    final existing = _typeSingl[S]?[name];
    if (existing != null) {
      if (!existing.isDirty) {
        return;
      } else {
        // Its route still owns the old generation until route disposal.
        _unregister(existing);
      }
    }
    final factory = _InstanceBuilderFactory<S>(
      isSingleton: isSingleton,
      builderFunc: builder,
      permanent: permanent,
      isInit: false,
      fenix: fenix,
      tag: name,
      handle: '@sint/${_nextHandle++}',
      legacyKey: key,
    );
    _typeSingl.putIfAbsent(S, () => {})[name] = factory;
    _singl[factory.handle] = factory;
    _legacySingl.putIfAbsent(key, () => {}).add(factory);
  }

  /// Initializes the dependencies for a Class Instance [S] (or tag),
  /// If its a Controller, it starts the lifecycle process.
  /// Optionally associating the current Route to the lifetime of the instance,
  /// if `Sint.smartManagement` is marked as [SmartManagement.full] or
  /// [SmartManagement.keepFactory]
  /// Only flags `isInit` if it's using `Sint.create()`
  /// (not for Singletons access).
  /// Returns the instance if not initialized, required for Sint.create() to
  /// work properly.
  S? _initDependencies<S>(
      {String? name, required _InstanceBuilderFactory dep}) {
    if (dep.isInit) {
      return null;
    }
    final isSingleton = dep.isSingleton ?? false;
    final generation = Object();
    if (isSingleton) {
      dep.isInit = true;
      dep.generation = generation;
    }
    try {
      final i = _startController<S>(tag: name, factory: dep);
      if (isSingleton && identical(dep.generation, generation)) {
        if (Sint.smartManagement != SmartManagement.onlyBuilder) {
          RouterReportManager.instance.reportDependencyLinkedToRoute(
            _routeDependency(dep, generation),
          );
        }
      }
      return i;
    } catch (_) {
      if (identical(dep.generation, generation)) {
        dep.isInit = false;
        dep.generation = null;
      }
      rethrow;
    }
  }

  InstanceInfo getInstanceInfo<S>({String? tag}) {
    final build = _getDependency<S>(tag: tag);

    return InstanceInfo(
      isPermanent: build?.permanent,
      isSingleton: build?.isSingleton,
      isRegistered: isRegistered<S>(tag: tag),
      isPrepared: !(build?.isInit ?? true),
      isInit: build?.isInit,
    );
  }

  _InstanceBuilderFactory? _getDependency<S>({String? tag, String? key}) {
    _InstanceBuilderFactory? dep;
    if (key != null) {
      dep = _factoryForKey(key);
    } else {
      dep = _typeSingl[S]?[tag];
    }
    if (dep == null) {
      final logKey = key ?? _getKey(S, tag);
      Sint.log('Instance "$logKey" is not registered.', isError: true);
      return null;
    }
    return dep;
  }

  void markAsDirty<S>({String? tag, String? key}) {
    final dep = key != null ? _factoryForKey(key) : _typeSingl[S]?[tag];
    if (dep != null && !dep.permanent) {
      dep.isDirty = true;
    }
  }

  /// Initializes the controller
  S _startController<S>(
      {String? tag, required _InstanceBuilderFactory factory}) {
    final i = factory.getDependency() as S;
    if (i is SintLifeCycleMixin) {
      i.onStart();
      if (Sint.isLogEnable) {
        if (tag == null) {
          Sint.log('Instance "$S" has been initialized');
        } else {
          Sint.log('Instance "$S" with tag "$tag" has been initialized');
        }
      }
      if (!factory.isSingleton!) {
        RouterReportManager.instance.appendRouteByCreate(i);
      }
    }
    return i;
  }

  S putOrFind<S>(InstanceBuilderCallback<S> dep, {String? tag}) {
    final factory = _typeSingl[S]?[tag];
    if (factory != null) {
      return find<S>(tag: tag);
    } else {
      return put(dep(), tag: tag);
    }
  }

  /// Finds the registered type <[S]> (or [tag])
  /// In case of using Sint.[create] to register a type <[S]> or [tag],
  /// it will create an instance each time you call [find].
  /// If the registered type <[S]> (or [tag]) is a Controller,
  /// it will initialize it's lifecycle.
  S find<S>({String? tag}) {
    final dep = _typeSingl[S]?[tag];
    if (dep == null) {
      // ignore: lines_longer_than_80_chars
      throw '"$S" not found. You need to call "Sint.put($S())" or "Sint.lazyPut(()=>$S())"';
    }

    /// although dirty solution, the lifecycle starts inside
    /// `initDependencies`, so we have to return the instance from there
    /// to make it compatible with `Sint.create()`.
    final i = _initDependencies<S>(name: tag, dep: dep);
    return (i ?? dep.getDependency()) as S;
  }

  /// The findOrNull method will return the instance if it is registered;
  /// otherwise, it will return null.
  S? findOrNull<S>({String? tag}) {
    if (isRegistered<S>(tag: tag)) {
      return find<S>(tag: tag);
    }
    return null;
  }

  /// Replace a parent instance of a class in dependency management
  /// with a [child] instance
  /// - [tag] optional, if you use a [tag] to register the Instance.
  void replace<P>(P child, {String? tag}) {
    final info = getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    final factory = _typeSingl[P]?[tag];
    if (factory != null) {
      _deleteFactory(factory, force: permanent, keepFactory: false);
    }
    put<P>(child, tag: tag, permanent: permanent);
  }

  /// Replaces a parent instance with a new Instance<P> lazily from the
  /// `<P>builder()` callback.
  /// - [tag] optional, if you use a [tag] to register the Instance.
  /// - [fenix] optional
  ///
  ///  Note: if fenix is not provided it will be set to true if
  /// the parent instance was permanent
  void lazyReplace<P>(InstanceBuilderCallback<P> builder,
      {String? tag, bool? fenix}) {
    final info = getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    final factory = _typeSingl[P]?[tag];
    if (factory != null) {
      _deleteFactory(factory, force: permanent, keepFactory: false);
    }
    lazyPut<P>(builder, tag: tag, fenix: fenix ?? permanent);
  }

  /// Generates the key based on [type] (and optionally a [name])
  /// to register an Instance Builder in the hashmap.
  String _getKey(Type type, String? name) {
    return name == null ? type.toString() : type.toString() + name;
  }

  /// Delete registered Class Instance [S] (or [tag]) and, closes any open
  /// controllers `DisposableInterface`, cleans up the memory
  ///
  /// /// Deletes the Instance<[S]>, cleaning the memory.
  //  ///
  //  /// - [tag] Optional "tag" used to register the Instance
  //  /// - [key] For internal usage, is the processed key used to register
  //  ///   the Instance. **don't use** it unless you know what you are doing.

  /// Deletes the Instance<[S]>, cleaning the memory and closes any open
  /// controllers (`DisposableInterface`).
  ///
  /// - [tag] Optional "tag" used to register the Instance
  /// - [key] For internal usage, is the processed key used to register
  ///   the Instance. **don't use** it unless you know what you are doing.
  /// - [force] Will delete an Instance even if marked as `permanent`.
  bool delete<S>({String? tag, String? key, bool force = false}) {
    final dep = key == null ? (_typeSingl[S]?[tag]) : _factoryForKey(key);
    if (dep == null) {
      return false;
    }
    if (key != null &&
        ((S != dynamic && dep.registeredType != S) ||
            (tag != null && dep.tag != tag))) {
      throw ArgumentError(
          'Dependency key does not match the supplied type/tag');
    }
    return _deleteFactory(dep, force: force);
  }

  static bool _deleteFactory(_InstanceBuilderFactory factory,
      {bool force = false, bool keepFactory = true}) {
    if (factory.permanent && !force) {
      Sint.log(
        '"${factory.legacyKey}" has been marked as permanent, '
        'SmartManagement is not authorized to delete it.',
        isError: true,
      );
      return false;
    }
    final i = factory.dependency;
    final active =
        identical(_typeSingl[factory.registeredType]?[factory.tag], factory);
    // Invalidate ownership before user callbacks. onClose may register or
    // resolve another instance of this same type, including a fenix revival.
    factory.dependency = null;
    factory.isInit = false;
    factory.isDirty = false;
    factory.generation = null;
    if (!keepFactory || !factory.fenix || !active) _unregister(factory);
    if (i is SintLifeCycleMixin) {
      i.onDelete();
      if (Sint.isLogEnable) {
        Sint.log('"${factory.legacyKey}" onDelete() called');
      }
    }
    return true;
  }

  /// Delete all registered Class Instances and, closes any open
  /// controllers `DisposableInterface`, cleans up the memory
  ///
  /// - [force] Will delete the Instances even if marked as `permanent`.
  void deleteAll({bool force = false}) {
    final factories = _singl.values.toList();
    for (final factory in factories) {
      _deleteFactory(factory, force: force);
    }
  }

  void reloadAll({bool force = false}) {
    for (final factory in _singl.values.toList()) {
      _reloadFactory(factory, force: force);
    }
  }

  void reload<S>({
    String? tag,
    String? key,
    bool force = false,
  }) {
    final builder = _getDependency<S>(tag: tag, key: key);
    if (builder == null) return;
    if (key != null &&
        ((S != dynamic && builder.registeredType != S) ||
            (tag != null && builder.tag != tag))) {
      throw ArgumentError(
          'Dependency key does not match the supplied type/tag');
    }
    _reloadFactory(builder, force: force);
  }

  void _reloadFactory(_InstanceBuilderFactory builder, {bool force = false}) {
    if (builder.permanent && !force) {
      Sint.log(
        'Instance "${builder.legacyKey}" is permanent. '
        'Use [force = true] to force the restart.',
        isError: true,
      );
      return;
    }

    final i = builder.dependency;
    builder.dependency = null;
    builder.isInit = false;
    builder.isDirty = false;
    builder.generation = null;
    if (i is SintLifeCycleMixin) {
      i.onDelete();
    }
  }

  /// Check if a Class Instance<[S]> (or [tag]) is registered in memory.
  /// - [tag] is optional, if you used a [tag] to register the Instance.
  bool isRegistered<S>({String? tag}) =>
      _typeSingl[S]?.containsKey(tag) ?? false;

  /// Checks if a lazy factory callback `Sint.lazyPut()` that returns an
  /// Instance<[S]> is registered in memory.
  /// - [tag] is optional, if you used a [tag] to register the lazy Instance.
  bool isPrepared<S>({String? tag}) {
    final builder = _getDependency<S>(tag: tag);
    if (builder == null) {
      return false;
    }

    if (!builder.isInit) {
      return true;
    }
    return false;
  }

  /// Clears all registered instances (and/or tags).
  /// Even the persistent ones.
  /// This should be used at the end or tearDown of unit tests.
  ///
  /// `clearFactory` clears the callbacks registered by [lazyPut]
  /// `clearRouteBindings` clears Instances associated with router.
  ///
  bool resetInstance({bool clearRouteBindings = true}) {
    if (clearRouteBindings) RouterReportManager.instance.clearRouteKeys();
    _typeSingl.clear();
    InjectionExtension._singl.clear();
    _legacySingl.clear();
    return true;
  }
}

/// Internal class to register instances with `Sint.put<S>()`.
class _InstanceBuilderFactory<S> {
  /// The reified generic type S registered in this factory.
  Type get registeredType => S;

  /// Marks the Builder as a single instance.
  /// For reusing [dependency] instead of [builderFunc]
  bool? isSingleton;

  /// When fenix mode is available, when a new instance is need
  /// Instance manager will recreate a new instance of S
  bool fenix;

  /// Stores the actual object instance when [isSingleton]=true.
  S? dependency;

  /// Generates (and regenerates) the instance when [isSingleton]=false.
  /// Usually used by factory methods
  InstanceBuilderCallback<S> builderFunc;

  /// Flag to persist the instance in memory,
  /// without considering `Sint.smartManagement`
  bool permanent = false;

  bool isInit = false;

  /// Distinguishes successive initializations of a retained fenix factory.
  Object? generation;

  final String handle;
  final String legacyKey;

  bool isDirty = false;

  String? tag;

  _InstanceBuilderFactory({
    required this.isSingleton,
    required this.builderFunc,
    required this.permanent,
    required this.isInit,
    required this.fenix,
    required this.tag,
    required this.handle,
    required this.legacyKey,
  });

  void _showInitLog() {
    if (tag == null) {
      Sint.log('Instance "$S" has been created');
    } else {
      Sint.log('Instance "$S" has been created with tag "$tag"');
    }
  }

  /// Gets the actual instance by it's [builderFunc] or the persisted instance.
  S getDependency() {
    if (isSingleton!) {
      if (dependency == null) {
        _showInitLog();
        dependency = builderFunc();
      }
      return dependency!;
    } else {
      return builderFunc();
    }
  }
}
