import 'package:flutter/foundation.dart';

/// All API endpoint constants.
/// Base URL is read from the build environment; falls back to localhost for dev.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Base ────────────────────────────────────────────────────────────────
  /// Base API URL.
  /// - Android emulator → 10.0.2.2 maps to host 127.0.0.1
  /// - iOS simulator / Web / Desktop → use 127.0.0.1/localhost directly
  /// - Physical device  → use your machine's LAN IP (e.g. 192.168.x.x)
  /// Override at build time:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v2
  static final String _base = const bool.hasEnvironment('API_BASE_URL')
      ? const String.fromEnvironment('API_BASE_URL')
      : (kIsWeb
          ? 'http://10.100.10.29:8000/api/v2'
          : (defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.100.10.29:8000/api/v2'
              : 'http://10.100.10.29:8000/api/v2'));

  static String get base => _base;

  // ── Auth (no token required) ────────────────────────────────────────────
  static const String login          = '/login';
  static const String register       = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp      = '/verify-email';
  static const String resetPassword  = '/reset-otp-password';

  // ── Auth (token required) ───────────────────────────────────────────────
  static const String logout         = '/logout';
  static const String userDetail     = '/user-detail';
  static const String setFcmToken    = '/set-fcm-token';
  static const String changePassword = '/set-password';
  static const String deleteAccount  = '/remove-self-account';

  // ── Profile ─────────────────────────────────────────────────────────────
  static const String updateBasicInfo   = '/user-update-basicinfo';
  static const String updateAbout       = '/user-update-about';
  static const String updateSocialInfo  = '/user-socialinfo-update';

  // ── Courses (public) ─────────────────────────────────────────────────────
  static const String courses        = '/courses';
  static const String courseDetail   = '/course-detail';
  static const String courseChapters = '/course-chapters';
  static const String lessons        = '/lessons';
  static const String categories     = '/course-category-list';
  static const String topCategories  = '/top-categories';
  static const String searchCourse   = '/search-course';
  static const String filterCourse   = '/filter-course';
  static const String lessonDetail   = '/lesson-detail';
  static const String languages      = '/language-list';
  static const String settings       = '/settings';

  // ── Student (auth) ────────────────────────────────────────────────────────
  static const String myCourses        = '/my-courses';
  static const String myClasses        = '/my-classes';
  static const String myQuizzes        = '/my-quizzes';
  static const String lessonComplete   = '/lesson-complete';
  static const String authCourses      = '/auth-courses';
  static const String purchaseHistory  = '/student/purchase-history';
  static const String loggedDevices    = '/login-devices';
  static const String logoutDevice     = '/logout-device';

  // ── Dashboard (new) ───────────────────────────────────────────────────────
  static const String dashboard        = '/student/dashboard';
  static String courseProgress(int id) => '/student/course-progress/$id';

  // ── Wishlist (new) ────────────────────────────────────────────────────────
  static const String wishlist       = '/wishlist';
  static const String wishlistToggle = '/wishlist/toggle';

  // ── Quizzes ──────────────────────────────────────────────────────────────
  static String quizStart(int courseId, int quizId) =>
      '/quiz-start/$courseId/$quizId';
  static const String quizSingleSubmit = '/quiz-single-submit';
  static const String quizFinalSubmit  = '/quiz-final-submit';
  static String quizResult(int courseId, int quizId) =>
      '/quiz-result/$courseId/$quizId';
  static const String quizHistory      = '/quiz-history';

  // ── Certificates ─────────────────────────────────────────────────────────
  static const String certificateRecords = '/certificate-records';
  static String getCertificate(int id)   => '/get-course-certificate/$id';

  // ── Notifications ────────────────────────────────────────────────────────
  static const String notifications    = '/notifications';
  static const String markAllRead      = '/NotificationMakeAllRead';

  // ── Cart ─────────────────────────────────────────────────────────────────
  static const String cartList    = '/cart-list';
  static const String addToCart   = '/add-to-cart';
  static const String removeCart  = '/remove-to-cart';

  // ── Review ───────────────────────────────────────────────────────────────
  static const String submitReview = '/submit-review';

  // ── Language ─────────────────────────────────────────────────────────────
  static const String getLang = '/get-lang';
  static const String setLang = '/set-lang';
}
