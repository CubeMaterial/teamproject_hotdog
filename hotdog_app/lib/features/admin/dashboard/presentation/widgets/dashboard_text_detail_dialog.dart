import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

class DashboardTextDetailDialog extends StatelessWidget {
  const DashboardTextDetailDialog({
    super.key,
    required this.title,
    required this.items,
    this.actions = const [],
  });

  final String title;
  final List<DashboardTextDetailItem> items;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: const Color(0xFF333333),
                      iconSize: 30,
                      tooltip: '닫기',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Divider(height: 1, color: AppColors.border),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final item in items)
                          _DetailRow(label: item.label, value: item.value),
                      ],
                    ),
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardTextDetailItem {
  const DashboardTextDetailItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 150,
              color: AppColors.beige,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 54),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
