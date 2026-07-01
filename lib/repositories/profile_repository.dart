import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/user_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient: apiClient);
});

class ProfileRepository {
  final ApiClient apiClient;

  ProfileRepository({required this.apiClient});

  Future<UserModel> getProfile() async {
    try {
      final response = await apiClient.get(ApiEndpoints.userDetail);
      final responseData = response.data;
      if (responseData['success'] == true) {
        return UserModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: responseData['message'] ?? 'Failed to load profile');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> updateBasicInfo({
    required String name,
    required String jobTitle,
    required String aboutMe,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.updateBasicInfo,
        data: {
          'name': name,
          'job_title': jobTitle,
          'about_me': aboutMe,
        },
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        final userData = responseData['data'] as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      }
      // Extract validation errors if present
      final errors = responseData['errors'];
      String errorMsg = responseData['message'] ?? 'Failed to update profile';
      if (errors is Map) {
        final firstError = (errors.values.first as List?)?.first?.toString();
        if (firstError != null) errorMsg = firstError;
      }
      throw ApiException(message: errorMsg);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateAbout(String about, {String? jobTitle}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.updateAbout,
        // Backend expects 'short_description', not 'about'
        data: {
          'short_description': about,
          if (jobTitle != null && jobTitle.isNotEmpty) 'job_title': jobTitle,
        },
      );
      final responseData = response.data;
      if (responseData['success'] != true) {
        final errors = responseData['errors'];
        String errorMsg = responseData['message'] ?? 'Failed to update about';
        if (errors is Map) {
          final firstError = (errors.values.first as List?)?.first?.toString();
          if (firstError != null) errorMsg = firstError;
        }
        throw ApiException(message: errorMsg);
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      final responseData = response.data;
      if (responseData['success'] != true) {
        throw ApiException(message: responseData['message'] ?? 'Failed to change password');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
      });
      final response = await apiClient.post(
        ApiEndpoints.updateBasicInfo,
        data: formData,
      );
      final responseData = response.data;
      if (responseData['success'] != true) {
        throw ApiException(message: responseData['message'] ?? 'Failed to upload avatar');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await apiClient.post(ApiEndpoints.deleteAccount);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
