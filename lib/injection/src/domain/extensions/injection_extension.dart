import 'dart:async';

import 'package:sint/core/sint_core.dart';
import 'package:sint/injection/src/lifecycle.dart';
import 'package:sint/injection/src/sint_service.dart';
import 'package:sint/injection/src/domain/typedefs/injection_typedefs.dart';
import 'package:sint/injection/src/domain/models/instance_info.dart';
import 'package:sint/injection/src/domain/models/route_dependency.dart';
import 'package:sint/navigation/src/router/router_report_manager.dart';

/// Describes a scoped dependency override supplied to `SintScope`.
class SintOverride<S> {
  SintOverride._({
    required InstanceBuilderCallback<S> builder,
    required bool isLazy,
    this.tag,
    this.aliases,
    this.bindUntaggedDefault = false,
  }) :
        // ignore: prefer_initializing_formals
        _builder = builder,
        // ignore: prefer_initializing_formals
        _isLazy = isLazy;

  /// Overrides `T` (and optional [tag] / [aliases]) with an eager [instance]
  /// within a `SintScope`.
  static SintOverride<T> value<T>(
    T instance, {
    String? tag,
    List<Type>? aliases,
  }) =>
      SintOverride<T>._(
        builder: () => instance,
        isLazy: false,
        tag: tag,
        aliases: aliases,
      );

  /// Overrides `T` (and optional [tag] / [aliases]) with a lazy [builder]
  /// within a `SintScope`.
  static SintOverride<T> lazy<T>(
    InstanceBuilderCallback<T> builder, {
    String? tag,
    List<Type>? aliases,
  }) =>
      SintOverride<T>._(
        builder: builder,
        isLazy: true,
        tag: tag,
        aliases: aliases,
      );

  /// Lazy contract-first scoped override: binds both service contract [S] and
  /// concrete implementation [I] to the same scoped singleton within `SintScope`.
  static SintOverride<S> contract<S, I extends S>(
    InstanceBuilderCallback<I> builder, {
    String? tag,
    bool isDefault = false,
    List<Type>? aliases,
  }) =>
      SintOverride<S>._(
        builder: builder,
        isLazy: true,
        tag: tag,
        bindUntaggedDefault: tag != null && isDefault,
        aliases: <Type>[
          if (I != S) I,
          ...?aliases,
        ],
      );

  /// Eager contract-first scoped override: binds [instance] under both service
  /// contract [S] and concrete implementation [I] within `SintScope`.
  static SintOverride<S> contractValue<S, I extends S>(
    I instance, {
    String? tag,
    bool isDefault = false,
    List<Type>? aliases,
  }) =>
      SintOverride<S>._(
        builder: () => instance,
        isLazy: false,
        tag: tag,
        bindUntaggedDefault: tag != null && isDefault,
        aliases: <Type>[
          if (I != S) I,
          ...?aliases,
        ],
      );

  final InstanceBuilderCallback<S> _builder;
  final bool _isLazy;
  final String? tag;
  final List<Type>? aliases;
  final bool bindUntaggedDefault;

  Type get overrideType => S;

  _InstanceBuilderFactory<S> _createFactory() {
    final factory = _InstanceBuilderFactory<S>(
      isSingleton: true,
      builderFunc: _builder,
      permanent: true,
      isInit: false,
      fenix: false,
      tag: tag,
    );
    if (!_isLazy) {
      final instance = factory.getDependency();
      factory.isInit = true;
      factory.generation = Object();
      if (instance is SintLifeCycleMixin) {
        instance.onStart();
      }
    }
    return factory;
  }
}

/// Internal container holding scoped overrides for a single `SintScope`.
class SintScopeContainer {
  SintScopeContainer(Iterable<SintOverride<dynamic>> overrides) {
    for (final override in overrides) {
      final factory = override._createFactory();
      final primaryMap = (_factories[override.overrideType] ??=
          <String?, _InstanceBuilderFactory>{});
      primaryMap[override.tag] = factory;
      if (override.tag != null &&
          (override.bindUntaggedDefault || !primaryMap.containsKey(null))) {
        primaryMap[null] = factory;
      }
      final extraTypes = override.aliases;
      if (extraTypes != null) {
        for (final alias in extraTypes) {
          final aliasMap =
              (_factories[alias] ??= <String?, _InstanceBuilderFactory>{});
          aliasMap[override.tag] = factory;
          if (override.tag != null &&
              (override.bindUntaggedDefault || !aliasMap.containsKey(null))) {
            aliasMap[null] = factory;
          }
        }
      }
    }
  }

  final Map<Type, Map<String?, _InstanceBuilderFactory>> _factories = {};
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final visited = Set<_InstanceBuilderFactory>.identity();
    for (final tagMap in _factories.values) {
      for (final factory in tagMap.values) {
        if (!visited.add(factory)) continue;
        final instance = factory.dependency;
        factory.dependency = null;
        factory.isInit = false;
        factory.generation = null;
        if (instance is SintLifeCycleMixin) {
          instance.onDelete();
        }
      }
    }
    _factories.clear();
  }
}

extension InjectionExtension on SintInterface {
  T call<T>() => find<T>();

  /// Active factories indexed by opaque handles for legacy string-key callers.
  /// Populated lazily only when [registeredKeys] or [_factoryForKey] is used.
  static final Map<String, _InstanceBuilderFactory> _singl = {};
  static final Map<String, Set<_InstanceBuilderFactory>> _legacySingl = {};
  static int _nextHandle = 0;
  static bool _hasUnindexedFactories = false;

  /// Type-keyed injection registry (O5a - SINT 1.6.0)
  /// Provides O(1) type-identity lookups, eliminating string concatenation
  /// overhead and dart2js minification collision risk.
  static final Map<Type, Map<String?, _InstanceBuilderFactory>> _typeSingl = {};

  /// Active `SintScope` containers (mounted widget scopes + imperative `SintScope.run` + build scopes).
  static final List<SintScopeContainer> _mountedScopes = [];
  static final List<(SintScopeContainer, int)> _imperativeScopes = [];
  static final List<(SintScopeContainer, int)> _buildScopes = [];
  static final List<String> _resolutionStack = [];
  static int _scopeEpoch = 0;
  static int _widgetBuildScopeDepth = 0;
  static bool _hasActiveScopes = false;

  /// Fast `O(1)` check indicating whether at least one `SintScope` is active.
  static bool get hasActiveScopes => _hasActiveScopes;

  static void _refreshScopeFlag() {
    _hasActiveScopes = _mountedScopes.isNotEmpty ||
        _imperativeScopes.isNotEmpty ||
        _buildScopes.isNotEmpty;
  }

  /// Internal hook used by `SintScope` when mounting in a widget tree.
  static void pushMountedScope(SintScopeContainer scope) {
    _mountedScopes.add(scope);
    _hasActiveScopes = true;
  }

  /// Internal hook used by `SintScope` when unmounting.
  static void popMountedScope(SintScopeContainer scope) {
    _mountedScopes.remove(scope);
    _imperativeScopes.removeWhere((entry) => identical(entry.$1, scope));
    _buildScopes.removeWhere((entry) => identical(entry.$1, scope));
    _refreshScopeFlag();
    scope.dispose();
  }

  /// Internal hook used by `SintScope` around subtree `build` so sibling scopes
  /// resolve their own subtree overrides first.
  static R runWithBuildScope<R>(
    SintScopeContainer scope,
    R Function() action,
  ) {
    _buildScopes.add((scope, ++_scopeEpoch));
    _hasActiveScopes = true;
    try {
      return action();
    } finally {
      _buildScopes.removeLast();
      _refreshScopeFlag();
    }
  }

  /// Pushes the exact ordered chain of ancestor widget [scopes] (outermost to
  /// innermost, or empty when a widget has no ancestor `SintScope`) around
  /// [action] so side-by-side sibling `SintScope`s and unscoped siblings isolate
  /// cleanly without `BuildContext` boilerplate.
  static R runWithWidgetBuildScopes<R>(
    List<SintScopeContainer> scopes,
    R Function() action,
  ) {
    final prevLen = _buildScopes.length;
    if (scopes.isNotEmpty) {
      for (final scope in scopes) {
        _buildScopes.add((scope, ++_scopeEpoch));
      }
    }
    _widgetBuildScopeDepth++;
    _refreshScopeFlag();
    try {
      return action();
    } finally {
      _widgetBuildScopeDepth--;
      _buildScopes.length = prevLen;
      _refreshScopeFlag();
    }
  }

  /// Resolves `S` directly from a specific [scope], returning `null` if [scope]
  /// does not contain an override for `S` (and [tag]).
  static S? findInScope<S>(SintScopeContainer scope, {String? tag}) {
    final dep = scope._factories[S]?[tag];
    if (dep == null) return null;
    return _resolveScopedFactory<S>(dep);
  }

  /// Resolves `S` from the global `_typeSingl` container, bypassing active scopes.
  static S findGlobal<S>({String? tag}) {
    final dep = _typeSingl[S]?[tag];
    if (dep == null) {
      // ignore: lines_longer_than_80_chars
      throw StateError('"$S" not found. You need to call "Sint.put($S())" or "Sint.lazyPut(()=>$S())"');
    }
    final i = Sint._initDependencies<S>(name: tag, dep: dep);
    return (i ?? dep.getDependency()) as S;
  }

  /// Runs [body] with temporary scoped [overrides] and disposes them when done.
  static FutureOr<R> runScoped<R>({
    required List<SintOverride<dynamic>> overrides,
    required FutureOr<R> Function() body,
  }) {
    final container = SintScopeContainer(overrides);
    _imperativeScopes.add((container, ++_scopeEpoch));
    _hasActiveScopes = true;
    try {
      final result = body();
      if (result is Future<R>) {
        return result.whenComplete(() => popMountedScope(container));
      }
      popMountedScope(container);
      return result;
    } catch (_) {
      popMountedScope(container);
      rethrow;
    }
  }

  static _InstanceBuilderFactory? _lookupScopedFactory(Type type, String? tag) {
    _InstanceBuilderFactory? buildMatch;
    var buildEpoch = -1;
    for (var i = _buildScopes.length - 1; i >= 0; i--) {
      final entry = _buildScopes[i];
      final match = entry.$1._factories[type]?[tag];
      if (match != null) {
        buildMatch = match;
        buildEpoch = entry.$2;
        break;
      }
    }

    _InstanceBuilderFactory? impMatch;
    var impEpoch = -1;
    for (var i = _imperativeScopes.length - 1; i >= 0; i--) {
      final entry = _imperativeScopes[i];
      final match = entry.$1._factories[type]?[tag];
      if (match != null) {
        impMatch = match;
        impEpoch = entry.$2;
        break;
      }
    }

    if (buildMatch != null || impMatch != null) {
      return impEpoch > buildEpoch ? impMatch : buildMatch;
    }

    if (_widgetBuildScopeDepth == 0) {
      for (var i = _mountedScopes.length - 1; i >= 0; i--) {
        final match = _mountedScopes[i]._factories[type]?[tag];
        if (match != null) return match;
      }
    }
    return null;
  }

  static S _resolveScopedFactory<S>(_InstanceBuilderFactory dep) {
    if (dep._isBuilding) {
      throw StateError(
        'Circular dependency detected while resolving "${dep.legacyKey}": '
        '${_resolutionStack.join(' -> ')} -> ${dep.legacyKey}',
      );
    }
    if (!dep.isInit) {
      dep.isInit = true;
      final generation = dep.generation ??= Object();
      dep._isBuilding = true;
      _resolutionStack.add(dep.legacyKey);
      try {
        final instance = dep.getDependency() as S;
        if (instance is SintLifeCycleMixin) {
          instance.onStart();
        }
        return instance;
      } catch (_) {
        if (identical(dep.generation, generation)) {
          dep.isInit = false;
        }
        rethrow;
      } finally {
        dep._isBuilding = false;
        _resolutionStack.removeLast();
      }
    }
    return dep.getDependency() as S;
  }

  static void _ensureLegacyIndex() {
    if (!_hasUnindexedFactories) return;
    for (final tagMap in _typeSingl.values) {
      for (final factory in tagMap.values) {
        if (!factory._legacyIndexed) {
          factory._legacyIndexed = true;
          _singl[factory.handle] = factory;
          _legacySingl.putIfAbsent(factory.legacyKey, () => {}).add(factory);
        }
      }
    }
    _hasUnindexedFactories = false;
  }

  /// Exposes the registered dependency keys for internal use (e.g. selective cleanup).
  static Iterable<String> get registeredKeys {
    _ensureLegacyIndex();
    return _singl.values.map((factory) =>
        _legacySingl[factory.legacyKey]!.length == 1
            ? factory.legacyKey
            : factory.handle);
  }

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
    _ensureLegacyIndex();
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
    final extras = factory._extraBindings;
    if (extras != null) {
      for (final (aliasType, aliasTag) in extras) {
        final aliasTags = _typeSingl[aliasType];
        if (identical(aliasTags?[aliasTag], factory)) {
          aliasTags!.remove(aliasTag);
          if (aliasTags.isEmpty) _typeSingl.remove(aliasType);
        }
      }
      extras.clear();
    }
    if (factory._legacyIndexed) {
      factory._legacyIndexed = false;
      _singl.remove(factory._handle);
      final key = factory._legacyKey;
      if (key != null) {
        final legacy = _legacySingl[key];
        legacy?.remove(factory);
        if (legacy?.isEmpty ?? false) _legacySingl.remove(key);
      }
    }
  }

  static void _bindExtraSlot(
    _InstanceBuilderFactory factory,
    Type type,
    String? slotTag, {
    bool overwrite = false,
  }) {
    if (type == factory.registeredType && slotTag == factory.tag) return;
    var tagMap = _typeSingl[type];
    if (tagMap != null) {
      final existing = tagMap[slotTag];
      if (existing != null) {
        if (identical(existing, factory)) return;
        if (!overwrite && !existing.isDirty) return;
      }
    }
    (tagMap ?? (_typeSingl[type] = <String?, _InstanceBuilderFactory>{}))[
        slotTag] = factory;
    factory._addExtraBinding(type, slotTag);
  }

  /// Registers [dependency] as a singleton in SINT's container.
  ///
  /// Subclasses of [SintService] default to `permanent: true` unless
  /// [permanent] is explicitly provided. Optional [aliases] bind additional
  /// interface or controller [Type] keys to the exact same factory and
  /// lifecycle generation without creating bridge closures.
  S put<S>(
    S dependency, {
    String? tag,
    bool? permanent,
    List<Type>? aliases,
  }) {
    _insert(
      isSingleton: true,
      name: tag,
      permanent: permanent ?? (dependency is SintService),
      builder: (() => dependency),
      aliases: aliases,
    );
    return find<S>(tag: tag);
  }

  /// Eager contract-first registration: registers [dependency] primarily under
  /// the service/interface contract [S], while also aliasing concrete [I] for
  /// intra-module consumers.
  ///
  /// When [tag] is provided, the first registered contract for [S] (or one with
  /// `isDefault: true`) also serves untagged `Sint.find<S>()` by default.
  I putContract<S, I extends S>(
    I dependency, {
    String? tag,
    bool? permanent,
    bool? isDefault,
    List<Type>? aliases,
  }) {
    final bindAsDefault =
        tag != null && (isDefault ?? (_typeSingl[S]?[null] == null));
    final factory = _insert<S>(
      isSingleton: true,
      name: tag,
      permanent: permanent ?? (dependency is SintService),
      builder: () => dependency,
      aliases: <Type>[
        if (I != S) I,
        ...?aliases,
      ],
      bindUntaggedDefault: bindAsDefault,
      overwriteDefault: isDefault == true,
    );
    if (factory != null && I != S && tag != null && _typeSingl[I]?[null] == null) {
      _bindExtraSlot(factory, I, null);
    }
    return find<S>(tag: tag) as I;
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
    bool? permanent,
    List<Type>? aliases,
  }) {
    _insert(
      isSingleton: true,
      name: tag,
      permanent:
          permanent ?? (builder is InstanceBuilderCallback<SintService>),
      builder: builder,
      fenix: fenix,
      isLazyFactory: true,
      aliases: aliases,
    );
  }

  /// Lazy contract-first registration (`lazyPut` with [S] service contract
  /// first and concrete controller/implementation [I] second).
  ///
  /// - External modules (which only import core service contracts) resolve via:
  ///   - `Sint.find<S>()` for the default implementation (when there is only
  ///     one, the first registered, or whichever passed `isDefault: true`),
  ///   - `Sint.find<S>(tag: 'id')` by identifier, or
  ///   - `Sint.findAt<S>(index)` / `Sint.findAll<S>()` by registration order.
  /// - Intra-module UI inside the owning package can also resolve `Sint.find<I>()`
  ///   from the exact same shared singleton factory.
  void contract<S, I extends S>(
    InstanceBuilderCallback<I> builder, {
    String? tag,
    bool fenix = false,
    bool? permanent,
    bool? isDefault,
    List<Type>? aliases,
  }) {
    final bindAsDefault =
        tag != null && (isDefault ?? (_typeSingl[S]?[null] == null));
    final factory = _insert<S>(
      isSingleton: true,
      name: tag,
      permanent:
          permanent ?? (builder is InstanceBuilderCallback<SintService>),
      builder: builder,
      fenix: fenix,
      isLazyFactory: true,
      aliases: <Type>[
        if (I != S) I,
        ...?aliases,
      ],
      bindUntaggedDefault: bindAsDefault,
      overwriteDefault: isDefault == true,
    );
    if (factory != null && I != S && tag != null && _typeSingl[I]?[null] == null) {
      _bindExtraSlot(factory, I, null);
    }
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
    bool? permanent,
    List<Type>? aliases,
  }) async {
    final instance = await asyncBuilder();
    return put<S>(instance, tag: tag, permanent: permanent, aliases: aliases);
  }

  /// Asynchronous contract-first registration: awaits [asyncBuilder] and binds
  /// the resulting [I] primarily under service contract [S] while also aliasing
  /// concrete [I] for intra-module consumers.
  Future<I> putContractAsync<S, I extends S>(
    Future<I> Function() asyncBuilder, {
    String? tag,
    bool? permanent,
    bool? isDefault,
    List<Type>? aliases,
  }) async {
    final instance = await asyncBuilder();
    return putContract<S, I>(
      instance,
      tag: tag,
      permanent: permanent,
      isDefault: isDefault,
      aliases: aliases,
    );
  }

  /// Injects the Instance [S] builder into the `_typeSingl` HashMap.
  _InstanceBuilderFactory<S>? _insert<S>({
    required InstanceBuilderCallback<S> builder,
    bool? isSingleton,
    String? name,
    bool fenix = false,
    bool permanent = false,
    bool isLazyFactory = false,
    List<Type>? aliases,
    bool bindUntaggedDefault = false,
    bool overwriteDefault = false,
  }) {
    if (S == dynamic) {
      throw ArgumentError(
        'Cannot register a dependency under type "dynamic". '
        'Specify an explicit type argument (e.g. Sint.put<MyController>(...) '
        'or Bind.lazyPut<MyService>(...)) or pass a statically typed value.',
      );
    }
    var tagMap = _typeSingl[S];
    if (tagMap != null) {
      final existing = tagMap[name];
      if (existing != null) {
        if (!existing.isDirty) {
          return null;
        }
        // Its route still owns the old generation until route disposal.
        _unregister(existing);
        tagMap = _typeSingl[S];
      }
    }
    final factory = _InstanceBuilderFactory<S>(
      isSingleton: isSingleton,
      builderFunc: builder,
      permanent: permanent,
      isInit: false,
      fenix: fenix,
      isLazyFactory: isLazyFactory,
      tag: name,
    );
    (tagMap ?? (_typeSingl[S] = <String?, _InstanceBuilderFactory>{}))[name] =
        factory;
    if (bindUntaggedDefault && name != null) {
      _bindExtraSlot(factory, S, null, overwrite: overwriteDefault);
    }
    if (aliases != null) {
      for (final alias in aliases) {
        _bindExtraSlot(factory, alias, name);
        if (bindUntaggedDefault && name != null) {
          _bindExtraSlot(factory, alias, null, overwrite: overwriteDefault);
        }
      }
    }
    _hasUnindexedFactories = true;
    return factory;
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
    if (dep._isBuilding) {
      throw StateError(
        'Circular dependency detected while resolving "${dep.legacyKey}": '
        '${_resolutionStack.join(' -> ')} -> ${dep.legacyKey}',
      );
    }
    if (dep.isInit) {
      return null;
    }
    final isSingleton = dep.isSingleton ?? false;
    final generation = isSingleton ? (dep.generation ??= Object()) : Object();
    if (isSingleton) {
      dep.isInit = true;
    }
    dep._isBuilding = true;
    _resolutionStack.add(dep.legacyKey);
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
      }
      rethrow;
    } finally {
      dep._isBuilding = false;
      _resolutionStack.removeLast();
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
      if (_hasActiveScopes) {
        dep = _lookupScopedFactory(S, tag);
      }
      dep ??= _typeSingl[S]?[tag];
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
    if (_hasActiveScopes) {
      final scoped = _lookupScopedFactory(S, tag);
      if (scoped != null) return _resolveScopedFactory<S>(scoped);
    }
    final factory = _typeSingl[S]?[tag];
    if (factory != null) {
      return find<S>(tag: tag);
    } else {
      return put(dep(), tag: tag);
    }
  }

  /// Finds the registered type <[S]> (or [tag])
  /// In case of using `Sint.spawn` to register a type <[S]> or [tag],
  /// it will create an instance each time you call [find].
  /// If the registered type <[S]> (or [tag]) is a Controller,
  /// it will initialize it's lifecycle.
  S find<S>({String? tag}) {
    if (_hasActiveScopes) {
      final scoped = _lookupScopedFactory(S, tag);
      if (scoped != null) {
        return _resolveScopedFactory<S>(scoped);
      }
    }
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

  /// Returns the registered instance if available, or `null` in a single `O(1)` lookup.
  S? findOrNull<S>({String? tag}) {
    if (_hasActiveScopes) {
      final scoped = _lookupScopedFactory(S, tag);
      if (scoped != null) {
        return _resolveScopedFactory<S>(scoped);
      }
    }
    final dep = _typeSingl[S]?[tag];
    if (dep == null) return null;
    final i = _initDependencies<S>(name: tag, dep: dep);
    return (i ?? dep.getDependency()) as S;
  }

  static List<(_InstanceBuilderFactory, bool)> _orderedFactoriesForType(
    Type type,
  ) {
    Map<String?, (_InstanceBuilderFactory, bool)>? mergedByTag;
    if (_hasActiveScopes) {
      mergedByTag = <String?, (_InstanceBuilderFactory, bool)>{};
      final globalMap = _typeSingl[type];
      if (globalMap != null) {
        for (final entry in globalMap.entries) {
          if (entry.key == null && entry.value.tag != null) continue;
          mergedByTag[entry.key] = (entry.value, false);
        }
        final globalDefault = globalMap[null];
        if (globalDefault != null && !mergedByTag.containsKey(globalDefault.tag)) {
          mergedByTag[null] = (globalDefault, false);
        }
      }
      if (_widgetBuildScopeDepth == 0) {
        for (var i = 0; i < _mountedScopes.length; i++) {
          final scopedMap = _mountedScopes[i]._factories[type];
          if (scopedMap == null) continue;
          for (final entry in scopedMap.entries) {
            if (entry.key == null && entry.value.tag != null) continue;
            mergedByTag[entry.key] = (entry.value, true);
          }
        }
      }
      if (_imperativeScopes.isNotEmpty && _buildScopes.isNotEmpty) {
        final combined = <(SintScopeContainer, int)>[
          ..._imperativeScopes,
          ..._buildScopes,
        ]..sort((a, b) => a.$2.compareTo(b.$2));
        for (final entry in combined) {
          final scopedMap = entry.$1._factories[type];
          if (scopedMap == null) continue;
          for (final item in scopedMap.entries) {
            if (item.key == null && item.value.tag != null) continue;
            mergedByTag[item.key] = (item.value, true);
          }
        }
      } else {
        for (var i = 0; i < _imperativeScopes.length; i++) {
          final scopedMap = _imperativeScopes[i].$1._factories[type];
          if (scopedMap == null) continue;
          for (final entry in scopedMap.entries) {
            if (entry.key == null && entry.value.tag != null) continue;
            mergedByTag[entry.key] = (entry.value, true);
          }
        }
        for (var i = 0; i < _buildScopes.length; i++) {
          final scopedMap = _buildScopes[i].$1._factories[type];
          if (scopedMap == null) continue;
          for (final entry in scopedMap.entries) {
            if (entry.key == null && entry.value.tag != null) continue;
            mergedByTag[entry.key] = (entry.value, true);
          }
        }
      }
      if (mergedByTag.isEmpty) {
        return const <(_InstanceBuilderFactory, bool)>[];
      }
      final seen = Set<_InstanceBuilderFactory>.identity();
      final ordered = <(_InstanceBuilderFactory, bool)>[];
      for (final value in mergedByTag.values) {
        if (seen.add(value.$1)) {
          ordered.add(value);
        }
      }
      return ordered;
    }

    final tagMap = _typeSingl[type];
    if (tagMap == null || tagMap.isEmpty) {
      return const <(_InstanceBuilderFactory, bool)>[];
    }
    final seen = Set<_InstanceBuilderFactory>.identity();
    final ordered = <(_InstanceBuilderFactory, bool)>[];
    for (final entry in tagMap.entries) {
      // Skip synthetic untagged default pointers on the first pass so explicit
      // registration order is preserved even when a later entry sets isDefault.
      if (entry.key == null && entry.value.tag != null) continue;
      if (seen.add(entry.value)) {
        ordered.add((entry.value, false));
      }
    }
    final defaultEntry = tagMap[null];
    if (defaultEntry != null && seen.add(defaultEntry)) {
      ordered.add((defaultEntry, false));
    }
    return ordered;
  }

  /// Resolves all unique implementations registered under [S] in exact
  /// registration order (honoring active `SintScope` overrides), allowing
  /// modules that only import a core service interface to iterate or select
  /// implementations without importing concrete controllers.
  List<S> findAll<S>() {
    final factories = _orderedFactoriesForType(S);
    if (factories.isEmpty) return <S>[];
    return <S>[
      for (final (dep, isScoped) in factories)
        isScoped
            ? _resolveScopedFactory<S>(dep)
            : (_initDependencies<S>(name: dep.tag, dep: dep) ??
                dep.getDependency()) as S,
    ];
  }

  /// Resolves the implementation of [S] at registration [index] (`0`-based),
  /// enabling order-based selection using only the service contract [S].
  S findAt<S>(int index) {
    final factories = _orderedFactoriesForType(S);
    if (index < 0 || index >= factories.length) {
      throw RangeError.range(
        index,
        0,
        factories.length - 1,
        'index',
        'Out of range for registered "$S" implementations (${factories.length} found)',
      );
    }
    final (dep, isScoped) = factories[index];
    if (isScoped) {
      return _resolveScopedFactory<S>(dep);
    }
    final i = _initDependencies<S>(name: dep.tag, dep: dep);
    return (i ?? dep.getDependency()) as S;
  }

  /// Replace a parent instance of a class in dependency management
  /// with a [child] instance
  /// - [tag] optional, if you use a [tag] to register the Instance.
  void replace<P>(P child, {String? tag}) {
    final factory = _typeSingl[P]?[tag];
    final permanent = factory?.permanent ?? (child is SintService);
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
    final factory = _typeSingl[P]?[tag];
    final permanent = factory?.permanent ?? false;
    if (factory != null) {
      _deleteFactory(factory, force: permanent, keepFactory: false);
    }
    lazyPut<P>(builder, tag: tag, fenix: fenix ?? permanent);
  }

  /// Generates the key based on [type] (and optionally a [name])
  /// to register an Instance Builder in the hashmap.
  static String _getKey(Type type, String? name) {
    return name == null ? type.toString() : '${type.toString()}$name';
  }

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
    final retainFactory = keepFactory &&
        (factory.fenix ||
            (factory.isLazyFactory &&
                Sint.smartManagement == SmartManagement.keepFactory));
    if (!retainFactory || !active) _unregister(factory);
    if (i is SintLifeCycleMixin) {
      i.onDelete();
      if (Sint.isLogEnable) {
        Sint.log('"${factory.legacyKey}" onDelete() called');
      }
    }
    return true;
  }

  static List<_InstanceBuilderFactory> _allFactories() {
    final seen = Set<_InstanceBuilderFactory>.identity();
    for (final tagMap in _typeSingl.values) {
      seen.addAll(tagMap.values);
    }
    return seen.toList(growable: false);
  }

  /// Delete all registered Class Instances and, closes any open
  /// controllers `DisposableInterface`, cleans up the memory
  ///
  /// - [force] Will delete the Instances even if marked as `permanent`.
  void deleteAll({bool force = false}) {
    final factories = _allFactories();
    for (final factory in factories) {
      _deleteFactory(factory, force: force);
    }
  }

  void reloadAll({bool force = false}) {
    final factories = _allFactories();
    for (final factory in factories) {
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
  bool isRegistered<S>({String? tag}) {
    if (_hasActiveScopes && _lookupScopedFactory(S, tag) != null) {
      return true;
    }
    return _typeSingl[S]?.containsKey(tag) ?? false;
  }

  /// Checks if a lazy factory callback `Sint.lazyPut()` that returns an
  /// Instance<[S]> is registered in memory.
  /// - [tag] is optional, if you used a [tag] to register the lazy Instance.
  bool isPrepared<S>({String? tag}) {
    final builder = (_hasActiveScopes ? _lookupScopedFactory(S, tag) : null) ??
        _typeSingl[S]?[tag];
    if (builder == null) {
      return false;
    }

    return !builder.isInit;
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
    for (final scope in List<SintScopeContainer>.of(_mountedScopes)) {
      scope.dispose();
    }
    for (final entry in List<(SintScopeContainer, int)>.of(_imperativeScopes)) {
      entry.$1.dispose();
    }
    _mountedScopes.clear();
    _imperativeScopes.clear();
    _buildScopes.clear();
    _resolutionStack.clear();
    _scopeEpoch = 0;
    _widgetBuildScopeDepth = 0;
    _hasActiveScopes = false;
    _typeSingl.clear();
    InjectionExtension._singl.clear();
    _legacySingl.clear();
    _hasUnindexedFactories = false;
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

  /// Whether this factory was registered lazily (`lazyPut` / `contract`) and
  /// can recreate fresh instances under [SmartManagement.keepFactory].
  final bool isLazyFactory;

  /// Stores the actual object instance when [isSingleton]=true.
  S? dependency;

  /// Generates (and regenerates) the instance when [isSingleton]=false.
  /// Usually used by factory methods
  InstanceBuilderCallback<S> builderFunc;

  /// Flag to persist the instance in memory,
  /// without considering `Sint.smartManagement`
  bool permanent = false;

  bool isInit = false;
  bool _isBuilding = false;

  /// Distinguishes successive initializations of a retained fenix factory.
  Object? generation = Object();

  String? _handle;
  String? _legacyKey;
  bool _legacyIndexed = false;
  List<(Type, String?)>? _extraBindings;

  void _addExtraBinding(Type type, String? slotTag) {
    (_extraBindings ??= <(Type, String?)>[]).add((type, slotTag));
  }

  String get handle => _handle ??= '@sint/${InjectionExtension._nextHandle++}';
  String get legacyKey =>
      _legacyKey ??= InjectionExtension._getKey(S, tag);

  bool isDirty = false;

  String? tag;

  _InstanceBuilderFactory({
    required this.isSingleton,
    required this.builderFunc,
    required this.permanent,
    required this.isInit,
    required this.fenix,
    required this.tag,
    this.isLazyFactory = false,
  });

  void _showInitLog() {
    if (Sint.isLogEnable) {
      if (tag == null) {
        Sint.log('Instance "$S" has been created');
      } else {
        Sint.log('Instance "$S" has been created with tag "$tag"');
      }
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
