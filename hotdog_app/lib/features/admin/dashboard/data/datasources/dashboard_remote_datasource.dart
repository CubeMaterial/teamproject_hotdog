import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_routes.dart';
import '../models/dashboard_summary_model.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardSummaryModel> getSummary() async {
    final data = await _apiClient.getMap(ApiRoutes.dashboardSummary);

    return DashboardSummaryModel.fromJson(data);
  }
}
