import '../../../../../core/network/json_readers.dart';
import '../../domain/entities/staff.dart';

class StaffModel extends Staff {
  const StaffModel({
    required super.staffSeq,
    required super.staffName,
    required super.staffPhone,
    required super.staffId,
    required super.staffPw,
    required super.staffDate,
    required super.staffLevel,
    required super.staffSuperSeq,
    super.staffEmail,
    super.staffRole,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    final staffLevel = _staffLevelValue(json);

    return StaffModel(
      staffSeq: JsonReaders.stringValue(json, ['staffSeq', 'staff_seq']),
      staffName: JsonReaders.stringValue(json, ['staffName', 'staff_name']),
      staffPhone: JsonReaders.stringValue(json, ['staffPhone', 'staff_phone']),
      staffId: JsonReaders.stringValue(json, ['staffId', 'staff_id']),
      staffPw: JsonReaders.stringValue(json, ['staffPw', 'staff_pw']),
      staffDate: JsonReaders.dateTimeValue(json, ['staffDate', 'staff_date']),
      staffLevel: staffLevel,
      staffSuperSeq: JsonReaders.stringValue(json, [
        'staffSuperSeq',
        'staff_super_seq',
      ]),
      staffEmail: JsonReaders.stringValue(json, [
        'staffEmail',
        'staff_email',
        'email',
      ]),
      staffRole: _staffRoleValue(json, staffLevel),
    );
  }

  static int _staffLevelValue(Map<String, dynamic> json) {
    final numericLevel = JsonReaders.intValue(json, [
      'staffLevel',
      'staff_level',
    ], fallback: -1);

    if (numericLevel >= 0) {
      return numericLevel;
    }

    final role = JsonReaders.stringValue(json, ['staffLevel', 'staff_level']);

    return switch (role.toUpperCase()) {
      'CEO' || 'CTO' || '관리자' => 9,
      '대리' => 3,
      '주임' => 2,
      '사원' => 1,
      _ => 0,
    };
  }

  static String _staffRoleValue(Map<String, dynamic> json, int staffLevel) {
    final role = JsonReaders.stringValue(json, ['staffRole', 'staffLevel']);

    if (role.isNotEmpty && int.tryParse(role) == null) {
      return role;
    }

    return switch (staffLevel) {
      1 => '사원',
      2 => '주임',
      3 => '대리',
      >= 9 => '관리자',
      _ => '',
    };
  }
}
