/// Single notification from GET /api/usernotify.
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final int? orderId;
  final String? readAt;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.orderId,
    this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null || readAt!.isEmpty;

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      orderId: map['order_id'] is int
          ? map['order_id'] as int
          : (map['order_id'] != null ? int.tryParse(map['order_id'].toString()) : null),
      readAt: map['read_at']?.toString(),
      createdAt: map['created_at']?.toString() ?? '',
    );
  }
}
