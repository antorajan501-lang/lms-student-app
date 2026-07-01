import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/course_model.dart';
import '../models/chapter_model.dart';
import '../models/lesson_model.dart';
import '../models/category_model.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CourseRepository(apiClient: apiClient);
});

class CourseRepository {
  final ApiClient apiClient;

  CourseRepository({required this.apiClient});

  // ── Public Courses ────────────────────────────────────────────────────────
  Future<List<CourseModel>> getCourses({
    int page = 1,
    int? categoryId,
    String? search,
    int perPage = 15,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'per_page': perPage,
        if (categoryId != null) 'category_id': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await apiClient.get(
        ApiEndpoints.courses,
        queryParameters: queryParams,
      );

      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((c) => CourseModel.fromJson(c as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Course Detail ─────────────────────────────────────────────────────────
  Future<CourseModel> getCourseDetail(int courseId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.courseDetail,
        queryParameters: {'course_id': courseId},
      );

      final responseData = response.data;
      if (responseData['success'] == true) {
        return CourseModel.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      throw const ApiException(message: 'Failed to retrieve course details');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Chapters & Lessons ────────────────────────────────────────────────────
  Future<List<ChapterModel>> getChapters(int courseId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.courseChapters,
        queryParameters: {'course_id': courseId},
      );

      final responseData = response.data;
      // Depending on API version, response can wrap data in 'data' key or return array directly
      final rawList = responseData is Map ? (responseData['data'] as List? ?? []) : (responseData as List? ?? []);
      return rawList.map((c) => ChapterModel.fromJson(c as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<LessonModel>> getLessons(int chapterId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.lessons,
        queryParameters: {'chapter_id': chapterId},
      );

      final responseData = response.data;
      final rawList = responseData is Map ? (responseData['data'] as List? ?? []) : (responseData as List? ?? []);
      return rawList.map((l) => LessonModel.fromJson(l as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Fetch full detail for a single lesson (url, content, type).
  Future<LessonModel> getLessonDetail(int lessonId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.lessonDetail,
        queryParameters: {'lesson_id': lessonId},
      );
      final responseData = response.data;
      final data = responseData['data'] ?? responseData;
      return LessonModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Returns all chapters with their lessons for a course — used by the lesson sidebar.
  Future<List<ChapterModel>> getCourseWithChapters(int courseId) async {
    final chapters = await getChapters(courseId);
    final chaptersWithLessons = await Future.wait(
      chapters.map((chapter) async {
        try {
          final lessons = await getLessons(chapter.id);
          return chapter.copyWith(lessons: lessons);
        } catch (_) {
          return chapter.copyWith(lessons: []);
        }
      }),
    );
    return chaptersWithLessons;
  }

  // ── My Enrolled Courses ───────────────────────────────────────────────────
  Future<List<CourseModel>> getMyCourses({String? search}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.myCourses,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((c) => CourseModel.fromJson(c as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Wishlist ──────────────────────────────────────────────────────────────
  Future<List<CourseModel>> getWishlist() async {
    try {
      final response = await apiClient.get(ApiEndpoints.wishlist);
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((c) => CourseModel.fromJson(c as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<bool> toggleWishlist(int courseId) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.wishlistToggle,
        data: {'course_id': courseId},
      );
      final responseData = response.data;
      if (responseData['success'] == true) {
        return responseData['in_wishlist'] as bool? ?? false;
      }
      throw const ApiException(message: 'Failed to toggle wishlist');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiClient.get(ApiEndpoints.categories);
      final responseData = response.data;
      if (responseData['success'] == true) {
        final List list = responseData['data'] ?? [];
        return list.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Lesson Completion ─────────────────────────────────────────────────────
  Future<void> markLessonComplete({required int courseId, required int lessonId, required bool isComplete}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.lessonComplete,
        data: {
          'course_id': courseId,
          'lesson_id': lessonId,
          'status': isComplete ? 1 : 0,
        },
      );
      final responseData = response.data;
      if (responseData['success'] != true) {
        throw ApiException(message: responseData['message'] ?? 'Failed to update lesson completion');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Get My Live Classes ───────────────────────────────────────────────────
  Future<List<dynamic>> getMyClasses() async {
    try {
      final response = await apiClient.get(ApiEndpoints.myClasses);
      final responseData = response.data;
      if (responseData['success'] == true) {
        return responseData['data'] as List? ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Course Enrollment ──────────────────────────────────────────────────────
  Future<bool> enrollInCourse(int courseId) async {
    try {
      final response = await apiClient.get('${ApiEndpoints.addToCart}/$courseId');
      final responseData = response.data;
      if (responseData['success'] == true) {
        return true;
      }
      throw ApiException(message: responseData['message'] ?? 'Failed to enroll in course');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}


