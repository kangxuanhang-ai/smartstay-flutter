import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/room/room_bloc.dart';
import '../../blocs/room/room_event.dart';
import '../../blocs/room/room_state.dart';

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
        final loading = state.loading && state.roomNumber.isEmpty;
        return Scaffold(
          appBar: AppBar(title: Text('💡 智能控房 · ${state.roomNumber}'), backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  if (state.error != null)
                    Container(width: double.infinity, padding: const EdgeInsets.all(10), color: Colors.red.shade50,
                      child: Text('⚠️ ${state.error}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)),
                  Expanded(child: ListView(
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
                ),
              ),
            ],
          ),
        );
      },
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
