import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/room/room_bloc.dart';
import '../blocs/room/room_state.dart';

class QuickChips extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const QuickChips({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final roomState = context.watch<RoomBloc>().state;
    final chips = _getChips(authState, roomState);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips.map((text) {
          return GestureDetector(
            onTap: () => onSelected(text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1f2937),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2563eb).withValues(alpha: 0.4)),
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, color: Color(0xFF93c5fd)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<String> _getChips(AuthState auth, RoomState room) {
    if (auth.status != AuthStatus.authenticated) {
      return ['酒店有什么设施？', '怎么预订房间？', '酒店在哪里？'];
    }
    if (room.roomStatus == 'checked_in' || room.roomNumber.isNotEmpty) {
      return ['空调太冷了', '帮我打扫房间', '附近有什么好吃的？', '我想延迟退房'];
    }
    return ['查看我的账单', '怎么开发票？', '酒店有什么设施？'];
  }
}
