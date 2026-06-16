import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    required this.onHomePressed,
    required this.staffName,
    required this.staffRole,
  });

  final VoidCallback onHomePressed;
  final String staffName;
  final String staffRole;

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        height: preferredSize.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.help_outline),
                color: AppColors.neutral,
                tooltip: '도움말',
              ),
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: AppColors.border,
              ),
              _StaffProfileSummary(name: staffName, role: staffRole),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffProfileSummary extends StatelessWidget {
  const _StaffProfileSummary({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              role,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.beige,
          child: Icon(Icons.person, size: 24, color: AppColors.deepOrange),
        ),
      ],
    );
  }
}
