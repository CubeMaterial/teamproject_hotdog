import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

class DashboardSideMenu extends StatelessWidget {
  const DashboardSideMenu({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.bottomItemCount = 0,
  });

  final List<String> items;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final int bottomItemCount;

  @override
  Widget build(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 980;
    final pinnedCount = bottomItemCount.clamp(0, items.length).toInt();
    final topItems = items.take(items.length - pinnedCount).toList();
    final bottomItems = items.skip(items.length - pinnedCount).toList();

    return SizedBox(
      width: extended ? 210 : 88,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.deepOrange),
        child: Column(
          children: [
            SizedBox(
              height: 112,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'images/hotdog_icon.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                    if (extended) ...[
                      const SizedBox(width: 10),
                      const Text(
                        'HOTDOG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  for (final (index, item) in topItems.indexed)
                    _DashboardMenuItem(
                      item: item,
                      extended: extended,
                      selected: selectedIndex == index,
                      onTap: () => onSelected(index),
                    ),
                ],
              ),
            ),
            if (bottomItems.isNotEmpty) ...[
              Divider(color: Colors.white.withValues(alpha: 0.18), height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                child: Column(
                  children: [
                    for (final (index, item) in bottomItems.indexed)
                      _DashboardMenuItem(
                        item: item,
                        extended: extended,
                        selected: selectedIndex == topItems.length + index,
                        onTap: () => onSelected(topItems.length + index),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardMenuItem extends StatelessWidget {
  const _DashboardMenuItem({
    required this.item,
    required this.extended,
    required this.selected,
    required this.onTap,
  });

  final String item;
  final bool extended;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.62);

    return Padding(
      padding: EdgeInsets.only(right: extended ? 0 : 8, top: 4, bottom: 4),
      child: Tooltip(
        message: item,
        child: Material(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: selected ? 42 : 0,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(width: extended ? 26 : 0),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: extended
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconForItem(item),
                          size: 24,
                          color: foregroundColor,
                        ),
                        if (extended) ...[
                          const SizedBox(width: 18),
                          Flexible(
                            child: Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: foregroundColor,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (extended) const SizedBox(width: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForItem(String item) {
    return switch (item) {
      '대시보드' => Icons.home_outlined,
      '주문관리' => Icons.attach_money,
      '재고관리' => Icons.inventory_2_outlined,
      '직원관리' => Icons.people_outline,
      '커뮤니티관리' => Icons.forum_outlined,
      '내 정보 수정' => Icons.manage_accounts_outlined,
      _ => Icons.circle,
    };
  }
}
