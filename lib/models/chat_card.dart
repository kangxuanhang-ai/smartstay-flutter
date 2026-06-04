enum ChatCardType { success, error, deviceControl, workOrder, pricing, info }

class ChatCard {
  final ChatCardType type;
  final String title;
  final String? subtitle;
  final Map<String, dynamic>? metadata;

  const ChatCard({
    required this.type,
    required this.title,
    this.subtitle,
    this.metadata,
  });

  factory ChatCard.fromJson(Map<String, dynamic> json) {
    return ChatCard(
      type: ChatCardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatCardType.info,
      ),
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      metadata: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (metadata != null) ...metadata!,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatCard && type == other.type && title == other.title;

  @override
  int get hashCode => type.hashCode ^ title.hashCode;
}
