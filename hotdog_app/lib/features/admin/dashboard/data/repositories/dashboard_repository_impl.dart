import '../../domain/entities/comment.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/staff.dart';
import '../../domain/entities/staff_creation_result.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/entities/refund.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/comment_remote_datasource.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../datasources/staff_remote_datasource.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../datasources/member_remote_datasource.dart';
import '../datasources/purchase_order_remote_datasource.dart';
import '../datasources/refund_remote_datasource.dart';
import '../datasources/sales_order_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required this.dashboardRemoteDataSource,
    required this.refundRemoteDataSource,
    required this.inventoryRemoteDataSource,
    required this.salesOrderRemoteDataSource,
    required this.purchaseOrderRemoteDataSource,
    required this.staffRemoteDataSource,
    required this.memberRemoteDataSource,
    required this.commentRemoteDataSource,
  });

  final DashboardRemoteDataSource dashboardRemoteDataSource;
  final RefundRemoteDataSource refundRemoteDataSource;
  final InventoryRemoteDataSource inventoryRemoteDataSource;
  final SalesOrderRemoteDataSource salesOrderRemoteDataSource;
  final PurchaseOrderRemoteDataSource purchaseOrderRemoteDataSource;
  final StaffRemoteDataSource staffRemoteDataSource;
  final MemberRemoteDataSource memberRemoteDataSource;
  final CommentRemoteDataSource commentRemoteDataSource;

  @override
  Future<DashboardSummary> getDashboardSummary() =>
      dashboardRemoteDataSource.getSummary();

  @override
  Future<List<Refund>> getRefunds() => refundRemoteDataSource.getRefunds();

  @override
  Future<List<InventoryItem>> getInventoryItems() =>
      inventoryRemoteDataSource.getInventoryItems();

  @override
  Future<List<StockHistory>> getStockHistories() =>
      inventoryRemoteDataSource.getStockHistories();

  @override
  Future<List<String>> getInventoryMakers() =>
      inventoryRemoteDataSource.getInventoryMakers();

  @override
  Future<InventoryItem> createInventoryItem({
    required String name,
    required String category,
    required String maker,
    required int price,
    required int stock,
  }) => inventoryRemoteDataSource.createInventoryItem(
    name: name,
    category: category,
    maker: maker,
    price: price,
    stock: stock,
  );

  @override
  Future<List<SalesOrder>> getSalesOrders() =>
      salesOrderRemoteDataSource.getSalesOrders();

  @override
  Future<List<PurchaseOrder>> getPurchaseOrders() =>
      purchaseOrderRemoteDataSource.getPurchaseOrders();

  @override
  Future<List<Staff>> getStaffs() => staffRemoteDataSource.getStaffs();

  @override
  Future<StaffCreationResult> createStaff({
    required String staffName,
    required String staffId,
    required String staffPhone,
    required int staffLevel,
  }) {
    return staffRemoteDataSource.createStaff(
      staffName: staffName,
      staffId: staffId,
      staffPhone: staffPhone,
      staffLevel: staffLevel,
    );
  }

  @override
  Future<Staff> updateStaffPhone({
    required String staffSeq,
    required String staffPhone,
  }) {
    return staffRemoteDataSource.updateStaffPhone(
      staffSeq: staffSeq,
      staffPhone: staffPhone,
    );
  }

  @override
  Future<void> updateStaffPassword({
    required String staffSeq,
    required String currentPassword,
    required String newPassword,
  }) {
    return staffRemoteDataSource.updateStaffPassword(
      staffSeq: staffSeq,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> verifyStaffPassword({
    required String staffSeq,
    required String currentPassword,
  }) {
    return staffRemoteDataSource.verifyStaffPassword(
      staffSeq: staffSeq,
      currentPassword: currentPassword,
    );
  }

  @override
  Future<void> deleteStaff(String staffSeq) {
    return staffRemoteDataSource.deleteStaff(staffSeq);
  }

  @override
  Future<List<Member>> getMembers() => memberRemoteDataSource.getMembers();

  @override
  Future<List<AdminComment>> getComments() =>
      commentRemoteDataSource.getComments();

  @override
  Future<void> deleteComment(String commentId) =>
      commentRemoteDataSource.deleteComment(commentId);

  @override
  Future<List<String>> getInventoryCategories() =>
      inventoryRemoteDataSource.getInventoryCategories();
}
