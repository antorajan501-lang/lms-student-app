import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/error_widget.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    // Fetch courses with optional category filter
    final featuredFilter = CourseFilter(page: 1, categoryId: _selectedCategoryId);
    final recommendedFilter = CourseFilter(page: 2, categoryId: _selectedCategoryId);
    final popularFilter = CourseFilter(page: 3, categoryId: _selectedCategoryId);
    final latestFilter = CourseFilter(page: 4, categoryId: _selectedCategoryId);

    final featuredAsync = ref.watch(coursesProvider(featuredFilter));
    final recommendedAsync = ref.watch(coursesProvider(recommendedFilter));
    final popularAsync = ref.watch(coursesProvider(popularFilter));
    final latestAsync = ref.watch(coursesProvider(latestFilter));
    
    // Enrolled courses for "Continue Learning" section
    final myCoursesAsync = ref.watch(myCoursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Explore Courses',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            tooltip: 'Wishlist',
            onPressed: () => context.push(AppRoutes.wishlist),
          ),
          IconButton(
            icon: const Icon(Icons.history_edu_rounded),
            tooltip: 'My Enrolled Courses',
            onPressed: () => context.push(AppRoutes.myCourses),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(myCoursesProvider);
          ref.invalidate(coursesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search Bar Section ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding,
                  vertical: AppSizes.sm,
                ),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.search),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppColors.grey500, size: AppSizes.iconMd),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          'What do you want to learn today?',
                          style: GoogleFonts.inter(
                            color: AppColors.grey500,
                            fontSize: AppSizes.textMd,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Category Chips Section ─────────────────────────────────────
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) return const SizedBox.shrink();
                  return Container(
                    height: 50,
                    margin: const EdgeInsets.only(top: AppSizes.xs, bottom: AppSizes.sm),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                      itemCount: categories.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          final isAllSelected = _selectedCategoryId == null;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('All Topics'),
                              selected: isAllSelected,
                              onSelected: (_) {
                                setState(() => _selectedCategoryId = null);
                              },
                              selectedColor: AppColors.primary,
                              labelStyle: GoogleFonts.inter(
                                color: isAllSelected ? Colors.white : AppColors.grey700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }
                        
                        final cat = categories[i - 1];
                        final isSelected = _selectedCategoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategoryId = cat.id;
                              });
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: GoogleFonts.inter(
                              color: isSelected ? Colors.white : AppColors.grey700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: ShimmerLoader(width: 80, height: 32),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // ── Continue Learning (Only shown if enrolled in progress) ───────
              myCoursesAsync.when(
                data: (enrolledCourses) {
                  final activeCourses = enrolledCourses.where((c) => (c.progress ?? 0) < 100).toList();
                  if (activeCourses.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, AppSizes.md, AppSizes.screenPadding, AppSizes.xs),
                        child: Text(
                          'Continue Learning',
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.textLg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                          separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
                          itemCount: activeCourses.length,
                          itemBuilder: (context, i) {
                            final course = activeCourses[i];
                            return _ContinueLearningCompactCard(
                              course: course,
                              onTap: () => context.push(
                                '${AppRoutes.courseDetail}?courseId=${course.id}',
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // ── Featured Courses ───────────────────────────────────────────
              _HorizontalSection(
                title: 'Featured Courses',
                asyncData: featuredAsync,
                ref: ref,
              ),

              // ── Recommended Courses ────────────────────────────────────────
              _HorizontalSection(
                title: 'Recommended For You',
                asyncData: recommendedAsync,
                ref: ref,
              ),

              // ── Popular Courses ────────────────────────────────────────────
              _HorizontalSection(
                title: 'Popular Courses',
                asyncData: popularAsync,
                ref: ref,
              ),

              // ── Latest Courses ─────────────────────────────────────────────
              _HorizontalSection(
                title: 'Latest Additions',
                asyncData: latestAsync,
                ref: ref,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  final String title;
  final AsyncValue<List<CourseModel>> asyncData;
  final WidgetRef ref;

  const _HorizontalSection({
    required this.title,
    required this.asyncData,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return asyncData.when(
      data: (courses) {
        if (courses.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding,
                vertical: AppSizes.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.textLg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.search),
                    child: Text(
                      'See All',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
                itemCount: courses.length > 6 ? 6 : courses.length,
                itemBuilder: (context, i) {
                  final course = courses[i];
                  return SizedBox(
                    width: 220,
                    child: CourseCard(
                      course: course,
                      onTap: () => context.push(
                        '${AppRoutes.courseDetail}?courseId=${course.id}',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: ShimmerLoader(width: 140, height: 22),
          ),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
              itemCount: 3,
              itemBuilder: (_, __) => const SizedBox(
                width: 220,
                child: CourseCardShimmer(),
              ),
            ),
          ),
        ],
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: AppErrorWidget(
          message: 'Error loading $title',
          onRetry: () => ref.invalidate(coursesProvider),
        ),
      ),
    );
  }
}

class _ContinueLearningCompactCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _ContinueLearningCompactCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progressVal = ((course.progress ?? 0) / 100).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 68,
                height: 68,
                child: (course.thumbnail ?? course.image) != null
                    ? CachedNetworkImage(
                        imageUrl: (course.thumbnail ?? course.image)!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.image, color: AppColors.primary),
                        ),
                      )
                    : Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.image, color: AppColors.primary),
                      ),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progressVal * 100).toInt()}% Complete',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.grey500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progressVal,
                      backgroundColor: AppColors.grey100,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
