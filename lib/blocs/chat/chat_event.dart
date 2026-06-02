class ChatMessageSent {
  final String message;
  const ChatMessageSent(this.message);
}

class ChatStreamCancelled {
  const ChatStreamCancelled();
}

class ChatSessionsLoadRequested {
  const ChatSessionsLoadRequested();
}

class ChatSessionSwitchRequested {
  final String sessionId;
  const ChatSessionSwitchRequested(this.sessionId);
}

class ChatNewSessionRequested {
  const ChatNewSessionRequested();
}
