class SintTestMode {
  static bool active = false;
  static Object? _arguments;

  static void setTestArguments(Object? arguments) {
    _arguments = arguments;
  }

  static Object? get arguments => _arguments;

  static Map<String, String?> _parameters = {};

  static void setTestParameters(Map<String, String?> parameters) {
    _parameters = parameters;
  }

  static Map<String, String?> get parameters => _parameters;

  /// Test mode support for routeParam — returns first parameter value.
  static String? get routeParam =>
      _parameters.values.where((v) => v != null && v.isNotEmpty).firstOrNull;

  /// Test mode support for named path parameter.
  static String? pathParam(String name) => _parameters[name];

  /// Test mode support for query parameter.
  static String? queryParam(String name) => null;

  /// Test mode support for query parameter with default.
  static String queryParamOrDefault(String name, String defaultValue) =>
      defaultValue;
}
