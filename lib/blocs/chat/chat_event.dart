class ChatMessageSent {
  final String message;
  final bool newSession;
  final bool webSearch;
  const ChatMessageSent(this.message, {this.newSession = false, this.webSearch = false});
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

class ChatWebSearchToggled {
  const ChatWebSearchToggled();
}

class ChatRegenerate {
  const ChatRegenerate();
}

class ChatErrorDismissed {
  const ChatErrorDismissed();
}

class ChatVoiceRecordingStarted {
  const ChatVoiceRecordingStarted();
}

class ChatVoiceRecordingStopped {
  const ChatVoiceRecordingStopped();
}

class ChatVoiceRecordingCancelled {
  const ChatVoiceRecordingCancelled();
}

class ChatVoiceTranscribeRequested {
  final String audioPath;
  const ChatVoiceTranscribeRequested(this.audioPath);
}
