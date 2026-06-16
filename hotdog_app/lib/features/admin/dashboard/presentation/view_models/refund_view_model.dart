import 'package:flutter/foundation.dart';

import '../../domain/entities/refund.dart';
import '../../domain/usecases/get_refunds_usecase.dart';

class RefundViewModel extends ChangeNotifier {
  RefundViewModel(this._getRefundsUseCase);
  final GetRefundsUseCase _getRefundsUseCase;
  List<Refund> refunds = [];
  Future<void> load() async {
    refunds = await _getRefundsUseCase();
    notifyListeners();
  }
}
