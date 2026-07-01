import 'package:equatable/equatable.dart';

class CourseModel extends Equatable {
  final int id;
  final String courseType; // 'Course' or 'Quiz'
  final String title;
  final String? image;
  final String? thumbnail;
  final String instructor;
  final String category;
  final double price;
  final double? discountPrice;
  final int lessonCount;
  final int totalEnrolled;
  final double rating;
  final String? description;
  final String? requirements;
  final String? outcomes;
  final int? progress; // Optional: used for enrolled courses progress percentage
  final bool isDrip;

  const CourseModel({
    required this.id,
    required this.courseType,
    required this.title,
    this.image,
    this.thumbnail,
    required this.instructor,
    required this.category,
    required this.price,
    this.discountPrice,
    required this.lessonCount,
    required this.totalEnrolled,
    required this.rating,
    this.description,
    this.requirements,
    this.outcomes,
    this.progress,
    required this.isDrip,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    // Instructor name parsing
    String instr = '';
    if (json['instructor'] != null) {
      instr = json['instructor'].toString();
    } else if (json['assign_instructor'] is Map) {
      instr = (json['assign_instructor']['name'] ?? '').toString();
    } else if (json['assigned_instructor'] != null) {
      instr = json['assigned_instructor'].toString();
    }

    // Category name parsing
    String cat = '';
    if (json['category'] != null) {
      if (json['category'] is Map) {
        cat = (json['category']['name'] ?? '').toString();
      } else {
        cat = json['category'].toString();
      }
    }

    return CourseModel(
      id: json['id'] as int? ?? json['course_id'] as int? ?? 0,
      courseType: json['course_type'] as String? ?? 'Course',
      title: json['title'] as String? ?? '',
      image: json['image'] as String?,
      thumbnail: json['thumbnail'] as String?,
      instructor: instr,
      category: cat,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      lessonCount: json['lesson'] as int? ?? json['lessons_count'] as int? ?? 0,
      totalEnrolled: json['total_enrolled'] as int? ?? 0,
      rating: (json['reveiw'] as num?)?.toDouble() ?? (json['rating'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? json['about'] as String?,
      requirements: json['requirement'] as String? ?? json['requirements'] as String?,
      outcomes: json['outcome'] as String? ?? json['outcomes'] as String?,
      progress: json['progress'] as int? ?? (json['totalCompletePercentage'] as num?)?.round(),
      isDrip: json['is_drip'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_type': courseType,
      'title': title,
      'image': image,
      'thumbnail': thumbnail,
      'instructor': instructor,
      'category': category,
      'price': price,
      'discount_price': discountPrice,
      'lesson': lessonCount,
      'total_enrolled': totalEnrolled,
      'reveiw': rating,
      'description': description,
      'requirement': requirements,
      'outcome': outcomes,
      'progress': progress,
      'is_drip': isDrip,
    };
  }

  @override
  List<Object?> get props => [
        id,
        courseType,
        title,
        image,
        thumbnail,
        instructor,
        category,
        price,
        discountPrice,
        lessonCount,
        totalEnrolled,
        rating,
        description,
        requirements,
        outcomes,
        progress,
        isDrip,
      ];
}
