import 'package:equatable/equatable.dart';
import 'lesson_model.dart';

class ChapterModel extends Equatable {
  final int id;
  final int courseId;
  final String name;
  final double chapterNo;
  final bool isLock;
  final int position;
  final List<LessonModel>? lessons;

  const ChapterModel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.chapterNo,
    required this.isLock,
    required this.position,
    this.lessons,
  });

  String get title => name;
  int? get lessonsCount => lessons?.length;

  ChapterModel copyWith({
    List<LessonModel>? lessons,
  }) {
    return ChapterModel(
      id: id,
      courseId: courseId,
      name: name,
      chapterNo: chapterNo,
      isLock: isLock,
      position: position,
      lessons: lessons ?? this.lessons,
    );
  }

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['chapter_id'] as int? ?? json['id'] as int? ?? 0,
      courseId: json['course_id'] as int? ?? 0,
      name: json['chapter_name'] as String? ?? json['name'] as String? ?? '',
      chapterNo: (json['chapter_no'] as num?)?.toDouble() ?? 0.0,
      isLock: (json['is_lock'] as int? ?? json['lock'] as int? ?? 0) == 1,
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapter_id': id,
      'course_id': courseId,
      'chapter_name': name,
      'chapter_no': chapterNo,
      'is_lock': isLock ? 1 : 0,
      'position': position,
    };
  }

  @override
  List<Object?> get props => [id, courseId, name, chapterNo, isLock, position, lessons];
}
