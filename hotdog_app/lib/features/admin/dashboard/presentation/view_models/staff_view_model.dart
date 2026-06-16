import 'package:flutter/foundation.dart';

import '../../domain/entities/staff.dart';
import '../../domain/entities/staff_creation_result.dart';
import '../../domain/usecases/create_staff_usecase.dart';
import '../../domain/usecases/delete_staffs_usecase.dart';
import '../../domain/usecases/get_staffs_usecase.dart';
import '../../domain/usecases/update_staff_password_usecase.dart';
import '../../domain/usecases/update_staff_phone_usecase.dart';
import '../../domain/usecases/verify_staff_password_usecase.dart';

class StaffViewModel extends ChangeNotifier {
  StaffViewModel(
    this._getStaffsUseCase,
    this._createStaffUseCase,
    this._updateStaffPhoneUseCase,
    this._updateStaffPasswordUseCase,
    this._verifyStaffPasswordUseCase,
    this._deleteStaffsUseCase,
  );

  final GetStaffsUseCase _getStaffsUseCase;
  final CreateStaffUseCase _createStaffUseCase;
  final UpdateStaffPhoneUseCase _updateStaffPhoneUseCase;
  final UpdateStaffPasswordUseCase _updateStaffPasswordUseCase;
  final VerifyStaffPasswordUseCase _verifyStaffPasswordUseCase;
  final DeleteStaffsUseCase _deleteStaffsUseCase;
  List<Staff> staffs = [];
  Future<void> load() async {
    staffs = await _getStaffsUseCase();
    notifyListeners();
  }

  Future<StaffCreationResult> createStaff({
    required String staffName,
    required String staffId,
    required String staffPhone,
    required int staffLevel,
  }) async {
    final result = await _createStaffUseCase(
      staffName: staffName,
      staffId: staffId,
      staffPhone: staffPhone,
      staffLevel: staffLevel,
    );
    staffs = [result.staff, ...staffs];
    notifyListeners();

    return result;
  }

  Future<Staff> updateStaffPhone({
    required String staffSeq,
    required String staffPhone,
  }) async {
    final updatedStaff = await _updateStaffPhoneUseCase(
      staffSeq: staffSeq,
      staffPhone: staffPhone,
    );
    staffs = [
      for (final staff in staffs)
        if (staff.staffSeq == updatedStaff.staffSeq) updatedStaff else staff,
    ];
    notifyListeners();

    return updatedStaff;
  }

  Future<void> updateStaffPassword({
    required String staffSeq,
    required String currentPassword,
    required String newPassword,
  }) {
    return _updateStaffPasswordUseCase(
      staffSeq: staffSeq,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> verifyStaffPassword({
    required String staffSeq,
    required String currentPassword,
  }) {
    return _verifyStaffPasswordUseCase(
      staffSeq: staffSeq,
      currentPassword: currentPassword,
    );
  }

  Future<void> deleteStaffs(Iterable<String> staffSeqs) async {
    final ids = staffSeqs.toSet();
    await _deleteStaffsUseCase(ids);
    staffs = [
      for (final staff in staffs)
        if (!ids.contains(staff.staffSeq)) staff,
    ];
    notifyListeners();
  }
}
