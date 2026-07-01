import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalEnrolled;
  final int inProgress;
  final int completed;
  final int certificatesEarned;

  const DashboardStats({
    required this.totalEnrolled,
    required this.inProgress,
    required this.completed,
    required this.certificatesEarned,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalEnrolled: json['total_enrolled'] as int? ?? 0,
      inProgress: json['in_progress'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      certificatesEarned: json['certificates_earned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_enrolled': totalEnrolled,
      'in_progress': inProgress,
      'completed': completed,
      'certificates_earned': certificatesEarned,
    };
  }

  @override
  List<Object?> get props => [totalEnrolled, inProgress, completed, certificatesEarned];
}

class DashboardRecentActivity extends Equatable {
  final String lessonTitle;
  final String courseTitle;
  final String? completedAt;

  const DashboardRecentActivity({
    required this.lessonTitle,
    required this.courseTitle,
    this.completedAt,
  });

  factory DashboardRecentActivity.fromJson(Map<String, dynamic> json) {
    return DashboardRecentActivity(
      lessonTitle: json['lesson_title'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      completedAt: json['completed_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lesson_title': lessonTitle,
      'course_title': courseTitle,
      'completed_at': completedAt,
    };
  }

  @override
  List<Object?> get props => [lessonTitle, courseTitle, completedAt];
}

class EnrolledCourseProgress extends Equatable {
  final int enrollmentId;
  final int courseId;
  final String courseTitle;
  final String? courseThumbnail;
  final String courseType;
  final int progress;
  final String? enrolledAt;

  const EnrolledCourseProgress({
    required this.enrollmentId,
    required this.courseId,
    required this.courseTitle,
    this.courseThumbnail,
    required this.courseType,
    required this.progress,
    this.enrolledAt,
  });

  factory EnrolledCourseProgress.fromJson(Map<String, dynamic> json) {
    return EnrolledCourseProgress(
      enrollmentId: json['enrollment_id'] as int? ?? 0,
      courseId: json['course_id'] as int? ?? 0,
      courseTitle: json['course_title'] as String? ?? '',
      courseThumbnail: json['course_thumbnail'] as String?,
      courseType: json['course_type'] as String? ?? 'Course',
      progress: json['progress'] as int? ?? 0,
      enrolledAt: json['enrolled_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enrollment_id': enrollmentId,
      'course_id': courseId,
      'course_title': courseTitle,
      'course_thumbnail': courseThumbnail,
      'course_type': courseType,
      'progress': progress,
      'enrolled_at': enrolledAt,
    };
  }

  @override
  List<Object?> get props => [
        enrollmentId,
        courseId,
        courseTitle,
        courseThumbnail,
        courseType,
        progress,
        enrolledAt,
      ];
}

class DashboardModel extends Equatable {
  final List<EnrolledCourseProgress> enrolledCourses;
  final DashboardStats stats;
  final List<DashboardRecentActivity> recentActivity;

  const DashboardModel({
    required this.enrolledCourses,
    required this.stats,
    required this.recentActivity,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final coursesList = json['enrolled_courses'] as List? ?? [];
    final activityList = json['recent_activity'] as List? ?? [];

    return DashboardModel(
      enrolledCourses: coursesList.map((c) => EnrolledCourseProgress.fromJson(c as Map<String, dynamic>)).toList(),
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      recentActivity: activityList.map((a) => DashboardRecentActivity.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enrolled_courses': enrolledCourses.map((c) => c.toJson()).toList(),
      'stats': stats.toJson(),
      'recent_activity': recentActivity.map((a) => a.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [enrolledCourses, stats, recentActivity];
}
