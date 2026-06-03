import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../widgets/auth_prompt.dart';
import '../../widgets/chat_card.dart';
import '../../widgets/quick_chips.dart';
import '../../widgets/typing_indicator.dart';
import 'session_list_page.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final bloc = context.read<ChatBloc>();
    if (bloc.state.isStreaming) return;
    bloc.add(ChatMessageSent(text));
    _textCtrl.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ── Colors ──
  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1f2937);
  static const _bubbleBot = Color(0xFF1a1a3a);
  static const _blue = Color(0xFF2563eb);
  static const _muted = Color(0xFF9ca3af);

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthBloc>().state.status == AuthStatus.authenticated;

    return Scaffold(
      backgroundColor: _bg,
      body: isLoggedIn ? _buildBody() : const AuthPrompt.overlay(
        icon: '🤖', title: 'AI 虚拟管家',
        description: '登录后即可享受智能对话\n控制设备 · 查询信息 · 提交服务'),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF111128), Color(0xFF0a0a1e)],
        ),
      ),
      child: Column(
        children: [
          // ── Header ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(color: _card, shape: BoxShape.circle),
                          child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF60a5fa), size: 18),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('AI 智能管家', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                            Text('在线中', style: TextStyle(fontSize: 11, color: Color(0xFF4ade80))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<ChatBloc>().add(const ChatSessionsLoadRequested());
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BlocProvider.value(
                          value: context.read<ChatBloc>(),
                          child: const SessionListPage(),
                        ),
                      );
                    },
                    child: const Icon(Icons.history_rounded, color: Color(0xFF9ca3af), size: 22),
                  ),
                ],
              ),
            ),
          ),
          // ── Chat Messages ──
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: const BoxDecoration(color: _card, shape: BoxShape.circle),
                          child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF60a5fa), size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text('有什么可以帮您的吗？', style: TextStyle(fontSize: 15, color: _muted)),
                      ],
                    ),
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.messages.length,
                  itemBuilder: (context, idx) {
                    final msg = state.messages[idx];
                    final isUser = msg.isUser;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            Container(
                              width: 32, height: 32,
                              decoration: const BoxDecoration(color: _card, shape: BoxShape.circle),
                              child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF60a5fa), size: 18),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser ? _blue : _bubbleBot,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (msg.isThinking)
                                    const TypingIndicator()
                                  else if (msg.text.isNotEmpty && isUser)
                                    Text(msg.text, style: const TextStyle(fontSize: 14, color: Colors.white))
                                  else if (msg.text.isNotEmpty && !isUser)
                                    MarkdownBody(
                                      data: msg.text,
                                      styleSheet: MarkdownStyleSheet(
                                        p: const TextStyle(fontSize: 14, color: Color(0xFFc0c0e0), height: 1.5),
                                        strong: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                        em: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFFc0c0e0)),
                                        code: TextStyle(
                                          fontSize: 13,
                                          color: const Color(0xFF60a5fa),
                                          backgroundColor: _card,
                                          fontFamily: 'monospace',
                                        ),
                                        codeblockDecoration: BoxDecoration(
                                          color: _card,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        blockquote: const TextStyle(color: Color(0xFF9ca3af)),
                                        listBullet: const TextStyle(color: Color(0xFF60a5fa)),
                                        a: const TextStyle(color: Color(0xFF60a5fa), decoration: TextDecoration.underline),
                                        h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                                        h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                                        h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                      onTapLink: (text, href, title) {
                                        if (href != null) {
                                          launchUrl(Uri.parse(href));
                                        }
                                      },
                                    ),
                                  ...msg.cards.map((card) => BlocBuilder<ChatBloc, ChatState>(
                                    buildWhen: (prev, curr) => prev.isStreaming != curr.isStreaming,
                                    builder: (context, state) {
                                      final isLastMsg = msg == state.messages.last;
                                      return ChatCardWidget(
                                        card: card,
                                        isStreaming: state.isStreaming && isLastMsg,
                                      );
                                    },
                                  )),
                                ],
                              ),
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _blue, width: 2),
                                color: _card,
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 16),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // ── Quick Chips (only when no messages) ──
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (prev, curr) => prev.messages.length != curr.messages.length,
            builder: (context, state) {
              if (state.messages.isEmpty) {
                return QuickChips(
                  onSelected: (text) {
                    context.read<ChatBloc>().add(ChatMessageSent(text));
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // ── Input Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF111128),
              border: Border(top: BorderSide(color: _card)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _card, borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _textCtrl,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '输入您的需求...',
                        hintStyle: TextStyle(color: _muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: _card, shape: BoxShape.circle),
                  child: const Icon(Icons.mic, color: _muted, size: 20),
                ),
                const SizedBox(width: 8),
                BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (prev, curr) => prev.isStreaming != curr.isStreaming,
                  builder: (context, state) {
                    if (state.isStreaming) {
                      return GestureDetector(
                        onTap: () => context.read<ChatBloc>().add(const ChatStreamCancelled()),
                        child: Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(color: Color(0xFFef4444), shape: BoxShape.circle),
                          child: const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}
