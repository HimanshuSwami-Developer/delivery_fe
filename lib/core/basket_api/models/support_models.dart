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

/// Mirrors `support.serializers.SupportConfigSerializer` — the
/// admin-editable call/WhatsApp contact info shown on the "Help & support"
/// screen. Every field may be blank (not yet configured by an admin), so
/// the UI must treat blank as "hide/disable this option", not crash on it.
class ApiSupportConfig {
  const ApiSupportConfig({
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.whatsappLink,
    required this.replyTimeLabel,
  });

  final String phoneNumber;
  final String whatsappNumber;

  /// `https://wa.me/<number>?text=<message>` — the message is already
  /// baked in and URL-encoded server-side (`SupportConfig.whatsapp_message`).
  final String whatsappLink;
  final String replyTimeLabel;

  factory ApiSupportConfig.fromJson(Map<String, dynamic> json) => ApiSupportConfig(
        phoneNumber: json['phone_number'] as String? ?? '',
        whatsappNumber: json['whatsapp_number'] as String? ?? '',
        whatsappLink: json['whatsapp_link'] as String? ?? '',
        replyTimeLabel: json['reply_time_label'] as String? ?? '',
      );
}

/// Mirrors `support.serializers.SupportFAQSerializer` — one admin-editable
/// Q&A row on the "Help & support" screen.
class ApiSupportFaq {
  const ApiSupportFaq({required this.id, required this.question, required this.answer});

  final int id;
  final String question;
  final String answer;

  factory ApiSupportFaq.fromJson(Map<String, dynamic> json) => ApiSupportFaq(
        id: json['id'] as int,
        question: json['question'] as String,
        answer: json['answer'] as String,
      );
}
