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

class ChatVoiceRecordStarted {
  const ChatVoiceRecordStarted();
}

class ChatVoiceRecordStopped {
  const ChatVoiceRecordStopped();
}

class ChatClearTranscribedText {
  const ChatClearTranscribedText();
}

class ChatClearError {
  const ChatClearError();
}
