import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../core/storage/secure_storage.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(apiClient: apiClient, storage: storage);
});

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorage storage;

  AuthRepository({required this.apiClient, required this.storage});

  Future<UserModel> login({required String email, required String password}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final responseData = response.data;
      if (responseData['success'] == true) {
        final data = responseData['data'];
        final token = data['access_token'] as String;
        await storage.saveToken(token);

        final userData = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        
        await storage.saveUserData(
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.roleId,
        );

        return user;
      } else {
        throw ApiException(message: responseData['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': confirmPassword,
          'type': 'student', // explicit student role
        },
      );

      final responseData = response.data;
      if (responseData['success'] != true) {
        throw ApiException(message: responseData['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      final responseData = response.data;
      if (responseData['success'] != true) {
        throw ApiException(message: responseData['message'] ?? 'Failed to send OTP');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {
          'email': email,
          'otp': otp,
          'type': 'reset', // reset flow verification
        },
      );
      final responseData = response.data;
      if (responseData['success'] != true) {
        throw ApiException(message: responseData['message'] ?? 'OTP verification failed');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'otp': otp,
          'password': password,
          'password_confirmation': confirmPassword,
        },
      );
      final responseData = response.data;
      if (responseData['success'] != true) {
        throw ApiException(message: responseData['message'] ?? 'Password reset failed');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // even if API logout fails, clear storage locally
    } finally {
      await storage.clearAll();
    }
  }
}
