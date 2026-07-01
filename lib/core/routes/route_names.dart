class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  
  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';

  // Shell Tabs
  static const String dashboard = '/dashboard';
  static const String myCourses = '/my-courses';
  static const String coursesCatalog = '/courses-catalog';
  static const String wishlist = '/wishlist';
  static const String profile = '/profile';

  // Details & Modals
  static const String courseDetail = '/course-detail';
  static const String lessonViewer = '/lesson-viewer';
  static const String quizAttempt = '/quiz-attempt';
  static const String quizResult = '/quiz-result';
  static const String certificates = '/certificates';
  static const String profileEdit = '/profile-edit';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String downloads = '/downloads';
  
  // New Migrated Web Modules
  static const String calendar = '/calendar';
  static const String studyMaterials = '/study-materials';
  static const String assignments = '/assignments';
  static const String purchaseHistory = '/purchase-history';
  static const String loggedDevices = '/logged-in-devices';
}
