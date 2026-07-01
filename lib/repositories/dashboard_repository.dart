import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_stats_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepository(apiClient: apiClient);
});

class DashboardRepository {
  final ApiClient apiClient;

  DashboardRepository({required this.apiClient});

  /// Fetch all 8 summary stats from the unified /student/dashboard endpoint.
  /// Returns [DashboardStatsData.zero()] on any error so the UI never breaks.
  Future<DashboardStatsData> getUnifiedStats() async {
    try {
      final response = await apiClient.get(ApiEndpoints.dashboard);
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData?['success'] == true) {
        final data = responseData!['data'] as Map<String, dynamic>? ?? {};
        return DashboardStatsData.fromJson(data);
      }
      return DashboardStatsData.zero();
    } catch (_) {
      return DashboardStatsData.zero();
    }
  }

  Future<DashboardModel> getDashboard() async {
    try {
      final response = await apiClient.get(ApiEndpoints.dashboard);
      final responseData = response.data;
      if (responseData['success'] == true) {
        return DashboardModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: responseData['message'] ?? 'Failed to load dashboard');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<double> getWalletBalance() async {
    try {
      final base = ApiEndpoints.base;
      final userUrl = base.endsWith('/v2')
          ? '${base.substring(0, base.length - 3)}/user'
          : '$base/user';
      final response = await apiClient.get(userUrl);
      final responseData = response.data;
      if (responseData['success'] == true) {
        final data = responseData['data'];
        final balance = data['balance'];
        return (balance as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<double> getTotalSpent() async {
    try {
      final response = await apiClient.get(ApiEndpoints.purchaseHistory);
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        double total = 0.0;
        for (var item in list) {
          final purchasePrice = (item['purchase_price'] as num?)?.toDouble() ?? 0.0;
          total += purchasePrice;
        }
        return total;
      }
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> getCourseProgress(int courseId) async {
    try {
      final response = await apiClient.get(ApiEndpoints.courseProgress(courseId));
      final responseData = response.data;
      if (responseData['success'] == true) {
        return responseData['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: responseData['message'] ?? 'Failed to load progress');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
