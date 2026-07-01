import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../providers/course_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_widget.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: wishlistAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const EmptyStateWidget(
              title: 'Your wishlist is empty',
              subtitle: 'Save courses you want to take later.',
              icon: Icons.favorite_border_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(wishlistProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.md,
                mainAxisSpacing: AppSizes.md,
                childAspectRatio: 0.68,
              ),
              itemCount: courses.length,
              itemBuilder: (context, i) => CourseCard(
                course: courses[i],
                onTap: () => context.push(
                  '${AppRoutes.courseDetail}?courseId=${courses[i].id}',
                ),
              ),
            ),
          );
        },
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSizes.md,
            mainAxisSpacing: AppSizes.md,
            childAspectRatio: 0.68,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const CourseCardShimmer(),
        ),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(wishlistProvider),
        ),
      ),
    );
  }
}
