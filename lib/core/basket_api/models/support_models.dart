/// Mirrors `support.serializers.SupportTicketSerializer`.
class ApiSupportTicket {
  const ApiSupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.adminReply,
    required this.createdAt,
  });

  final int id;
  final String subject;
  final String message;

  /// 'open' | 'resolved'
  final String status;
  final String adminReply;
  final DateTime createdAt;

  factory ApiSupportTicket.fromJson(Map<String, dynamic> json) => ApiSupportTicket(
        id: json['id'] as int,
        subject: json['subject'] as String,
        message: json['message'] as String,
        status: json['status'] as String,
        adminReply: json['admin_reply'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
