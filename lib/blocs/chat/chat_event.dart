class ChatMessageSent {
  final String message;
  final bool newSession;
  const ChatMessageSent(this.message, {this.newSession = false});
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
