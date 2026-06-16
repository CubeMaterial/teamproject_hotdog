import 'package:flutter/foundation.dart';

import '../../domain/entities/inventory.dart';
import '../../domain/usecases/create_inventory_item_usecase.dart';
import '../../domain/usecases/get_inventory_categories_usecase.dart';
import '../../domain/usecases/get_inventory_items_usecase.dart';
import '../../domain/usecases/get_inventory_makers_usecase.dart';
import '../../domain/usecases/get_stock_histories_usecase.dart';

class InventoryViewModel extends ChangeNotifier {
  InventoryViewModel(
    this._getInventoryItemsUseCase,
    this._getInventoryCategoriesUseCase,
    this._getInventoryMakersUseCase,
    this._getStockHistoriesUseCase,
    this._createInventoryItemUseCase,
  );

  final GetInventoryItemsUseCase _getInventoryItemsUseCase;
  final GetInventoryCategoriesUseCase _getInventoryCategoriesUseCase;
  final GetInventoryMakersUseCase _getInventoryMakersUseCase;
  final GetStockHistoriesUseCase _getStockHistoriesUseCase;
  final CreateInventoryItemUseCase _createInventoryItemUseCase;

  List<InventoryItem> items = [];
  List<StockHistory> histories = [];
  List<String> makers = [];
  List<String> _categories = [];
  String searchQuery = '';
  String selectedCategory = '전체';
  bool isLoading = false;
  bool hasLoaded = false;
  final Set<String> selectedItemIds = {};

  List<String> get categories {
    final values = {
      ..._categories,
      ...items.map((item) => item.category),
    }.toList()..sort();

    return ['전체', ...values];
  }

  List<InventoryItem> get filteredItems {
    final query = searchQuery.trim().toLowerCase();

    return items.where((item) {
      final matchesQuery =
          query.isEmpty || item.name.toLowerCase().contains(query);
      final matchesCategory =
          selectedCategory == '전체' || item.category == selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();
  }

  List<CategoryInventoryForecast> get categoryForecasts {
    final groupedItems = <String, List<InventoryItem>>{};
    for (final item in items) {
      groupedItems.putIfAbsent(item.category, () => []).add(item);
    }

    final forecasts = [
      for (final entry in groupedItems.entries)
        CategoryInventoryForecast(
          category: entry.key,
          predictedStockAfter7d: _sumForecast(
            entry.value,
            (item) => item.predictedStockAfter7d,
          ),
          predictedStockAfter30d: _sumForecast(
            entry.value,
            (item) => item.predictedStockAfter30d,
          ),
        ),
    ]..sort((a, b) => a.category.compareTo(b.category));

    return forecasts;
  }

  Future<void> ensureLoaded() async {
    if (hasLoaded || isLoading) {
      return;
    }

    await load();
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _getInventoryItemsUseCase(),
        _getInventoryCategoriesUseCase(),
        _getInventoryMakersUseCase(),
        _getStockHistoriesUseCase(),
      ]);

      items = results[0] as List<InventoryItem>;
      _categories = results[1] as List<String>;
      makers = results[2] as List<String>;
      histories = results[3] as List<StockHistory>;
      selectedItemIds.removeWhere((id) => !items.any((item) => item.id == id));
      if (!categories.contains(selectedCategory)) {
        selectedCategory = '전체';
      }
      hasLoaded = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setSelectedCategory(String value) {
    selectedCategory = categories.contains(value) ? value : '전체';
    notifyListeners();
  }

  void setItemSelected(String itemId, bool selected) {
    if (selected) {
      selectedItemIds.add(itemId);
    } else {
      selectedItemIds.remove(itemId);
    }

    notifyListeners();
  }

  void setItemsSelected(Iterable<String> itemIds, bool selected) {
    if (selected) {
      selectedItemIds.addAll(itemIds);
    } else {
      selectedItemIds.removeAll(itemIds);
    }

    notifyListeners();
  }

  Future<void> createItem({
    required String name,
    required String category,
    required String maker,
    required int price,
    required int stock,
  }) async {
    await _createInventoryItemUseCase(
      name: name,
      category: category,
      maker: maker,
      price: price,
      stock: stock,
    );

    hasLoaded = false;
    await load();
  }

  double? _sumForecast(
    List<InventoryItem> items,
    double? Function(InventoryItem item) valueOf,
  ) {
    var hasValue = false;
    var total = 0.0;

    for (final item in items) {
      final value = valueOf(item);
      if (value == null) {
        continue;
      }

      hasValue = true;
      total += value;
    }

    return hasValue ? total : null;
  }
}

class CategoryInventoryForecast {
  const CategoryInventoryForecast({
    required this.category,
    required this.predictedStockAfter7d,
    required this.predictedStockAfter30d,
  });

  final String category;
  final double? predictedStockAfter7d;
  final double? predictedStockAfter30d;
}
