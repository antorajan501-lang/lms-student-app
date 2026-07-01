import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../providers/course_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/course_card.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    ref.read(courseSearchProvider.notifier).search(query);
  }

  void _clear() {
    _searchCtrl.clear();
    ref.read(courseSearchProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(courseSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 42,
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Search courses...',
              hintStyle: GoogleFonts.inter(color: AppColors.grey400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                borderSide: const BorderSide(color: AppColors.grey300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: _clear,
                    )
                  : null,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: searchState.when(
        data: (courses) {
          if (courses.isEmpty && _searchCtrl.text.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_rounded, size: 64, color: AppColors.grey300),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Search for courses',
                    style: GoogleFonts.inter(color: AppColors.grey400, fontSize: AppSizes.textLg),
                  ),
                ],
              ),
            );
          }
          if (courses.isEmpty) {
            return EmptyStateWidget(
              title: 'No results found',
              subtitle: 'Try different keywords.',
              icon: Icons.search_off_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
            itemBuilder: (context, i) => CourseCard(
              course: courses[i],
              onTap: () => context.push(
                '${AppRoutes.courseDetail}?courseId=${courses[i].id}',
              ),
            ),
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
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}
