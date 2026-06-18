import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../core/network/api_client.dart';
import '../../data/datasources/comment_remote_datasource.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/datasources/staff_remote_datasource.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/datasources/member_remote_datasource.dart';
import '../../data/datasources/purchase_order_remote_datasource.dart';
import '../../data/datasources/refund_remote_datasource.dart';
import '../../data/datasources/sales_order_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/create_inventory_item_usecase.dart';
import '../../domain/usecases/delete_comments_usecase.dart';
import '../../domain/usecases/get_inventory_categories_usecase.dart';
import '../../domain/usecases/create_staff_usecase.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';
import '../../domain/usecases/delete_staffs_usecase.dart';
import '../../domain/usecases/get_staffs_usecase.dart';
import '../../domain/usecases/get_inventory_items_usecase.dart';
import '../../domain/usecases/get_inventory_makers_usecase.dart';
import '../../domain/usecases/get_members_usecase.dart';
import '../../domain/usecases/get_purchase_orders_usecase.dart';
import '../../domain/usecases/get_refunds_usecase.dart';
import '../../domain/usecases/get_sales_orders_usecase.dart';
import '../../domain/usecases/get_stock_histories_usecase.dart';
import '../../domain/usecases/update_staff_password_usecase.dart';
import '../../domain/usecases/update_staff_phone_usecase.dart';
import '../../domain/usecases/update_refund_status_usecase.dart';
import '../../domain/usecases/verify_staff_password_usecase.dart';
import '../view_models/comment_view_model.dart';
import '../view_models/dashboard_view_model.dart';
import '../view_models/staff_view_model.dart';
import '../view_models/inventory_view_model.dart';
import '../view_models/member_view_model.dart';
import '../view_models/purchase_order_view_model.dart';
import '../view_models/refund_view_model.dart';
import '../view_models/sales_order_view_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return DashboardRepositoryImpl(
    dashboardRemoteDataSource: DashboardRemoteDataSource(apiClient),
    refundRemoteDataSource: RefundRemoteDataSource(apiClient),
    inventoryRemoteDataSource: InventoryRemoteDataSource(apiClient),
    salesOrderRemoteDataSource: SalesOrderRemoteDataSource(apiClient),
    purchaseOrderRemoteDataSource: PurchaseOrderRemoteDataSource(apiClient),
    staffRemoteDataSource: StaffRemoteDataSource(apiClient),
    memberRemoteDataSource: MemberRemoteDataSource(apiClient),
    commentRemoteDataSource: CommentRemoteDataSource(apiClient),
  );
});

final dashboardViewModelProvider = ChangeNotifierProvider<DashboardViewModel>((
  ref,
) {
  return DashboardViewModel(
    GetDashboardSummaryUseCase(ref.watch(dashboardRepositoryProvider)),
  );
});

final refundViewModelProvider = ChangeNotifierProvider<RefundViewModel>((ref) {
  return RefundViewModel(
    GetRefundsUseCase(ref.watch(dashboardRepositoryProvider)),
    UpdateRefundStatusUseCase(ref.watch(dashboardRepositoryProvider)),
  );
});

final inventoryViewModelProvider = ChangeNotifierProvider<InventoryViewModel>((
  ref,
) {
  return InventoryViewModel(
    GetInventoryItemsUseCase(ref.watch(dashboardRepositoryProvider)),
    GetInventoryCategoriesUseCase(ref.watch(dashboardRepositoryProvider)),
    GetInventoryMakersUseCase(ref.watch(dashboardRepositoryProvider)),
    GetStockHistoriesUseCase(ref.watch(dashboardRepositoryProvider)),
    CreateInventoryItemUseCase(ref.watch(dashboardRepositoryProvider)),
  );
});

final salesOrderViewModelProvider = ChangeNotifierProvider<SalesOrderViewModel>(
  (ref) {
    return SalesOrderViewModel(
      GetSalesOrdersUseCase(ref.watch(dashboardRepositoryProvider)),
    );
  },
);

final purchaseOrderViewModelProvider =
    ChangeNotifierProvider<PurchaseOrderViewModel>((ref) {
      return PurchaseOrderViewModel(
        GetPurchaseOrdersUseCase(ref.watch(dashboardRepositoryProvider)),
      );
    });

final staffViewModelProvider = ChangeNotifierProvider<StaffViewModel>((ref) {
  return StaffViewModel(
    GetStaffsUseCase(ref.watch(dashboardRepositoryProvider)),
    CreateStaffUseCase(ref.watch(dashboardRepositoryProvider)),
    UpdateStaffPhoneUseCase(ref.watch(dashboardRepositoryProvider)),
    UpdateStaffPasswordUseCase(ref.watch(dashboardRepositoryProvider)),
    VerifyStaffPasswordUseCase(ref.watch(dashboardRepositoryProvider)),
    DeleteStaffsUseCase(ref.watch(dashboardRepositoryProvider)),
  );
});

final memberViewModelProvider = ChangeNotifierProvider<MemberViewModel>((ref) {
  return MemberViewModel(
    GetMembersUseCase(ref.watch(dashboardRepositoryProvider)),
  );
});

final commentViewModelProvider = ChangeNotifierProvider<CommentViewModel>((
  ref,
) {
  return CommentViewModel(
    GetCommentsUseCase(ref.watch(dashboardRepositoryProvider)),
    DeleteCommentsUseCase(ref.watch(dashboardRepositoryProvider)),
  );
});
