import 'package:flutter/foundation.dart';

import '../../domain/entities/refund.dart';
import '../../domain/usecases/get_refunds_usecase.dart';
import '../../domain/usecases/update_refund_status_usecase.dart';

class RefundViewModel extends ChangeNotifier {
  RefundViewModel(this._getRefundsUseCase, this._updateRefundStatusUseCase);

  final GetRefundsUseCase _getRefundsUseCase;
  final UpdateRefundStatusUseCase _updateRefundStatusUseCase;

  List<Refund> refunds = [];

  Future<void> load() async {
    refunds = await _getRefundsUseCase();
    notifyListeners();
  }

  Future<void> updateStatus({
    required String refundId,
    required String action,
  }) async {
    await _updateRefundStatusUseCase(refundId: refundId, action: action);
    await load();
  }
}
