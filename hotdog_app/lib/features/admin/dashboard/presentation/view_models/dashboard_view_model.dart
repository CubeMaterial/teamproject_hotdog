import 'package:flutter/foundation.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._getDashboardSummaryUseCase);

  final GetDashboardSummaryUseCase _getDashboardSummaryUseCase;
  DashboardSummary? summary;
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      summary = await _getDashboardSummaryUseCase();
    } catch (error, stackTrace) {
      debugPrint('Failed to load dashboard summary: $error');
      debugPrintStack(stackTrace: stackTrace);
      summary = DashboardSummaryModel.empty();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
