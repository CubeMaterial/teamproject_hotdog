import '../entities/comment.dart';
import '../entities/dashboard_summary.dart';
import '../entities/staff.dart';
import '../entities/staff_creation_result.dart';
import '../entities/inventory.dart';
import '../entities/member.dart';
import '../entities/purchase_order.dart';
import '../entities/refund.dart';
import '../entities/sales_order.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getDashboardSummary();
  Future<List<Refund>> getRefunds();
  Future<List<InventoryItem>> getInventoryItems();
  Future<List<StockHistory>> getStockHistories();
  Future<List<String>> getInventoryMakers();
  Future<InventoryItem> createInventoryItem({
    required String name,
    required String category,
    required String maker,
    required int price,
    required int stock,
  });
  Future<List<SalesOrder>> getSalesOrders();
  Future<List<PurchaseOrder>> getPurchaseOrders();
  Future<List<Staff>> getStaffs();
  Future<StaffCreationResult> createStaff({
    required String staffName,
    required String staffId,
    required String staffPhone,
    required int staffLevel,
  });
  Future<Staff> updateStaffPhone({
    required String staffSeq,
    required String staffPhone,
  });
  Future<void> updateStaffPassword({
    required String staffSeq,
    required String currentPassword,
    required String newPassword,
  });
  Future<void> verifyStaffPassword({
    required String staffSeq,
    required String currentPassword,
  });
  Future<void> deleteStaff(String staffSeq);
  Future<List<Member>> getMembers();
  Future<List<String>> getInventoryCategories();
  Future<List<AdminComment>> getComments();
  Future<void> deleteComment(String commentId);
}
