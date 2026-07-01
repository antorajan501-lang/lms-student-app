import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_model.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../repositories/certificate_repository.dart';

class EnrolledCourseCard extends ConsumerWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const EnrolledCourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressValue = ((course.progress ?? 0) / 100).clamp(0.0, 1.0);
    final thumbnailUrl = course.thumbnail ?? course.image;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    course.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.titleLarge?.color ?? AppColors.grey900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  
                  // Progress Bar
                  LinearPercentIndicator(
                    percent: progressValue,
                    lineHeight: 6,
                    backgroundColor: AppColors.grey200,
                    progressColor: AppColors.primary,
                    barRadius: const Radius.circular(3),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress Text and Continue Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        progressValue == 1.0 ? '100% Completed 🎉' : '${(progressValue * 100).toInt()}% Complete',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: progressValue == 1.0 ? AppColors.success : AppColors.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (progressValue == 1.0)
                        ElevatedButton.icon(
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            try {
                              final certRepo = ref.read(certificateRepositoryProvider);
                              final url = await certRepo.getCertificateUrl(course.id);
                              if (context.mounted) Navigator.pop(context); // close loader
                              if (url.isNotEmpty) {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } else {
                                  throw 'Could not open certificate URL.';
                                }
                              } else {
                                throw 'Certificate is not available yet.';
                              }
                            } catch (e) {
                              if (context.mounted) Navigator.pop(context); // close loader
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          },
                          icon: const Icon(Icons.workspace_premium_rounded, size: 14),
                          label: Text(
                            'Certificate',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Text(
                              'Continue',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                          ],
                        )
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
                    child: Divider(height: 1),
                  ),
                  
                  // Bottom Metadata
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(
                        '${course.lessonCount} Lessons',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey500),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.group_outlined, size: 14, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(
                        '${course.totalEnrolled} Students',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey500),
                      ),
                    ],
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

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey100,
      child: const Center(
        child: Icon(Icons.image_rounded, color: AppColors.grey300, size: 48),
      ),
    );
  }
}
