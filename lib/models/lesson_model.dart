import 'package:equatable/equatable.dart';

class LessonModel extends Equatable {
  final int id;
  final int courseId;
  final int chapterId;
  final String name;
  final int duration; // in minutes
  final String host; // 'Youtube', 'Vimeo', 'Self', etc.
  final String? url;
  final bool isLock;
  final String? description;

  const LessonModel({
    required this.id,
    required this.courseId,
    required this.chapterId,
    required this.name,
    required this.duration,
    required this.host,
    this.url,
    required this.isLock,
    this.description,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['lesson_id'] as int? ?? json['id'] as int? ?? 0,
      courseId: json['course_id'] as int? ?? 0,
      chapterId: json['chapter_id'] as int? ?? 0,
      name: json['lesson_name'] as String? ?? json['name'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      host: json['host'] as String? ?? '',
      url: json['url'] as String? ?? json['video_url'] as String?,
      isLock: (json['privacy'] as int? ?? json['is_lock'] as int? ?? 0) == 1,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lesson_id': id,
      'course_id': courseId,
      'chapter_id': chapterId,
      'lesson_name': name,
      'duration': duration,
      'host': host,
      'url': url,
      'privacy': isLock ? 1 : 0,
      'description': description,
    };
  }

  String get title => name;
  String? get videoUrl => url;

  @override
  List<Object?> get props => [
        id,
        courseId,
        chapterId,
        name,
        duration,
        host,
        url,
        isLock,
        description,
      ];
}
