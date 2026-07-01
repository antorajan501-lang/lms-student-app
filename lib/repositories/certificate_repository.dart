import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/certificate_model.dart';

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CertificateRepository(apiClient: apiClient);
});

class CertificateRepository {
  final ApiClient apiClient;

  CertificateRepository({required this.apiClient});

  Future<List<CertificateModel>> getCertificates() async {
    try {
      final response = await apiClient.get(ApiEndpoints.certificateRecords);
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((c) => CertificateModel.fromJson(c as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> getCertificateUrl(int courseId) async {
    try {
      final response = await apiClient.get(ApiEndpoints.getCertificate(courseId));
      final responseData = response.data;
      if (responseData['success'] == true) {
        return responseData['data']['url'] as String? ??
               responseData['data']['certificate_url'] as String? ?? '';
      }
      throw ApiException(message: responseData['message'] ?? 'Failed to get certificate');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
