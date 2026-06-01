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
  int _selectedTab = 0; // 0=device, 1=scene

  @override
  void initState() {
    super.initState();
    final isLoggedIn = context.read<AuthBloc>().state.status == AuthStatus.authenticated;
    if (isLoggedIn) context.read<RoomBloc>().add(RoomFetched());
  }

  // ── Colors ──
  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1f2937);
  static const _cardInner = Color(0xFF374151);
  static const _blue = Color(0xFF2563eb);
  static const _muted = Color(0xFF9ca3af);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) {
        final isLoggedIn = context.watch<AuthBloc>().state.status == AuthStatus.authenticated;
        final loading = state.loading && state.roomNumber.isEmpty;

        return Scaffold(
          backgroundColor: _bg,
          body: loading
            ? const Center(child: CircularProgressIndicator(color: _blue))
            : !isLoggedIn
              ? _buildUnauthView()
              : _buildAuthView(context, state),
        );
      },
    );
  }

  Widget _buildUnauthView() {
    return Stack(children: [
      Opacity(opacity: 0.25, child: IgnorePointer(child: _buildDeviceTab(null))),
      const AuthPrompt.bottomBar(icon: '💡', title: '控房', description: '入住后即可控制房间设备'),
    ]);
  }

  Widget _buildAuthView(BuildContext context, RoomState state) {
    return Column(
      children: [
        // ── Header ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('智能客房', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${state.roomNumber} 房间', style: const TextStyle(fontSize: 14, color: _muted)),
                  ],
                ),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _card),
                  child: const Icon(Icons.hotel, color: _muted, size: 32),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ── Tab Switcher ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildTab('设备控制', 0),
              const SizedBox(width: 8),
              _buildTab('场景模式', 1),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── Content ──
        Expanded(
          child: _selectedTab == 0 ? _buildDeviceTab(state) : _buildSceneTab(state),
        ),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? _blue : _card,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isActive ? Colors.white : _muted)),
        ),
      ),
    );
  }

  // ── Device Control Tab ──
  Widget _buildDeviceTab(RoomState? state) {
    final s = state ?? const RoomState();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Lights
        _buildSectionTitle('灯光控制'),
        _buildToggleRow('筒灯', Icons.lightbulb, s.livingLight, () {
          context.read<RoomBloc>().add(const LightToggled('living_light'));
        }),
        _buildToggleRow('射灯', Icons.lightbulb, s.bedroomLight, () {
          context.read<RoomBloc>().add(const LightToggled('bedroom_light'));
        }),
        _buildToggleRow('床头灯', Icons.lightbulb_outline, s.bedsideLight, () {
          context.read<RoomBloc>().add(const LightToggled('bedside_light'));
        }),
        const SizedBox(height: 20),
        // Curtains
        _buildSectionTitle('窗帘控制'),
        _buildSliderRow('窗帘开合', s.curtain, (v) {
          context.read<RoomBloc>().add(CurtainChanged(v.round()));
        }),
        const SizedBox(height: 20),
        // AC
        _buildSectionTitle('空调控制'),
        _buildACControl(s),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Scene Tab ──
  Widget _buildSceneTab(RoomState? state) {
    final scenes = [
      {'icon': Icons.home, 'label': '回家模式', 'desc': '打开灯光、窗帘、空调调整到 24℃', 'color': _blue, 'key': 'home'},
      {'icon': Icons.nightlight_round, 'label': '睡眠模式', 'desc': '灯光关闭、窗帘关闭、空调调整到 26℃', 'color': const Color(0xFF7c3aed), 'key': 'sleep'},
      {'icon': Icons.movie_outlined, 'label': '观影模式', 'desc': '灯光调暗、窗帘关闭、空调调整到 24℃', 'color': const Color(0xFFdc2626), 'key': 'movie'},
      {'icon': Icons.menu_book_outlined, 'label': '阅读模式', 'desc': '床头灯调亮、窗帘打开、空调调整到 24℃', 'color': const Color(0xFF16a34a), 'key': 'reading'},
      {'icon': Icons.logout, 'label': '离开模式', 'desc': '关闭所有设备，节省电能', 'color': _muted, 'key': 'leave'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        ...scenes.map((scene) => GestureDetector(
          onTap: () => _applyScene(scene['key'] as String),
          child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: scene['color'] as Color, shape: BoxShape.circle),
                child: Icon(scene['icon'] as IconData, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scene['label'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(scene['desc'] as String, style: const TextStyle(fontSize: 12, color: _muted)),
                  ],
                ),
              ),
            ],
          ),
        ))),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF374151)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            child: const Text('自定义场景', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Helpers ──
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  Widget _buildToggleRow(String label, IconData icon, bool value, VoidCallback onToggle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: value ? _blue : _muted, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: value ? Colors.white : _muted))),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 44, height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: value ? _blue : _cardInner,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20, height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, int value, ValueChanged<double> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 15, color: Colors.white)),
              Text('$value%', style: const TextStyle(fontSize: 15, color: _blue, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6, activeTrackColor: _blue, inactiveTrackColor: _cardInner,
              thumbColor: Colors.white, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(value: value.toDouble(), min: 0, max: 100, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildACControl(RoomState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Temperature dial
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () { if (state.acTemp > 16) context.read<RoomBloc>().add(ACTemperatureChanged(state.acTemp - 1)); },
                child: Container(
                  width: 38, height: 38,
                  decoration: const BoxDecoration(color: _cardInner, shape: BoxShape.circle),
                  child: const Icon(Icons.remove, color: _blue, size: 20),
                ),
              ),
              const SizedBox(width: 25),
              Text('${state.acTemp}°C', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 25),
              GestureDetector(
                onTap: () { if (state.acTemp < 30) context.read<RoomBloc>().add(ACTemperatureChanged(state.acTemp + 1)); },
                child: Container(
                  width: 38, height: 38,
                  decoration: const BoxDecoration(color: _cardInner, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: _blue, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mode grid
          Row(
            children: [
              _buildModeItem('制冷', Icons.ac_unit, state.acCool, () {
                if (!state.acCool) context.read<RoomBloc>().add(ACModeToggled());
              }),
              _buildModeItem('制热', Icons.local_fire_department, !state.acCool, () {
                if (state.acCool) context.read<RoomBloc>().add(ACModeToggled());
              }),
              _buildModeItem('自动', Icons.sync, false, () {}),
              _buildModeItem('送风', Icons.air, false, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? _blue : _cardInner,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Apply Scene Mode ──
  Future<void> _applyScene(String key) async {
    final bloc = context.read<RoomBloc>();
    const d = Duration(milliseconds: 600); // debounce gap

    switch (key) {
      case 'home': // 回家: 全开灯 + 开窗帘 + 空调24°C制冷
        bloc.add(const LightToggled('living_light'));
        await Future.delayed(d);
        bloc.add(const LightToggled('bedroom_light'));
        await Future.delayed(d);
        bloc.add(const LightToggled('bedside_light'));
        await Future.delayed(d);
        bloc.add(const CurtainChanged(80));
        await Future.delayed(d);
        bloc.add(const ACTemperatureChanged(24));
        await Future.delayed(d);
        if (!bloc.state.acCool) bloc.add(ACModeToggled());
        break;

      case 'sleep': // 睡眠: 全关灯 + 关窗帘 + 空调26°C制热
        if (bloc.state.livingLight) bloc.add(const LightToggled('living_light'));
        await Future.delayed(d);
        if (bloc.state.bedroomLight) bloc.add(const LightToggled('bedroom_light'));
        await Future.delayed(d);
        if (bloc.state.bedsideLight) bloc.add(const LightToggled('bedside_light'));
        await Future.delayed(d);
        bloc.add(const CurtainChanged(0));
        await Future.delayed(d);
        bloc.add(const ACTemperatureChanged(26));
        await Future.delayed(d);
        if (bloc.state.acCool) bloc.add(ACModeToggled());
        break;

      case 'movie': // 观影: 关客厅灯卧室灯 + 开床头灯 + 关窗帘 + 空调24°C
        if (bloc.state.livingLight) bloc.add(const LightToggled('living_light'));
        await Future.delayed(d);
        if (bloc.state.bedroomLight) bloc.add(const LightToggled('bedroom_light'));
        await Future.delayed(d);
        if (!bloc.state.bedsideLight) bloc.add(const LightToggled('bedside_light'));
        await Future.delayed(d);
        bloc.add(const CurtainChanged(0));
        await Future.delayed(d);
        bloc.add(const ACTemperatureChanged(24));
        break;

      case 'reading': // 阅读: 开床头灯 + 开窗帘 + 空调24°C
        if (!bloc.state.bedsideLight) bloc.add(const LightToggled('bedside_light'));
        await Future.delayed(d);
        if (bloc.state.livingLight) bloc.add(const LightToggled('living_light'));
        await Future.delayed(d);
        if (bloc.state.bedroomLight) bloc.add(const LightToggled('bedroom_light'));
        await Future.delayed(d);
        bloc.add(const CurtainChanged(80));
        await Future.delayed(d);
        bloc.add(const ACTemperatureChanged(24));
        break;

      case 'leave': // 离开: 全关灯 + 关窗帘
        if (bloc.state.livingLight) bloc.add(const LightToggled('living_light'));
        await Future.delayed(d);
        if (bloc.state.bedroomLight) bloc.add(const LightToggled('bedroom_light'));
        await Future.delayed(d);
        if (bloc.state.bedsideLight) bloc.add(const LightToggled('bedside_light'));
        await Future.delayed(d);
        bloc.add(const CurtainChanged(0));
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_sceneLabel(key)}已生效'),
          backgroundColor: const Color(0xFF16a34a),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  String _sceneLabel(String key) {
    switch (key) {
      case 'home': return '回家模式';
      case 'sleep': return '睡眠模式';
      case 'movie': return '观影模式';
      case 'reading': return '阅读模式';
      case 'leave': return '离开模式';
      default: return '';
    }
  }
}
