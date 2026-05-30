import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../widgets/auth_prompt.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final _textCtrl = TextEditingController();

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final bloc = context.read<ChatBloc>();
    if (bloc.state.isStreaming) return;
    bloc.add(ChatMessageSent(text));
    _textCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthBloc>().state.status == AuthStatus.authenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('🤖 AI虚拟管家'), backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
      body: isLoggedIn ? _buildChatBody() : const AuthPrompt.overlay(
        icon: '🤖',
        title: 'AI 虚拟管家',
        description: '登录后即可享受智能对话\n控制设备 · 查询信息 · 提交服务',
      ),
    );
  }

  Widget _buildChatBody() {
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: state.messages.length,
                itemBuilder: (context, idx) {
                  final msg = state.messages[idx];
                  final isUser = msg.isUser;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF1677FF) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.text.isNotEmpty)
                            Text(msg.text, style: TextStyle(color: isUser ? Colors.white : const Color(0xFF262626))),
                          ...msg.cards.map((card) => Card(
                            margin: const EdgeInsets.only(top: 8),
                            color: card['type'] == 'error' ? const Color(0xFFFFF1F0) : const Color(0xFFF6FFED),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(children: [
                                Text(card['type'] == 'error' ? '❌' : '✅', style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(card['title'] ?? '', style: const TextStyle(fontSize: 13))),
                              ]),
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF0F0F0)))),
          child: Row(children: [
            Expanded(child: TextField(controller: _textCtrl, decoration: const InputDecoration(hintText: '输入需求...', border: InputBorder.none))),
            IconButton(onPressed: _send, icon: const Icon(Icons.send, color: Color(0xFF1677FF))),
          ]),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }
}
