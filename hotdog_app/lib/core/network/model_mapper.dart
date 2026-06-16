import 'package:flutter/foundation.dart';

class ModelMapper {
  const ModelMapper._();

  static List<T> mapList<T>(
    List<dynamic> data,
    T Function(Map<String, dynamic> json) fromJson, {
    required String label,
  }) {
    final items = <T>[];

    for (final (index, item) in data.indexed) {
      try {
        if (item is Map) {
          items.add(fromJson(item.cast<String, dynamic>()));
        } else {
          debugPrint('$label[$index] skipped: response item is not an object');
        }
      } catch (error, stackTrace) {
        debugPrint('$label[$index] skipped: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return items;
  }
}
