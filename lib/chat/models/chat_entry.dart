// lib/chat/models/chat_entry.dart
// Model untuk percakapan dan pesan chat.

class ChatConversation {
  final String id;
  final String otherUsername;
  final String lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.otherUsername,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'].toString(),
      otherUsername: json['other_username'] ?? json['other'] ?? '',
      lastMessage: json['last_message'] ?? json['last'] ?? '',
      lastMessageTime: json['last_message_time'],
      unreadCount: (json['unread_count'] is int)
          ? json['unread_count']
          : int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final int senderId;
  final String senderUsername;
  final String content;
  final String? imageUrl;
  final String createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      senderId: (json['sender_id'] is int)
          ? json['sender_id']
          : int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0,
      senderUsername: json['sender_username'] ?? json['sender'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'] ?? json['image'],
      createdAt: json['created_at'] ?? json['timestamp'] ?? '',
      isRead: json['is_read'] == true ||
          json['is_read']?.toString().toLowerCase() == 'true',
    );
  }
}
