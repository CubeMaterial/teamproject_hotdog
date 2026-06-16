import 'package:flutter/foundation.dart';

import '../../domain/entities/member.dart';
import '../../domain/usecases/get_members_usecase.dart';

class MemberViewModel extends ChangeNotifier {
  MemberViewModel(this._getMembersUseCase);
  final GetMembersUseCase _getMembersUseCase;
  List<Member> members = [];
  Future<void> load() async {
    members = await _getMembersUseCase();
    notifyListeners();
  }
}
