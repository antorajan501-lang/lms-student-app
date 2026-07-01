import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final int id;
  final String name;
  final bool status;
  final int position;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.status,
    required this.position,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as bool? ?? true,
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'position': position,
    };
  }

  @override
  List<Object?> get props => [id, name, status, position];
}
