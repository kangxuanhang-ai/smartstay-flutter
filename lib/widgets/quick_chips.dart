import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/chat/chat_bloc.dart';
import '../blocs/chat/chat_state.dart';
import '../blocs/room/room_bloc.dart';
import '../blocs/room/room_state.dart';

class QuickChips extends StatefulWidget {
  final ValueChanged<String> onSelected;

  const QuickChips({super.key, required this.onSelected});

  @override
  State<QuickChips> createState() => _QuickChipsState();
}

class _QuickChipsState extends State<QuickChips> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final roomState = context.watch<RoomBloc>().state;
    final chatState = context.watch<ChatBloc>().state;
    final chips = _generateChips(authState, roomState, chatState);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(chips.length, (index) {
          final anim = CurvedAnimation(
            parent: _controller,
            curve: Interval(index * 0.12, 1.0, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(anim),
              child: GestureDetector(
                onTap: () => widget.onSelected(chips[index]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1f2937),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2563eb).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    chips[index],
                    style: const TextStyle(fontSize: 13, color: Color(0xFF93c5fd)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<String> _generateChips(AuthState auth, RoomState room, ChatState chatState) {
    // 1. Not logged in
    if (auth.status != AuthStatus.authenticated) {
      return ['酒店有什么设施？', '怎么预订房间？', '酒店在哪里？'];
    }

    // 2. Logged in but not checked in
    if (room.roomStatus != 'checked_in' && room.roomNumber.isEmpty) {
      return ['查看我的账单', '怎么开发票？', '酒店有什么设施？'];
    }

    // 3. Checked in - dynamic based on time and history
    final hour = DateTime.now().hour;
    final isMorning = hour >= 6 && hour < 12;
    final isEvening = hour >= 18 || hour < 6;

    // Check conversation history for keywords
    final historyText = chatState.messages
        .where((m) => m.isUser)
        .map((m) => m.text)
        .join(' ');
    final hasAC = historyText.contains('空调') || historyText.contains('温度');
    final hasLight = historyText.contains('灯');
    final hasWorkOrder = historyText.contains('工单') || historyText.contains('报修') || historyText.contains('维修');

    final chips = <String>[];

    // History-based priority
    if (hasAC) {
      chips.addAll(['空调调到24度', '空调太冷了']);
    }
    if (hasLight) {
      chips.addAll(['帮我开灯', '帮我关灯']);
    }
    if (hasWorkOrder) {
      chips.add('报修进度怎么样？');
    }

    // Time-based fill
    if (isMorning) {
      chips.addAll(['帮我打扫房间', '附近有什么好吃的？', 'Wi-Fi密码是什么？', '退房时间是几点？']);
    } else if (isEvening) {
      chips.addAll(['空调调到24度', '帮我关窗帘', '帮我开灯', '需要送水']);
    } else {
      chips.addAll(['附近有什么好吃的？', '帮我送两瓶水', '我想延迟退房', '帮我打扫房间']);
    }

    // Deduplicate and take 4
    final unique = <String>[];
    for (final c in chips) {
      if (!unique.contains(c)) unique.add(c);
    }
    return unique.take(4).toList();
  }
}
