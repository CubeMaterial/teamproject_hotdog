import '../../../../../core/network/json_readers.dart';
import '../../domain/entities/member.dart';

class MemberModel extends Member {
  const MemberModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.status,
    required super.joinedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: JsonReaders.stringValue(json, ['id', 'user_seq']),
      name: JsonReaders.stringValue(json, ['name', 'user_name']),
      email: JsonReaders.stringValue(json, ['email', 'user_id']),
      phone: JsonReaders.stringValue(json, ['phone', 'user_phone']),
      status: JsonReaders.stringValue(json, ['status'], fallback: '일반'),
      joinedAt: JsonReaders.dateTimeValue(json, ['joinedAt', 'user_date']),
    );
  }
}
