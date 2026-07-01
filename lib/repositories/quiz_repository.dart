import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/quiz_model.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return QuizRepository(apiClient: apiClient);
});

class QuizRepository {
  final ApiClient apiClient;

  QuizRepository({required this.apiClient});

  // ── Start Quiz ────────────────────────────────────────────────────────────
  Future<QuizModel> startQuiz({required int courseId, required int quizId}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.quizStart(courseId, quizId),
      );

      final responseData = response.data;
      if (responseData['success'] == true) {
        return QuizModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: responseData['message'] ?? 'Failed to start quiz');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Submit Single Answer ──────────────────────────────────────────────────
  Future<void> submitSingleAnswer({
    required int courseId,
    required int quizId,
    required int questionId,
    required int answerId,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.quizSingleSubmit,
        data: {
          'course_id': courseId,
          'quiz_id': quizId,
          'question_id': questionId,
          'answer_id': answerId,
        },
      );
      final responseData = response.data;
      if (responseData['success'] != true) {
        throw ApiException(message: responseData['message'] ?? 'Failed to submit answer');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Final Submit ──────────────────────────────────────────────────────────
  Future<QuizResultModel> finalSubmit({
    required int courseId,
    required int quizId,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.quizFinalSubmit,
        data: {
          'course_id': courseId,
          'quiz_id': quizId,
        },
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        return QuizResultModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: responseData['message'] ?? 'Failed to submit quiz');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Quiz Result ───────────────────────────────────────────────────────────
  Future<QuizResultModel> getQuizResult({required int courseId, required int quizId}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.quizResult(courseId, quizId),
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        return QuizResultModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: responseData['message'] ?? 'Failed to get quiz result');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Quiz History ──────────────────────────────────────────────────────────
  Future<List<QuizResultModel>> getQuizHistory() async {
    try {
      final response = await apiClient.get(ApiEndpoints.quizHistory);
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((q) => QuizResultModel.fromJson(q as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── My Quizzes ────────────────────────────────────────────────────────────
  Future<List<QuizModel>> getMyQuizzes() async {
    try {
      final response = await apiClient.get(ApiEndpoints.myQuizzes);
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((q) => QuizModel.fromJson(q as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
