import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';

class SessionListPage extends StatelessWidget {
  const SessionListPage({super.key});

  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1f2937);
  static const _blue = Color(0xFF2563eb);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('聊天记录', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<ChatBloc>().add(const ChatNewSessionRequested());
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add, color: _blue, size: 18),
            label: const Text('新会话', style: TextStyle(color: _blue, fontSize: 13)),
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (prev, curr) => prev.sessions != curr.sessions,
        builder: (context, state) {
          if (state.sessions.isEmpty) {
            return const Center(
              child: Text('暂无聊天记录', style: TextStyle(color: Color(0xFF9ca3af), fontSize: 14)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final session = state.sessions[idx];
              final isActive = session['id'] == state.currentSessionId;
              return GestureDetector(
                onTap: () {
                  context.read<ChatBloc>().add(
                    ChatSessionSwitchRequested(session['id'] as String),
                  );
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isActive ? _blue.withValues(alpha: 0.15) : _card,
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(color: _blue.withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session['first_message'] as String? ?? '新对话',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session['created_at'] as String? ?? '',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6b7280)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
