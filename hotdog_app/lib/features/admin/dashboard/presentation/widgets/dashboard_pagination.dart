import 'package:flutter/material.dart';

class DashboardPagination extends StatelessWidget {
  const DashboardPagination({
    super.key,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPrevious,
    this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1 ? onPrevious : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: '이전',
        ),
        Text('$currentPage / $totalPages'),
        IconButton(
          onPressed: currentPage < totalPages ? onNext : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: '다음',
        ),
      ],
    );
  }
}
