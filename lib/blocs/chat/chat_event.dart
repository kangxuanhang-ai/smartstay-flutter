class ChatMessageSent {
  final String message;
  const ChatMessageSent(this.message);
}

class ChatSSETextReceived {
  final String text;
  const ChatSSETextReceived(this.text);
}

class ChatSSECardReceived {
  final Map<String, dynamic> card;
  const ChatSSECardReceived(this.card);
}

class ChatSSECompleted {}
