import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:readmore/readmore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../models/course_model.dart';
import '../../models/chapter_model.dart';
import '../../providers/course_provider.dart';
import '../../repositories/course_repository.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/app_button.dart';

class CourseDetailScreen extends ConsumerWidget {
  final int courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailProvider(courseId));
    final chaptersAsync = ref.watch(_chaptersProvider(courseId));

    return Scaffold(
      body: courseAsync.when(
        data: (course) => CustomScrollView(
          slivers: [
            // Expandable app bar with thumbnail
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: (course.thumbnail ?? course.image) != null
                    ? CachedNetworkImage(
                        imageUrl: (course.thumbnail ?? course.image)!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _PlaceholderThumbnail(),
                      )
                    : _PlaceholderThumbnail(),
              ),
            ),

            // Course Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    if (course.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          course.category,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSizes.sm),

                    // Title
                    Text(
                      course.title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),

                    // Instructor
                    if (course.instructor.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 16, color: AppColors.grey500),
                          const SizedBox(width: 4),
                          Text(
                            course.instructor,
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.textSm,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSizes.sm),

                    // Stats row
                    _CourseStats(course: course),
                    const SizedBox(height: AppSizes.lg),

                    // Description
                    if (course.description != null && course.description!.isNotEmpty) ...[
                      Text(
                        'About this course',
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.textLg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      ReadMoreText(
                        course.description!,
                        trimLines: 3,
                        colorClickableText: AppColors.primary,
                        trimMode: TrimMode.Line,
                        trimCollapsedText: 'Show more',
                        trimExpandedText: ' Show less',
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.textMd,
                          color: AppColors.grey600,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                    ],

                    // Requirements
                    if (course.requirements != null && course.requirements!.isNotEmpty) ...[
                      Text(
                        'Requirements',
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.textLg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        course.requirements!,
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.textMd,
                          color: AppColors.grey600,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                    ],

                    // Outcomes
                    if (course.outcomes != null && course.outcomes!.isNotEmpty) ...[
                      Text(
                        'What you\'ll learn',
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.textLg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        course.outcomes!,
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.textMd,
                          color: AppColors.grey600,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                    ],

                    // Course Content Header
                    Text(
                      'Course Content',
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.textLg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${course.lessonCount} lessons',
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.textSm,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                  ],
                ),
              ),
            ),

            // Chapters list
            chaptersAsync.when(
              data: (chapters) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ChapterTile(chapter: chapters[i], courseId: courseId),
                  childCount: chapters.length,
                ),
              ),
              loading: () => SliverToBoxAdapter(
                child: Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPadding,
                        vertical: AppSizes.sm,
                      ),
                      child: ShimmerLoader(height: 60),
                    ),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: AppErrorWidget(message: e.toString()),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(courseDetailProvider(courseId)),
        ),
      ),
      bottomNavigationBar: courseAsync.whenData((course) => _CourseActionBar(course: course)).valueOrNull,
    );
  }
}

final _chaptersProvider = FutureProvider.family<List<ChapterModel>, int>((ref, courseId) async {
  final repo = ref.watch(courseRepositoryProvider);
  final chapters = await repo.getChapters(courseId);
  final chaptersWithLessons = await Future.wait(
    chapters.map((chapter) async {
      try {
        final lessons = await repo.getLessons(chapter.id);
        return chapter.copyWith(lessons: lessons);
      } catch (_) {
        return chapter.copyWith(lessons: []);
      }
    }),
  );
  return chaptersWithLessons;
});

class _PlaceholderThumbnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: const Icon(Icons.play_circle_filled_rounded, size: 64, color: Colors.white),
    );
  }
}

class _CourseStats extends StatelessWidget {
  final CourseModel course;

  const _CourseStats({required this.course});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.md,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (course.rating > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  if (index < course.rating.floor()) {
                    return const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16);
                  } else if (index < course.rating) {
                    return const Icon(Icons.star_half_rounded, color: Color(0xFFFFC107), size: 16);
                  } else {
                    return const Icon(Icons.star_outline_rounded, color: AppColors.grey300, size: 16);
                  }
                }),
              ),
              const SizedBox(width: 4),
              Text(
                course.rating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: AppSizes.textSm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey700,
                ),
              ),
            ],
          ),
        if (course.lessonCount > 0)
          _Stat(
            icon: Icons.play_lesson_rounded,
            color: AppColors.primary,
            label: '${course.lessonCount} lessons',
          ),
        if (course.totalEnrolled > 0)
          _Stat(
            icon: Icons.group_rounded,
            color: AppColors.success,
            label: '${course.totalEnrolled} enrolled',
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _Stat({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppSizes.textSm,
            color: AppColors.grey600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final ChapterModel chapter;
  final int courseId;

  const _ChapterTile({required this.chapter, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        chapter.title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: AppSizes.textMd),
      ),
      subtitle: Text(
        '${chapter.lessonsCount ?? 0} lessons',
        style: GoogleFonts.inter(fontSize: AppSizes.textSm, color: AppColors.grey500),
      ),
      children: (chapter.lessons ?? [])
          .map(
            (lesson) => ListTile(
              leading: Icon(
                lesson.host == 'Document' || lesson.host == 'PDF' 
                  ? Icons.picture_as_pdf_rounded 
                  : (lesson.host == 'Quiz' ? Icons.quiz_rounded : Icons.play_circle_fill_rounded),
                color: lesson.isLock ? AppColors.grey400 : AppColors.primary,
              ),
              title: Text(
                lesson.title,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.textSm,
                  color: lesson.isLock ? AppColors.grey500 : null,
                ),
              ),
              trailing: lesson.isLock 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Locked',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.lock_rounded, size: 14, color: AppColors.grey400),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Play',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.play_arrow_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
              onTap: () {
                // If it's locked, maybe show a toast, but for now we let it pass or block
                if (!lesson.isLock) {
                  context.push(
                    '${AppRoutes.lessonViewer}?courseId=$courseId&lessonId=${lesson.id}',
                  );
                }
              },
            ),
          )
          .toList(),
    );
  }
}

class _CourseActionBar extends ConsumerWidget {
  final CourseModel course;

  const _CourseActionBar({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnrolled = course.progress != null;
    final displayPrice = course.discountPrice != null && course.discountPrice! > 0
        ? course.discountPrice!
        : course.price;
    final isFree = displayPrice == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.md,
        AppSizes.screenPadding,
        AppSizes.xl,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: isEnrolled
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: 'Continue Learning',
                  onPressed: () {
                    // Route to lesson viewer, ideally resuming at last lesson
                    context.push('${AppRoutes.lessonViewer}?courseId=${course.id}');
                  },
                ),
              ],
            )
          : Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFree ? 'Free' : AppCurrency.format(displayPrice),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (!isFree && course.discountPrice != null && course.price > 0)
                      Text(
                        AppCurrency.format(course.price),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.grey400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSizes.lg),
                Expanded(
                  child: AppButton(
                    label: 'Enroll Now',
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                      try {
                        final repo = ref.read(courseRepositoryProvider);
                        final success = await repo.enrollInCourse(course.id);
                        if (context.mounted) Navigator.pop(context); // close loader
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Enrolled successfully!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          ref.invalidate(courseDetailProvider(course.id));
                          ref.invalidate(myCoursesProvider);
                        }
                      } catch (e) {
                        if (context.mounted) Navigator.pop(context); // close loader
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to enroll: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
