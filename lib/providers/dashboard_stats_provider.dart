import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_currency.dart';
import '../repositories/dashboard_repository.dart';

/// Holds all 8 summary card values + currency symbol.
class DashboardStatsData {
  final double balance;
  final double totalSpent;
  final int certificates;
  final int coursesInProgress;
  final int coursesPurchased;
  final int completedCourses;
  final int pendingQuizzes;
  final int totalQuizzes;
  final int pendingAssignments;
  final int totalAssignments;
  final String currencySymbol;

  const DashboardStatsData({
    required this.balance,
    required this.totalSpent,
    required this.certificates,
    required this.coursesInProgress,
    required this.coursesPurchased,
    required this.completedCourses,
    required this.pendingQuizzes,
    required this.totalQuizzes,
    required this.pendingAssignments,
    required this.totalAssignments,
    this.currencySymbol = AppCurrency.symbol,
  });

  /// All zeros shown immediately before API responds.
  factory DashboardStatsData.zero() {
    return const DashboardStatsData(
      balance: 0.0,
      totalSpent: 0.0,
      certificates: 0,
      coursesInProgress: 0,
      coursesPurchased: 0,
      completedCourses: 0,
      pendingQuizzes: 0,
      totalQuizzes: 0,
      pendingAssignments: 0,
      totalAssignments: 0,
    );
  }

  /// Parse from the unified /student/dashboard JSON response.
  factory DashboardStatsData.fromJson(Map<String, dynamic> json) {
    // NOTE: We intentionally ignore json['currency_symbol'] — the app always
    // displays Indian Rupee (₹) regardless of what the backend sends.
    return DashboardStatsData(
      balance:             (json['balance'] as num?)?.toDouble() ?? 0.0,
      totalSpent:          (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      certificates:        (json['certificates'] as num?)?.toInt() ?? 0,
      coursesInProgress:   (json['courses_in_progress'] as num?)?.toInt() ?? 0,
      coursesPurchased:    (json['courses_purchased'] as num?)?.toInt() ?? 0,
      completedCourses:    (json['completed_courses'] as num?)?.toInt() ?? 0,
      pendingQuizzes:      (json['pending_quizzes'] as num?)?.toInt() ?? 0,
      totalQuizzes:        (json['total_quizzes'] as num?)?.toInt() ?? 0,
      pendingAssignments:  (json['pending_assignments'] as num?)?.toInt() ?? 0,
      totalAssignments:    (json['total_assignments'] as num?)?.toInt() ?? 0,
      // Always ₹ — never from API
      currencySymbol: AppCurrency.symbol,
    );
  }
}

// -- AsyncNotifier ------------------------------------------------------------
// build() always resolves to AsyncData so cards never disappear or flash.

class DashboardStatsNotifier extends AsyncNotifier<DashboardStatsData> {
  @override
  Future<DashboardStatsData> build() async {
    final repo = ref.watch(dashboardRepositoryProvider);
    try {
      return await repo.getUnifiedStats();
    } catch (_) {
      // On error keep zeros visible so layout never breaks.
      return DashboardStatsData.zero();
    }
  }

  Future<void> refresh() async {
    final prev = state.valueOrNull ?? DashboardStatsData.zero();
    state = AsyncData(prev); // keep current data while refreshing
    final repo = ref.read(dashboardRepositoryProvider);
    try {
      final data = await repo.getUnifiedStats();
      state = AsyncData(data);
    } catch (_) {
      // Silently keep previous values on refresh failure
    }
  }
}

/// The canonical provider used everywhere in the UI.
final dashboardStatsNotifierProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, DashboardStatsData>(
  DashboardStatsNotifier.new,
);

// Convenience alias so _DashboardSummaryGrid references work unchanged.
final dashboardStatsDataProvider = dashboardStatsNotifierProvider;
