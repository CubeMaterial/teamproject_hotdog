import 'package:flutter/material.dart';

import '../../../../widgets/dashboard_search_field.dart';

class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    this.pageSizeSelector,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final Widget? pageSizeSelector;

  @override
  Widget build(BuildContext context) {
    final searchField = DashboardSearchField(
      hintText: '상품명 검색',
      onChanged: onSearchChanged,
    );
    final categoryFilter = SizedBox(
      width: 320,
      child: DropdownButtonFormField<String>(
        initialValue: categories.contains(selectedCategory)
            ? selectedCategory
            : '전체',
        isDense: true,
        decoration: const InputDecoration(
          labelText: '카테고리',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      
        ),
        items: [
          for (final category in categories)
            DropdownMenuItem(value: category, child: Text(category))
        ],
        onChanged: (value) {
          if (value != null) {
            onCategoryChanged(value);
          }
        },
        dropdownColor: Color(0xFFF7F8FA),
        
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasRoomForSingleLine = constraints.maxWidth >= 760;

        if (!hasRoomForSingleLine) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [searchField, categoryFilter, ?pageSizeSelector],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(fit: FlexFit.loose, child: searchField),
                  const SizedBox(width: 12),
                  categoryFilter,
                ],
              ),
            ),
            ?pageSizeSelector,
          ],
        );
      },
    );
  }
}
