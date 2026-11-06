class SintTestMode {
  static bool active = false;
  static Object? _arguments;

  static void setTestArguments(Object? arguments) {
    _arguments = arguments;
  }

  static Object? get arguments => _arguments;

  static Map<String, String?> _parameters = {};
  static Map<String, String?> _queryParameters = {};

  static void setTestParameters(Map<String, String?> parameters) {
    _parameters = parameters;
  }

  static Map<String, String?> get parameters => _parameters;

  /// Configures query parameters for headless controller unit tests when
  /// [active] is `true`.
  static void setTestQueryParameters(Map<String, String?> queryParameters) {
    _queryParameters = queryParameters;
  }

  /// Non-null query parameters configured in test mode.
  static Map<String, String> get queryParameters => {
        for (final entry in _queryParameters.entries)
          if (entry.value != null) entry.key: entry.value!,
      };

  /// Test mode support for routeParam — returns first parameter value.
  static String? get routeParam =>
      _parameters.values.where((v) => v != null && v.isNotEmpty).firstOrNull;

  /// Test mode support for named path parameter.
  static String? pathParam(String name) => _parameters[name];

  /// Test mode support for query parameter (checks explicit query parameters
  /// first, then falls back to [parameters] for convenience).
  static String? queryParam(String name) =>
      _queryParameters[name] ?? _parameters[name];

  /// Test mode support for query parameter with default.
  static String queryParamOrDefault(String name, String defaultValue) =>
      queryParam(name) ?? defaultValue;

  /// Clears all mocked navigation arguments, parameters, and active flag.
  static void reset() {
    active = false;
    _arguments = null;
    _parameters = {};
    _queryParameters = {};
  }
}
