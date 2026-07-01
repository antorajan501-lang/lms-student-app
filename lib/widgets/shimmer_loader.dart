import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

class ShimmerLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppSizes.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkBorder : AppColors.grey200,
      highlightColor: isDark ? AppColors.darkCard : AppColors.grey50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.grey200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Course Card Shimmer ───────────────────────────────────────────────────────
class CourseCardShimmer extends StatelessWidget {
  const CourseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail — use AspectRatio so it scales with the card width
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.cardRadius),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ShimmerLoader(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
              ),
            ),
          ),
          // Text content — Flexible prevents overflow in fixed-height grid cells
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerLoader(width: 72, height: 14),
                  const SizedBox(height: AppSizes.xs),
                  ShimmerLoader(width: double.infinity, height: 13),
                  const SizedBox(height: 3),
                  ShimmerLoader(width: 130, height: 13),
                  const SizedBox(height: AppSizes.xs),
                  ShimmerLoader(width: 90, height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── List Tile Shimmer ─────────────────────────────────────────────────────────
class ListTileShimmer extends StatelessWidget {
  const ListTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          ShimmerLoader(width: 56, height: 56, borderRadius: AppSizes.radiusMd),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                ShimmerLoader(width: 140, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
