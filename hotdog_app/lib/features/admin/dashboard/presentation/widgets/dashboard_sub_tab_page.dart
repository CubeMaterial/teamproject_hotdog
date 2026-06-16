import 'package:flutter/material.dart';

import 'package:hotdog_app/core/theme/app_colors.dart';

class DashboardSubTabPage extends StatefulWidget {
  const DashboardSubTabPage({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
  });

  final List<DashboardSubTab> tabs;
  final int initialIndex;

  @override
  State<DashboardSubTabPage> createState() => _DashboardSubTabPageState();
}

class _DashboardSubTabPageState extends State<DashboardSubTabPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant DashboardSubTabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.tabs.length) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Row(
              children: [
                for (final (index, tab) in widget.tabs.indexed) ...[
                  _DashboardSubTabButton(
                    label: tab.label,
                    selected: _selectedIndex == index,
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                  if (index != widget.tabs.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        Expanded(child: widget.tabs[_selectedIndex].child),
      ],
    );
  }
}

class DashboardSubTab {
  const DashboardSubTab({required this.label, required this.child});

  final String label;
  final Widget child;
}

class _DashboardSubTabButton extends StatelessWidget {
  const _DashboardSubTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.deepOrange : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          constraints: const BoxConstraints(minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.deepOrange : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
