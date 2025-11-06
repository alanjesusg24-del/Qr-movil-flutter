/// Helpers para parsear JSON de forma segura
class JsonHelpers {
  /// Parsea un valor a double de forma segura
  static double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Parsea un valor a int de forma segura
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Parsea un valor a DateTime de forma segura
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parseando DateTime: $value');
        return null;
      }
    }
    return null;
  }

  /// Parsea una lista de forma segura
  static List<T> parseList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value == null) return [];
    if (value is! List) return [];

    return value
        .where((item) => item != null)
        .map((item) {
          try {
            return fromJson(item as Map<String, dynamic>);
          } catch (e) {
            print('Error parseando item de lista: $e');
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }
}
