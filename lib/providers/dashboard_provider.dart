import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../repositories/dashboard_repository.dart';

final dashboardProvider = FutureProvider<DashboardModel>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getDashboard();
});

final courseProgressProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, courseId) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getCourseProgress(courseId);
});
