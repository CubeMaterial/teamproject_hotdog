import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/staff.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_side_menu.dart';
import '../widgets/dashboard_sub_tab_page.dart';
import 'tabs/comment/comment_manage_tab.dart';
import 'tabs/staff/staff_manage_tab.dart';
import 'tabs/inventory/item_manage_tab.dart';
import 'tabs/inventory/category_inventory_forecast_tab.dart';
import 'tabs/inventory/inventory_tab.dart';
import 'tabs/inventory/stock_history_tab.dart';
import 'tabs/member/member_manage_tab.dart';
import 'tabs/overview/dashboard_overview_tab.dart';
import 'tabs/profile/admin_profile_tab.dart';
import 'tabs/purchase_order/purchase_order_tab.dart';
import 'tabs/refund/refund_tab.dart';
import 'tabs/sales_order/sales_order_tab.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const _menuItems = ['대시보드', '주문관리', '재고관리', '직원관리', '커뮤니티관리', '내 정보'];

  int _selectedMenuIndex = 0;
  bool _didLoad = false;

  Future<void> _loadDashboard(WidgetRef ref) async {
    await Future.wait([
      _loadSection('dashboard', ref.read(dashboardViewModelProvider).load),
      _loadSection('refunds', ref.read(refundViewModelProvider).load),
      _loadSection('inventory', ref.read(inventoryViewModelProvider).load),
      _loadSection('sales-orders', ref.read(salesOrderViewModelProvider).load),
      _loadSection(
        'purchase-orders',
        ref.read(purchaseOrderViewModelProvider).load,
      ),
      _loadSection('staffs', ref.read(staffViewModelProvider).load),
      _loadSection('members', ref.read(memberViewModelProvider).load),
      _loadSection('comments', ref.read(commentViewModelProvider).load),
    ]);
  }

  Future<void> _loadSection(String name, Future<void> Function() load) async {
    try {
      await load();
    } catch (error, stackTrace) {
      debugPrint('Failed to load $name: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        if (!_didLoad) {
          _didLoad = true;
          Future.microtask(() => _loadDashboard(ref));
        }

        return _buildDashboard(context, ref);
      },
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref) {
    final dashboardViewModel = ref.watch(dashboardViewModelProvider);
    final refundViewModel = ref.watch(refundViewModelProvider);
    final inventoryViewModel = ref.watch(inventoryViewModelProvider);
    final salesOrderViewModel = ref.watch(salesOrderViewModelProvider);
    final purchaseOrderViewModel = ref.watch(purchaseOrderViewModelProvider);
    final staffViewModel = ref.watch(staffViewModelProvider);
    final memberViewModel = ref.watch(memberViewModelProvider);
    final commentViewModel = ref.watch(commentViewModelProvider);
    final authSession = ref.watch(authViewModelProvider).session;
    final currentStaff = _findCurrentStaff(
      staffViewModel.staffs,
      staffSeq: authSession?.staffSeq,
      staffEmail: authSession?.staffEmail,
    );
    final canRegisterStaff =
        currentStaff?.isSuper ?? authSession?.staffSeq == '1004';
    final canDeleteStaff =
        currentStaff?.staffSuperSeq.trim().isNotEmpty ?? false;
    final menuPages = [
      DashboardOverviewTab(viewModel: dashboardViewModel),
      DashboardSubTabPage(
        tabs: [
          DashboardSubTab(
            label: '수주',
            child: SalesOrderTab(viewModel: salesOrderViewModel),
          ),
          DashboardSubTab(
            label: '발주',
            child: PurchaseOrderTab(viewModel: purchaseOrderViewModel),
          ),
          DashboardSubTab(
            label: '환불',
            child: RefundTab(viewModel: refundViewModel),
          ),
        ],
      ),
      DashboardSubTabPage(
        tabs: [
          DashboardSubTab(
            label: '재고현황',
            child: InventoryTab(viewModel: inventoryViewModel),
          ),
          DashboardSubTab(
            label: '입출고내역',
            child: StockHistoryTab(viewModel: inventoryViewModel),
          ),
          DashboardSubTab(
            label: '품목관리',
            child: ItemManageTab(viewModel: inventoryViewModel),
          ),
          DashboardSubTab(
            label: '카테고리별 재고 예측',
            child: CategoryInventoryForecastTab(viewModel: inventoryViewModel),
          ),
        ],
      ),
      DashboardSubTabPage(
        tabs: [
          DashboardSubTab(
            label: '직원',
            child: StaffManageTab(
              viewModel: staffViewModel,
              canRegister: canRegisterStaff,
              canDelete: canDeleteStaff,
            ),
          ),
          DashboardSubTab(
            label: '회원',
            child: MemberManageTab(viewModel: memberViewModel),
          ),
        ],
      ),
      CommentManageTab(viewModel: commentViewModel),
      AdminProfileTab(
        staff: currentStaff,
        staffViewModel: staffViewModel,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.deepOrange,
      body: SafeArea(
        child: Row(
          children: [
            DashboardSideMenu(
              items: _menuItems,
              selectedIndex: _selectedMenuIndex,
              onSelected: (index) => setState(() => _selectedMenuIndex = index),
              bottomItemCount: 1,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: ColoredBox(
                    color: const Color(0xFFF6F7FA),
                    child: Column(
                      children: [
                        DashboardAppBar(
                          onHomePressed: () =>
                              setState(() => _selectedMenuIndex = 0),
                          staffName: currentStaff?.name ?? '로그인 직원',
                          staffRole: currentStaff?.role ?? '직급',
                        ),
                        Expanded(child: menuPages[_selectedMenuIndex]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Staff? _findCurrentStaff(
    List<Staff> staffs, {
    required String? staffSeq,
    required String? staffEmail,
  }) {
    final normalizedEmail = staffEmail?.toLowerCase();

    for (final staff in staffs) {
      if (staff.staffSeq == staffSeq ||
          staff.email.toLowerCase() == normalizedEmail) {
        return staff;
      }
    }

    return null;
  }
}
