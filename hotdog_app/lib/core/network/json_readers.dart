class JsonReaders {
  const JsonReaders._();

  static String stringValue(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];

      if (value != null) {
        return '$value';
      }
    }

    return fallback;
  }

  static int intValue(
    Map<String, dynamic> json,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = json[key];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      final parsed = int.tryParse('${value ?? ''}');
      if (parsed != null) {
        return parsed;
      }
    }

    return fallback;
  }

  static bool boolValue(
    Map<String, dynamic> json,
    List<String> keys, {
    bool fallback = true,
  }) {
    for (final key in keys) {
      final value = json[key];

      if (value is bool) {
        return value;
      }

      if (value is num) {
        return value != 0;
      }

      final text = '${value ?? ''}'.toLowerCase();
      if (text == 'true' || text == 'y' || text == '1') {
        return true;
      }
      if (text == 'false' || text == 'n' || text == '0') {
        return false;
      }
    }

    return fallback;
  }

  static DateTime dateTimeValue(
    Map<String, dynamic> json,
    List<String> keys, {
    DateTime? fallback,
  }) {
    for (final key in keys) {
      final value = json[key];

      if (value is DateTime) {
        return value;
      }

      final parsed = DateTime.tryParse('${value ?? ''}');
      if (parsed != null) {
        return parsed;
      }
    }

    return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
