import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../models/dashboard_model.dart';
import '../../providers/course_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/dashboard_stats_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/shimmer_loader.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            const SliverToBoxAdapter(child: _DashboardHeader()),

            // Dashboard Summary Grid
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: AppSizes.md),
                child: _DashboardSummaryGrid(),
              ),
            ),

            // Featured Courses
            const _FeaturedCoursesSection(),

            // Recommended Courses
            const _RecommendedCoursesSection(),

            // Continue Learning
            const _ContinueLearningSection(),

            // Recent Activity
            const _RecentActivitySection(),

            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xl)),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningSection extends ConsumerWidget {
  const _ContinueLearningSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return SliverToBoxAdapter(
      child: dashboardAsync.when(
        data: (data) {
          final courses = data.enrolledCourses;
          if (courses.isEmpty) return const SizedBox.shrink();
          return _Section(
            title: 'Continue Learning',
            child: SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
                itemCount: courses.length,
                itemBuilder: (context, i) => _ContinueLearningCard(
                  course: courses[i],
                  onTap: () => context.push(
                    '${AppRoutes.courseDetail}?courseId=${courses[i].courseId}',
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => _Section(
          title: 'Continue Learning',
          child: SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
              itemCount: 3,
              itemBuilder: (_, __) => const SizedBox(
                width: 260,
                child: ShimmerLoader(height: 110),
              ),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _FeaturedCoursesSection extends ConsumerWidget {
  const _FeaturedCoursesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(coursesProvider(const CourseFilter(page: 1)));

    return SliverToBoxAdapter(
      child: _Section(
        title: 'Featured Courses',
        trailing: TextButton(
          onPressed: () => context.push(AppRoutes.search),
          child: Text(
            'See All',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: featuredAsync.when(
          data: (courses) => SizedBox(
            height: 265,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
              itemCount: courses.length > 8 ? 8 : courses.length,
              itemBuilder: (context, i) => SizedBox(
                width: 200,
                child: CourseCard(
                  course: courses[i],
                  onTap: () => context.push(
                    '${AppRoutes.courseDetail}?courseId=${courses[i].id}',
                  ),
                ),
              ),
            ),
          ),
          loading: () => SizedBox(
            height: 265,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
              itemCount: 4,
              itemBuilder: (_, __) => const SizedBox(
                width: 200,
                child: CourseCardShimmer(),
              ),
            ),
          ),
          error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(coursesProvider),
          ),
        ),
      ),
    );
  }
}

class _RecommendedCoursesSection extends ConsumerWidget {
  const _RecommendedCoursesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendedAsync = ref.watch(coursesProvider(const CourseFilter(page: 2)));

    return SliverToBoxAdapter(
      child: _Section(
        title: 'Recommended Courses',
        child: recommendedAsync.when(
          data: (courses) {
            if (courses.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 265,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
                itemCount: courses.length > 8 ? 8 : courses.length,
                itemBuilder: (context, i) => SizedBox(
                  width: 200,
                  child: CourseCard(
                    course: courses[i],
                    onTap: () => context.push(
                      '${AppRoutes.courseDetail}?courseId=${courses[i].id}',
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => SizedBox(
            height: 265,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
              itemCount: 4,
              itemBuilder: (_, __) => const SizedBox(
                width: 200,
                child: CourseCardShimmer(),
              ),
            ),
          ),
          error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(coursesProvider),
          ),
        ),
      ),
    );
  }
}

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: dashboardAsync.when(
        data: (data) {
          final activities = data.recentActivity;
          if (activities.isEmpty) return const SizedBox.shrink();
          return _Section(
            title: 'Recent Activity',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length > 5 ? 5 : activities.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                itemBuilder: (context, i) {
                  final act = activities[i];
                  return Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.grey50,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.grey200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSizes.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act.lessonTitle,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.grey800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                act.courseTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkSubtext : AppColors.grey500,
                                ),
                              ),
                              if (act.completedAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  act.completedAt!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.grey400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
        loading: () => _Section(
          title: 'Recent Activity',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
            child: Column(
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.md),
                  child: ShimmerLoader(height: 60),
                ),
              ),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final authUser = ref.watch(authProvider).user;

    final String name = profileAsync.when(
      data: (user) => user.name,
      loading: () => authUser?.name ?? 'Student',
      error: (_, __) => authUser?.name ?? 'Student',
    );

    return Container(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning! 👋',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: AppSizes.textSm,
                    ),
                  ),
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              NotificationBadge(
                count: 0,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 26),
                  onPressed: () => context.push(AppRoutes.notifications),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          // Search Bar
          GestureDetector(
            onTap: () => context.push(AppRoutes.search),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.grey400, size: AppSizes.iconMd),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Search courses...',
                    style: GoogleFonts.inter(
                      color: AppColors.grey400,
                      fontSize: AppSizes.textMd,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSummaryGrid extends ConsumerWidget {
  const _DashboardSummaryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always resolve to a value — use zeros until the API responds.
    final statsAsync = ref.watch(dashboardStatsDataProvider);
    final stats = statsAsync.valueOrNull ?? DashboardStatsData.zero();
    // NOTE: Do NOT use stats.currencySymbol — always use AppCurrency.format()
    // so the API cannot override the ₹ symbol.

    // ── 4 × 2 responsive grid ─────────────────────────────────────────────
    // On very small phones (< 360 logical px) fall back to 2 cols so cards
    // never become too narrow to read.  On every normal device → 4 cols.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < 360 ? 2 : 4;
        // Keep cards square-ish: narrower cols need a slightly taller ratio.
        final ratio = cols == 4 ? 0.88 : 1.5;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          child: GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: ratio,
            children: [
              _SummaryCard(
                title: 'Balance',
                value: AppCurrency.format(stats.balance),
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF00C853),
              ),
              _SummaryCard(
                title: 'Total Spent',
                value: AppCurrency.format(stats.totalSpent),
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFFFF3D00),
              ),
              _SummaryCard(
                title: 'Certificates',
                value: '${stats.certificates}',
                icon: Icons.workspace_premium_rounded,
                color: const Color(0xFFFFD600),
              ),
              _SummaryCard(
                title: 'In Progress',
                value: '${stats.coursesInProgress}',
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFF00B0FF),
              ),
              _SummaryCard(
                title: 'Purchased',
                value: '${stats.coursesPurchased}',
                icon: Icons.school_rounded,
                color: const Color(0xFFFF6D00),
              ),
              _SummaryCard(
                title: 'Completed',
                value: '${stats.completedCourses}',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF00E676),
              ),
              _SummaryCard(
                title: 'Quizzes',
                value: '${stats.pendingQuizzes}/${stats.totalQuizzes}',
                icon: Icons.quiz_rounded,
                color: const Color(0xFFFFC400),
              ),
              _SummaryCard(
                title: 'Assignments',
                value: '${stats.pendingAssignments}/${stats.totalAssignments}',
                icon: Icons.assignment_rounded,
                color: const Color(0xFFD500F9),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // Compact inner padding so 4 cards fit side-by-side
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.02 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon in a small coloured circle
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          // Value — bold, medium size
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.grey800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Label — small and muted
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : AppColors.grey500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final EnrolledCourseProgress course;
  final VoidCallback onTap;

  const _ContinueLearningCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.courseTitle,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: AppSizes.textSm,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: course.progress / 100,
                      backgroundColor: AppColors.grey200,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  '${course.progress}%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.textLg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        child,
        const SizedBox(height: AppSizes.lg),
      ],
    );
  }
}

