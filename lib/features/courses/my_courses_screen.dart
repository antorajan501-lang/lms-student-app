import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../widgets/enrolled_course_card.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_widget.dart';

class MyCoursesScreen extends ConsumerWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myCoursesAsync = ref.watch(myCoursesProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Enrolled Courses'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => context.push(AppRoutes.search),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: myCoursesAsync.when(
          data: (courses) {
            if (courses.isEmpty) {
              return EmptyStateWidget(
                title: 'No courses yet',
                subtitle: 'Enroll in a course to start learning.',
                icon: Icons.school_outlined,
                action: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.search),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Browse Courses'),
                ),
              );
            }
            
            final inProgress = courses.where((c) => (c.progress ?? 0) < 100).toList();
            final completed = courses.where((c) => (c.progress ?? 0) == 100).toList();

            return TabBarView(
              children: [
                _CourseList(courses: courses, ref: ref),
                _CourseList(courses: inProgress, ref: ref),
                _CourseList(courses: completed, ref: ref),
              ],
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            itemCount: 5,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: const CourseCardShimmer(),
            ),
          ),
          error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(myCoursesProvider),
          ),
        ),
      ),
    );
  }
}

class _CourseList extends StatelessWidget {
  final List<CourseModel> courses;
  final WidgetRef ref;

  const _CourseList({required this.courses, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return EmptyStateWidget(
        title: 'No courses',
        subtitle: 'No courses match this filter.',
        icon: Icons.hourglass_empty_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myCoursesProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
        itemBuilder: (context, i) => EnrolledCourseCard(
          course: courses[i],
          onTap: () => context.push(
            '${AppRoutes.courseDetail}?courseId=${courses[i].id}',
          ),
        ),
      ),
    );
  }
}
