import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/room/room_bloc.dart';
import '../../blocs/room/room_event.dart';
import '../../blocs/room/room_state.dart';
import '../../widgets/auth_prompt.dart';

class RoomControlPage extends StatefulWidget {
  const RoomControlPage({super.key});

  @override
  State<RoomControlPage> createState() => _RoomControlPageState();
}

class _RoomControlPageState extends State<RoomControlPage> {
  @override
  void initState() {
    super.initState();
    context.read<RoomBloc>().add(RoomFetched());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) {
        final isLoggedIn = context.watch<AuthBloc>().state.status == AuthStatus.authenticated;
        final loading = state.loading && state.roomNumber.isEmpty;
        final noRoom = !loading && state.error != null && state.roomNumber.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text('💡 智能控房${state.roomNumber.isNotEmpty ? ' · ${state.roomNumber}' : ''}'),
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
          ),
          body: loading
            ? const Center(child: CircularProgressIndicator())
            : !isLoggedIn
              ? _buildUnauthView()
              : noRoom
                ? _buildEmptyState(context, state.error!)
                : _buildAuthView(context, state),
        );
      },
    );
  }

  Widget _buildUnauthView() {
    return Stack(children: [
      Opacity(opacity: 0.25, child: IgnorePointer(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LightSwitch(label: '客厅灯', value: false, onToggle: () {}),
          _LightSwitch(label: '卧室灯', value: false, onToggle: () {}),
          _LightSwitch(label: '床头灯', value: false, onToggle: () {}),
          const SizedBox(height: 16),
          const Text('🪟 窗帘控制 · 50%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Slider(value: 50, min: 0, max: 100, onChanged: null),
          const SizedBox(height: 16),
          const Text('🌡️ 空调控制 · 24°C', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _TempButton(icon: Icons.remove, onTap: () {}),
            Container(width: 80, alignment: Alignment.center, child: const Text('24°C', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1677FF)))),
            _TempButton(icon: Icons.add, onTap: () {}),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ChoiceChip(label: const Text('❄️ 制冷'), selected: true, onSelected: null),
            const SizedBox(width: 12),
            ChoiceChip(label: const Text('🔥 制热'), selected: false, onSelected: null),
          ]),
        ],
      ))),
      const AuthPrompt.bottomBar(
        icon: '💡',
        title: '控房',
        description: '入住后即可控制房间设备',
      ),
    ]);
  }

  Widget _buildAuthView(BuildContext context, RoomState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _LightSwitch(label: '客厅灯', value: state.livingLight, onToggle: () => context.read<RoomBloc>().add(const LightToggled('living_light'))),
        _LightSwitch(label: '卧室灯', value: state.bedroomLight, onToggle: () => context.read<RoomBloc>().add(const LightToggled('bedroom_light'))),
        _LightSwitch(label: '床头灯', value: state.bedsideLight, onToggle: () => context.read<RoomBloc>().add(const LightToggled('bedside_light'))),
        const SizedBox(height: 16),
        Text('🪟 窗帘控制 · ${state.curtain}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Slider(value: state.curtain.toDouble(), min: 0, max: 100, onChanged: (v) => context.read<RoomBloc>().add(CurtainChanged(v.round()))),
        const SizedBox(height: 16),
        Text('🌡️ 空调控制 · ${state.acTemp}°C', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TempButton(icon: Icons.remove, onTap: () { if (state.acTemp > 16) context.read<RoomBloc>().add(ACTemperatureChanged(state.acTemp - 1)); }),
            Container(width: 80, alignment: Alignment.center, child: Text('${state.acTemp}°C', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1677FF)))),
            _TempButton(icon: Icons.add, onTap: () { if (state.acTemp < 30) context.read<RoomBloc>().add(ACTemperatureChanged(state.acTemp + 1)); }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(label: const Text('❄️ 制冷'), selected: state.acCool, onSelected: (_) { if (!state.acCool) context.read<RoomBloc>().add(ACModeToggled()); }),
            const SizedBox(width: 12),
            ChoiceChip(label: const Text('🔥 制热'), selected: !state.acCool, onSelected: (_) { if (state.acCool) context.read<RoomBloc>().add(ACModeToggled()); }),
          ],
        ),
        const SizedBox(height: 12),
        const Text('⏱️ 所有控件挂载 500ms 防抖', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.orange)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hotel_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<RoomBloc>().add(RoomFetched()),
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onToggle;
  const _LightSwitch({required this.label, required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(label),
        secondary: Icon(value ? Icons.lightbulb : Icons.lightbulb_outline, color: value ? Colors.orange : Colors.grey),
        value: value,
        onChanged: (_) => onToggle(),
      ),
    );
  }
}

class _TempButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TempButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white),
    );
  }
}
