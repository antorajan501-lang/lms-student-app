import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient: apiClient);
});

class NotificationRepository {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await apiClient.get(ApiEndpoints.notifications);
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((n) => NotificationModel.fromJson(n as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await apiClient.post(ApiEndpoints.markAllRead);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> setFcmToken(String token) async {
    try {
      await apiClient.post(
        ApiEndpoints.setFcmToken,
        data: {'fcm_token': token},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
