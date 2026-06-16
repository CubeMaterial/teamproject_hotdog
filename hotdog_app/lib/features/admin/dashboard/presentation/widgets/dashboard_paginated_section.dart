import 'package:flutter/material.dart';

import 'dashboard_pagination.dart';

class DashboardPaginatedSection<T> extends StatefulWidget {
  const DashboardPaginatedSection({
    super.key,
    required this.items,
    required this.tableBuilder,
    this.headerBuilder,
    this.indexedTableBuilder,
  });

  final List<T> items;
  final Widget Function(List<T> visibleItems) tableBuilder;
  final Widget Function(Widget pageSizeSelector)? headerBuilder;
  final Widget Function(List<T> visibleItems, int startIndex)?
  indexedTableBuilder;

  @override
  State<DashboardPaginatedSection<T>> createState() =>
      _DashboardPaginatedSectionState<T>();
}

class _DashboardPaginatedSectionState<T>
    extends State<DashboardPaginatedSection<T>> {
  static const _pageSizeOptions = [10, 20, 30];

  int _currentPage = 1;
  int _pageSize = 10;

  @override
  void didUpdateWidget(covariant DashboardPaginatedSection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _clampCurrentPage();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _totalPages;
    final visibleItems = _visibleItems;
    final pageSizeSelector = _PageSizeSelector(
      value: _pageSize,
      options: _pageSizeOptions,
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _pageSize = value;
          _currentPage = 1;
        });
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.headerBuilder?.call(pageSizeSelector) ??
            Align(alignment: Alignment.centerRight, child: pageSizeSelector),
        const SizedBox(height: 12),
        widget.indexedTableBuilder?.call(visibleItems, _visibleStartIndex) ??
            widget.tableBuilder(visibleItems),
        DashboardPagination(
          currentPage: _currentPage,
          totalPages: totalPages,
          onPrevious: () => setState(() => _currentPage--),
          onNext: () => setState(() => _currentPage++),
        ),
      ],
    );
  }

  int get _totalPages {
    if (widget.items.isEmpty) {
      return 1;
    }

    return (widget.items.length / _pageSize).ceil();
  }

  List<T> get _visibleItems {
    if (widget.items.isEmpty) {
      return const [];
    }

    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, widget.items.length);

    return widget.items.sublist(startIndex, endIndex);
  }

  int get _visibleStartIndex {
    if (widget.items.isEmpty) {
      return 0;
    }

    return (_currentPage - 1) * _pageSize;
  }

  void _clampCurrentPage() {
    final totalPages = _totalPages;

    if (_currentPage > totalPages) {
      setState(() => _currentPage = totalPages);
    }
  }
}

class _PageSizeSelector extends StatelessWidget {
  const _PageSizeSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '표시 개수',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: value,
            isDense: true,
            isExpanded: true,

            // 여기서 클릭했을 때 뜨는 메뉴 자체 너비 조절
            menuWidth: 128,

            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(8),
            menuMaxHeight: 240,

            items: [
              for (final option in options)
                DropdownMenuItem<int>(value: option, child: Text('$option개')),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
