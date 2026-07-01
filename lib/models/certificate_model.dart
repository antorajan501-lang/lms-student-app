import 'package:equatable/equatable.dart';

class CertificateModel extends Equatable {
  final int id;
  final int? courseId;
  final String title;
  final String? startDate;
  final String? endDate;
  final String? image;
  final String? createdAt;

  const CertificateModel({
    required this.id,
    this.courseId,
    required this.title,
    this.startDate,
    this.endDate,
    this.image,
    this.createdAt,
  });

  String get courseTitle => title;
  String? get completedAt => createdAt ?? startDate;

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'] as int? ?? 0,
      courseId: json['course_id'] as int?,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      image: json['image'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'image': image,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, courseId, title, startDate, endDate, image, createdAt];
}
