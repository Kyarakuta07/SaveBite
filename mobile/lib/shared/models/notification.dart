import 'package:equatable/equatable.dart';

/// Notification entity matching backend API response.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    this.type,
    this.title,
    this.message,
    this.data,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String? type;
  final String? title;
  final String? message;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'].toString(),
        type: json['type'] as String?,
        title: json['title'] as String? ??
            (json['data'] is Map ? json['data']['title'] as String? : null),
        message: json['message'] as String? ??
            (json['data'] is Map ? json['data']['message'] as String? : null),
        data: json['data'] as Map<String, dynamic>?,
        readAt: json['read_at'] != null
            ? DateTime.tryParse(json['read_at'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  @override
  List<Object?> get props => [id, type, readAt];
}
