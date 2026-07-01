import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../models/course_model.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_currency.dart';
import '../core/constants/app_sizes.dart';

class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool compact;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.showProgress = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: compact
            ? _CompactCard(course: course, showProgress: showProgress)
            : _FullCard(course: course, showProgress: showProgress),
      ),
    );
  }
}

class _FullCard extends StatelessWidget {
  final CourseModel course;
  final bool showProgress;

  const _FullCard({required this.course, required this.showProgress});

  @override
  Widget build(BuildContext context) {
    final progressValue = ((course.progress ?? 0) / 100).clamp(0.0, 1.0);
    final thumbnailUrl = course.thumbnail ?? course.image;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.cardRadius)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const _ThumbnailPlaceholder(),
                    errorWidget: (_, __, ___) => const _ThumbnailPlaceholder(),
                  )
                : const _ThumbnailPlaceholder(),
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category chip
                if (course.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Text(
                      course.category,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSizes.xs),
                // Title
                Text(
                  course.title,
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.textMd,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.xs),
                // Instructor
                if (course.instructor.isNotEmpty)
                  Text(
                    course.instructor,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.textSm,
                      color: AppColors.grey500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: AppSizes.sm),
                // Progress or price/rating
                if (showProgress) ...[
                  LinearPercentIndicator(
                    percent: progressValue,
                    lineHeight: 6,
                    backgroundColor: AppColors.grey200,
                    progressColor: AppColors.primary,
                    barRadius: const Radius.circular(3),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progressValue * 100).toInt()}% complete',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey500),
                  ),
                ] else ...[
                  Row(
                    children: [
                      if (course.rating > 0) ...[
                        const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          course.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.textSm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                      ],
                       Text(
                         AppCurrency.priceOrFree(course.price),
                         style: GoogleFonts.inter(
                           fontSize: AppSizes.textMd,
                           fontWeight: FontWeight.w700,
                           color: course.price > 0 ? AppColors.primary : AppColors.success,
                         ),
                       ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactCard extends StatelessWidget {
  final CourseModel course;
  final bool showProgress;

  const _CompactCard({required this.course, required this.showProgress});

  @override
  Widget build(BuildContext context) {
    final progressValue = ((course.progress ?? 0) / 100).clamp(0.0, 1.0);
    final thumbnailUrl = course.thumbnail ?? course.image;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: SizedBox(
              width: 72,
              height: 72,
              child: thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const _ThumbnailPlaceholder(),
                    )
                  : const _ThumbnailPlaceholder(),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.textSm,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (course.instructor.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    course.instructor,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey500),
                  ),
                ],
                if (showProgress) ...[
                  const SizedBox(height: AppSizes.xs),
                  LinearPercentIndicator(
                    percent: progressValue,
                    lineHeight: 4,
                    backgroundColor: AppColors.grey200,
                    progressColor: AppColors.primary,
                    barRadius: const Radius.circular(2),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(progressValue * 100).toInt()}%',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.play_circle_rounded, color: AppColors.primary, size: 32),
      ),
    );
  }
}
