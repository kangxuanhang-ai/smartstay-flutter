import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../widgets/auth_prompt.dart';
import '../../widgets/chat_card.dart';
import '../../widgets/error_card.dart';
import '../../widgets/quick_chips.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/voice_wave_animation.dart';
import '../../core/voice_service.dart';
import 'session_list_page.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> with TickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _quickChipsExpanded = true;
  bool _showCommandMenu = false;

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final bloc = context.read<ChatBloc>();
    if (bloc.state.isStreaming) return;
    bloc.add(ChatMessageSent(text, webSearch: bloc.state.webSearchEnabled));
    _textCtrl.clear();
    setState(() => _showCommandMenu = false);
  }

  bool _isScrolling = false;

  void _scrollToBottom() {
    if (_isScrolling) return;
    _isScrolling = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ).whenComplete(() => _isScrolling = false);
      } else {
        _isScrolling = false;
      }
    });
  }

  // ── Colors ──
  static const _bg = Color(0xFF0a0a1e);
  static const _bgTop = Color(0xFF111128);
  static const _card = Color(0xFF1f2937);
  static const _bubbleBot = Color(0xFF1a1a3a);
  static const _blue = Color(0xFF2563eb);
  static const _muted = Color(0xFF9ca3af);
  static const _errorRed = Color(0xFFef4444);

  // ── Voice Helpers ──
  bool _voiceStarted = false;

  Future<void> _startVoice(BuildContext context) async {
    final voiceService = VoiceService.instance;
    final started = await voiceService.startRecording();
    if (!started || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('请在系统设置中允许麦克风权限'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }
    _voiceStarted = true;
    context.read<ChatBloc>().add(const ChatVoiceRecordingStarted());

    // Forward duration updates to BLoC
    voiceService.durationStream.listen((duration) {
      if (mounted) {
        context.read<ChatBloc>().add(const ChatVoiceRecordingStarted());
      }
    });
  }

  Future<void> _stopVoice(BuildContext context) async {
    if (!_voiceStarted) return;
    _voiceStarted = false;

    final voiceService = VoiceService.instance;
    final bloc = context.read<ChatBloc>();

    bloc.add(const ChatVoiceRecordingStopped());
    final audioPath = await voiceService.stopRecording();

    if (audioPath == null) {
      bloc.add(const ChatVoiceRecordingCancelled());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('录音时间太短'),
            backgroundColor: const Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    bloc.add(ChatVoiceTranscribeRequested(audioPath));
  }

  // ── Slash Commands ──
  static const _commands = [
    _SlashCommand('送水', '帮我送两瓶矿泉水到房间', Icons.water_drop, '服务'),
    _SlashCommand('打扫', '帮我打扫房间', Icons.cleaning_services, '服务'),
    _SlashCommand('送物', '请帮我送物品到房间', Icons.inventory_2, '服务'),
    _SlashCommand('维修', '房间设备需要维修', Icons.build, '服务'),
    _SlashCommand('空调', '帮我调节空调温度', Icons.thermostat, '设备'),
    _SlashCommand('灯光', '帮我控制灯光', Icons.lightbulb, '设备'),
    _SlashCommand('窗帘', '帮我控制窗帘', Icons.curtains, '设备'),
    _SlashCommand('退房', '我想办理退房', Icons.logout, '流程'),
    _SlashCommand('延迟', '我想延迟退房', Icons.schedule, '流程'),
    _SlashCommand('账单', '查看我的账单', Icons.receipt_long, '查询'),
    _SlashCommand('发票', '我想开发票', Icons.receipt, '查询'),
    _SlashCommand('叫车', '帮我叫一辆车', Icons.local_taxi, '出行'),
    _SlashCommand('导航', '我想去某个地方', Icons.map, '出行'),
    _SlashCommand('Wi-Fi', 'Wi-Fi密码是什么', Icons.wifi, '信息'),
    _SlashCommand('投诉', '我要投诉', Icons.report, '反馈'),
  ];

  List<_SlashCommand> _filterCommands(String query) {
    if (query.isEmpty || query == '/') return _commands;
    final q = query.substring(1); // remove leading /
    if (q.isEmpty) return _commands;
    return _commands.where((c) => c.name.contains(q)).toList();
  }

  void _onTextChanged(String text) {
    final show = text.startsWith('/');
    if (show != _showCommandMenu) {
      setState(() => _showCommandMenu = show);
    }
  }

  void _selectCommand(_SlashCommand cmd) {
    _textCtrl.text = cmd.mappedText;
    _textCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _textCtrl.text.length),
    );
    setState(() => _showCommandMenu = false);
  }

  // ── Long Press Menu ──
  void _showMessageMenu(BuildContext context, ChatMessage msg, bool isLastAi, Offset position) {
    if (state(context).isStreaming) return;
    if (msg.isThinking) return;

    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'copy',
        child: Row(
          children: [
            Icon(Icons.content_copy, size: 18, color: Color(0xFF9CA3AF)),
            SizedBox(width: 10),
            Text('复制全文', style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    ];

    if (!msg.isUser && isLastAi) {
      items.add(const PopupMenuItem(
        value: 'regenerate',
        child: Row(
          children: [
            Icon(Icons.refresh, size: 18, color: Color(0xFF9CA3AF)),
            SizedBox(width: 10),
            Text('重新生成', style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ));
    }

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 100, position.dy + 100),
      items: items,
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ).then((value) {
      if (!mounted) return;
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: msg.text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已复制到剪贴板'),
            backgroundColor: const Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (value == 'regenerate') {
        context.read<ChatBloc>().add(const ChatRegenerate());
      }
    });
  }

  ChatState state(BuildContext context) => context.read<ChatBloc>().state;

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
          colors: [_bgTop, _bg],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessages()),
          _buildErrorArea(),
          _buildQuickChips(),
          _buildWebSearchToggle(),
          _buildCommandMenu(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return SafeArea(
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
              onTap: () => context.push('/ai-chat/preferences'),
              child: const Icon(Icons.settings_outlined, color: Color(0xFF9ca3af), size: 22),
            ),
            const SizedBox(width: 12),
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
    );
  }

  // ── Messages ──
  Widget _buildMessages() {
    return BlocBuilder<ChatBloc, ChatState>(
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
            final isLastAi = !isUser && (idx == state.messages.length - 1 ||
                state.messages.sublist(idx + 1).every((m) => m.isUser));

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
                    child: GestureDetector(
                      onLongPressStart: (details) {
                        _showMessageMenu(context, msg, isLastAi, details.globalPosition);
                      },
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
                                    if (href != null) launchUrl(Uri.parse(href));
                                  },
                                ),
                              ...msg.cards.map((card) {
                                final isLastMsg = idx == state.messages.length - 1;
                                return ChatCardWidget(
                                  card: card,
                                  isStreaming: state.isStreaming && isLastMsg,
                                );
                              }),
                              // Timestamp
                              if (!msg.isThinking && !isUser)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF4B5563)),
                                  ),
                                ),
                            ],
                          ),
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
    );
  }

  // ── Error Area ──
  Widget _buildErrorArea() {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (prev, curr) => prev.chatError != curr.chatError,
      builder: (context, state) {
        if (state.chatError == null) return const SizedBox.shrink();
        final error = state.chatError!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ErrorCardWidget(
            type: error.type,
            title: error.title,
            message: error.message,
            actionLabel: error.actionLabel,
            onAction: () {
              context.read<ChatBloc>().add(const ChatErrorDismissed());
              if (error.type == 'auth') {
                context.go('/login');
              } else if (error.type == 'forbidden') {
                context.go('/home');
              } else {
                final msgs = context.read<ChatBloc>().state.messages;
                final lastUserMsg = msgs.lastWhere((m) => m.isUser, orElse: () => ChatMessage(id: '', isUser: true, text: ''));
                if (lastUserMsg.text.isNotEmpty) {
                  context.read<ChatBloc>().add(ChatMessageSent(lastUserMsg.text));
                }
              }
            },
            secondaryLabel: error.secondaryLabel,
            onSecondary: error.secondaryLabel != null ? () {
              context.read<ChatBloc>().add(const ChatErrorDismissed());
            } : null,
            onDismiss: () => context.read<ChatBloc>().add(const ChatErrorDismissed()),
          ),
        );
      },
    );
  }

  // ── Quick Chips ──
  Widget _buildQuickChips() {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (prev, curr) => prev.messages.length != curr.messages.length,
      builder: (context, state) {
        final hasMessages = state.messages.isNotEmpty;
        if (hasMessages && !_quickChipsExpanded) {
          return GestureDetector(
            onTap: () => setState(() => _quickChipsExpanded = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: _blue.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Text('快捷提问', style: TextStyle(fontSize: 12, color: _blue.withOpacity(0.6))),
                  Icon(Icons.expand_more, size: 16, color: _blue.withOpacity(0.6)),
                ],
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMessages)
              GestureDetector(
                onTap: () => setState(() => _quickChipsExpanded = false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14, color: _blue.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Text('快捷提问', style: TextStyle(fontSize: 12, color: _blue.withOpacity(0.6))),
                      Icon(Icons.expand_less, size: 16, color: _blue.withOpacity(0.6)),
                    ],
                  ),
                ),
              ),
            QuickChips(
              onSelected: (text) {
                context.read<ChatBloc>().add(ChatMessageSent(text));
              },
            ),
          ],
        );
      },
    );
  }

  // ── Web Search Toggle ──
  Widget _buildWebSearchToggle() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: GestureDetector(
            onTap: () => context.read<ChatBloc>().add(const ChatWebSearchToggled()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: state.webSearchEnabled
                    ? const Color(0xFF2563eb).withOpacity(0.15)
                    : _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.webSearchEnabled ? _blue : const Color(0xFF374151),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 16,
                    color: state.webSearchEnabled ? const Color(0xFF60a5fa) : _muted),
                  const SizedBox(width: 6),
                  Text('联网搜索', style: TextStyle(fontSize: 13,
                    color: state.webSearchEnabled ? const Color(0xFF60a5fa) : _muted)),
                  const SizedBox(width: 6),
                  Icon(
                    state.webSearchEnabled ? Icons.toggle_on : Icons.toggle_off,
                    size: 20,
                    color: state.webSearchEnabled ? _blue : const Color(0xFF6b7280),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Command Menu ──
  Widget _buildCommandMenu() {
    if (!_showCommandMenu) return const SizedBox.shrink();

    final query = _textCtrl.text;
    final filtered = _filterCommands(query);

    // Group by category
    final grouped = <String, List<_SlashCommand>>{};
    for (final cmd in filtered) {
      grouped.putIfAbsent(cmd.category, () => []).add(cmd);
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F23).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A1A2E)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: filtered.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('没有找到命令', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13))),
              )
            : ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: grouped.entries.expand((entry) {
                  return [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(entry.key, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.value.map((cmd) {
                          return Material(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => _selectCommand(cmd),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(cmd.icon, size: 16, color: const Color(0xFF60a5fa)),
                                    const SizedBox(width: 6),
                                    Text(cmd.name, style: const TextStyle(fontSize: 13, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ];
                }).toList(),
              ),
      ),
    );
  }

  // ── Input Bar ──
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: _bgTop,
        border: Border(top: BorderSide(color: _card)),
      ),
      child: Row(
        children: [
          // Mic button
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (prev, curr) =>
                prev.isRecording != curr.isRecording ||
                prev.isTranscribing != curr.isTranscribing ||
                prev.recordingDuration != curr.recordingDuration,
            builder: (context, state) {
              if (state.isTranscribing) {
                return Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: _card, shape: BoxShape.circle),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60a5fa)),
                  ),
                );
              }
              if (state.isRecording) {
                return GestureDetector(
                  onLongPressEnd: (_) => _stopVoice(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VoiceWaveAnimation(isActive: true),
                      const SizedBox(width: 4),
                      Text(
                        '${state.recordingDuration}s',
                        style: const TextStyle(fontSize: 12, color: _errorRed, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }
              return GestureDetector(
                onLongPressStart: (_) => _startVoice(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: _card, shape: BoxShape.circle),
                  child: const Icon(Icons.mic_none, color: _muted, size: 20),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _textCtrl,
                onSubmitted: (_) => _send(),
                onChanged: _onTextChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _showCommandMenu ? '输入命令...' : '输入您的需求...',
                  hintStyle: const TextStyle(color: _muted),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send / Stop button
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (prev, curr) => prev.isStreaming != curr.isStreaming,
            builder: (context, state) {
              if (state.isStreaming) {
                return GestureDetector(
                  onTap: () => context.read<ChatBloc>().add(const ChatStreamCancelled()),
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: _errorRed, shape: BoxShape.circle),
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
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

class _SlashCommand {
  final String name;
  final String mappedText;
  final IconData icon;
  final String category;

  const _SlashCommand(this.name, this.mappedText, this.icon, this.category);
}
