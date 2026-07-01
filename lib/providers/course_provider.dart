import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../models/category_model.dart';
import '../repositories/course_repository.dart';

// ── Async Providers ────────────────────────────────────────────────────────────

// All courses (with optional filtering)
final coursesProvider = FutureProvider.family<List<CourseModel>, CourseFilter>((ref, filter) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getCourses(
    page: filter.page,
    categoryId: filter.categoryId,
    search: filter.search,
  );
});

// Course detail
final courseDetailProvider = FutureProvider.family<CourseModel, int>((ref, courseId) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getCourseDetail(courseId);
});

// My enrolled courses
final myCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getMyCourses();
});

// Wishlist
final wishlistProvider = FutureProvider<List<CourseModel>>((ref) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getWishlist();
});

// Categories
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getCategories();
});

// ── Course Search Notifier ────────────────────────────────────────────────────
class CourseSearchNotifier extends StateNotifier<AsyncValue<List<CourseModel>>> {
  final CourseRepository _repo;

  CourseSearchNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final results = await _repo.getCourses(search: query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data([]);
}

final courseSearchProvider =
    StateNotifierProvider<CourseSearchNotifier, AsyncValue<List<CourseModel>>>((ref) {
  final repo = ref.watch(courseRepositoryProvider);
  return CourseSearchNotifier(repo);
});

// ── Wishlist Toggle Notifier ──────────────────────────────────────────────────
class WishlistNotifier extends StateNotifier<Set<int>> {
  final CourseRepository _repo;
  final Ref _ref;

  WishlistNotifier(this._repo, this._ref) : super({});

  Future<void> toggle(int courseId) async {
    try {
      await _repo.toggleWishlist(courseId);
      if (state.contains(courseId)) {
        state = {...state}..remove(courseId);
      } else {
        state = {...state, courseId};
      }
      // Refresh wishlist
      _ref.invalidate(wishlistProvider);
    } catch (_) {
      rethrow;
    }
  }

  bool isInWishlist(int courseId) => state.contains(courseId);
}

final wishlistNotifierProvider =
    StateNotifierProvider<WishlistNotifier, Set<int>>((ref) {
  final repo = ref.watch(courseRepositoryProvider);
  return WishlistNotifier(repo, ref);
});

// ── Filter Model ──────────────────────────────────────────────────────────────
class CourseFilter {
  final int page;
  final int? categoryId;
  final String? search;

  const CourseFilter({this.page = 1, this.categoryId, this.search});

  @override
  bool operator ==(Object other) =>
      other is CourseFilter &&
      other.page == page &&
      other.categoryId == categoryId &&
      other.search == search;

  @override
  int get hashCode => Object.hash(page, categoryId, search);
}
