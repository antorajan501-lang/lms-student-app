import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final title = data['title'] as String? ?? data['message'] as String? ?? 'Notification';
    final message = data['body'] as String? ?? data['text'] as String? ?? data['message'] as String? ?? '';

    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: title,
      message: message,
      isRead: json['read_at'] != null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': {
        'title': title,
        'message': message,
      },
      'read_at': isRead ? DateTime.now().toIso8601String() : null,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, title, message, isRead, createdAt];
}
