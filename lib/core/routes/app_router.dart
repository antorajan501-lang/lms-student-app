import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';
import 'route_names.dart';

// Screens
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/verify_otp_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/main_layout.dart';
import '../../features/courses/my_courses_screen.dart';
import '../../features/courses/courses_screen.dart';
import '../../features/courses/course_detail_screen.dart';
import '../../features/courses/search_screen.dart';
import '../../features/courses/wishlist_screen.dart';
import '../../features/lessons/lesson_viewer_screen.dart';
import '../../features/quizzes/quiz_attempt_screen.dart';
import '../../features/quizzes/quiz_result_screen.dart';
import '../../features/certificates/certificates_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/profile_edit_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/downloads/downloads_screen.dart';

// New Migrated Screens
import '../../features/calendar/calendar_screen.dart';
import '../../features/study_material/study_materials_screen.dart';
import '../../features/assignments/assignments_screen.dart';
import '../../features/purchase_history/purchase_history_screen.dart';
import '../../features/devices/devices_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(secureStorageProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final isLoggedIn = await storage.isLoggedIn();
      final path = state.uri.path;

      // Public / Auth routes
      final isAuthRoute = path == AppRoutes.login ||
          path == AppRoutes.register ||
          path == AppRoutes.forgotPassword ||
          path == AppRoutes.verifyOtp ||
          path == AppRoutes.resetPassword ||
          path == AppRoutes.onboarding ||
          path == AppRoutes.splash;

      if (!isLoggedIn) {
        if (!isAuthRoute) {
          return AppRoutes.login;
        }
      } else {
        if (path == AppRoutes.login || path == AppRoutes.register || path == AppRoutes.splash) {
          return AppRoutes.dashboard;
        }
      }
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Login
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // Register
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      // Forgot Password
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Verify OTP
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyOtpScreen(email: email);
        },
      ),
      // Reset Password
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final otp = state.uri.queryParameters['otp'] ?? '';
          return ResetPasswordScreen(email: email, otp: otp);
        },
      ),

      // Shell for bottom navigation tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Courses Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.coursesCatalog,
                builder: (context, state) => const CoursesScreen(),
              ),
            ],
          ),
          // Assignments Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.assignments,
                builder: (context, state) => const AssignmentsScreen(),
              ),
            ],
          ),
          // Calendar Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          // Profile Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Course Detail
      GoRoute(
        path: AppRoutes.courseDetail,
        builder: (context, state) {
          final courseId = int.tryParse(state.uri.queryParameters['courseId'] ?? '') ?? 0;
          return CourseDetailScreen(courseId: courseId);
        },
      ),
      // My Courses (Standalone Page)
      GoRoute(
        path: AppRoutes.myCourses,
        builder: (context, state) => const MyCoursesScreen(),
      ),
      // Wishlist
      GoRoute(
        path: AppRoutes.wishlist,
        builder: (context, state) => const WishlistScreen(),
      ),
      // Lesson Viewer
      GoRoute(
        path: AppRoutes.lessonViewer,
        builder: (context, state) {
          final courseId = int.tryParse(state.uri.queryParameters['courseId'] ?? '') ?? 0;
          final lessonId = int.tryParse(state.uri.queryParameters['lessonId'] ?? '');
          return LessonViewerScreen(courseId: courseId, lessonId: lessonId);
        },
      ),
      // Quiz Attempt
      GoRoute(
        path: AppRoutes.quizAttempt,
        builder: (context, state) {
          final courseId = int.tryParse(state.uri.queryParameters['courseId'] ?? '') ?? 0;
          final quizId = int.tryParse(state.uri.queryParameters['quizId'] ?? '') ?? 0;
          return QuizAttemptScreen(courseId: courseId, quizId: quizId);
        },
      ),
      // Quiz Result
      GoRoute(
        path: AppRoutes.quizResult,
        builder: (context, state) {
          final courseId = int.tryParse(state.uri.queryParameters['courseId'] ?? '') ?? 0;
          final quizId = int.tryParse(state.uri.queryParameters['quizId'] ?? '') ?? 0;
          return QuizResultScreen(courseId: courseId, quizId: quizId);
        },
      ),
      // Certificates List
      GoRoute(
        path: AppRoutes.certificates,
        builder: (context, state) => const CertificatesScreen(),
      ),
      // Profile Edit
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const ProfileEditScreen(),
      ),
      // Notifications List
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      // Search
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      // Settings
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      // Downloads
      GoRoute(
        path: AppRoutes.downloads,
        builder: (context, state) => const DownloadsScreen(),
      ),
      // Study Materials
      GoRoute(
        path: AppRoutes.studyMaterials,
        builder: (context, state) => const StudyMaterialsScreen(),
      ),
      // Purchase History
      GoRoute(
        path: AppRoutes.purchaseHistory,
        builder: (context, state) => const PurchaseHistoryScreen(),
      ),
      // Logged Devices
      GoRoute(
        path: AppRoutes.loggedDevices,
        builder: (context, state) => const DevicesScreen(),
      ),
    ],
  );
});
