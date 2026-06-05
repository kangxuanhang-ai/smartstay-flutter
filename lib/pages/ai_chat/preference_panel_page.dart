import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class PreferencePanelPage extends StatefulWidget {
  const PreferencePanelPage({super.key});

  @override
  State<PreferencePanelPage> createState() => _PreferencePanelPageState();
}

class _PreferencePanelPageState extends State<PreferencePanelPage>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late AnimationController _animController;

  // Preference values
  bool _bedsideLight = false;
  bool _bedroomLight = false;
  bool _livingLight = false;
  double _acTemp = 24;
  bool _acCool = true;
  double _curtain = 80;

  bool _loading = true;
  Timer? _debounceTimer;

  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1A1A2E);
  static const _blue = Color(0xFF2563eb);
  static const _green = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadPreferences();
  }

  @override
  void dispose() {
    _animController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final resp = await _api.get('/api/ai/preferences');
      final prefs = resp.data as Map<String, dynamic>;
      setState(() {
        _bedsideLight = prefs['bedside_light'] == 'on';
        _bedroomLight = prefs['bedroom_light'] == 'on';
        _livingLight = prefs['living_light'] == 'on';
        _acTemp = double.tryParse(prefs['ac_temp'] ?? '24') ?? 24;
        _acCool = prefs['ac_mode'] != 'heat';
        _curtain = double.tryParse(prefs['curtain'] ?? '80') ?? 80;
        _loading = false;
      });
      _animController.forward();
    } catch (_) {
      setState(() => _loading = false);
      _animController.forward();
    }
  }

  Future<void> _savePreference(String key, String value) async {
    try {
      await _api.post('/api/ai/preferences', data: {'key': key, 'value': value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('偏好已保存，AI 将在下次对话中使用'),
            backgroundColor: const Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('保存失败，请重试'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _debounceSave(String key, String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _savePreference(key, value);
    });
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('清除所有偏好', style: TextStyle(color: Colors.white)),
        content: const Text('确定清除所有偏好？AI 将使用默认设置', style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Color(0xFF9CA3AF)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (confirm != true) return;

    final keys = ['bedside_light', 'bedroom_light', 'living_light', 'ac_temp', 'ac_mode', 'curtain'];
    for (final key in keys) {
      try {
        await _api.delete('/api/ai/preferences/$key');
      } catch (_) {}
    }

    setState(() {
      _bedsideLight = false;
      _bedroomLight = false;
      _livingLight = false;
      _acTemp = 24;
      _acCool = true;
      _curtain = 80;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('所有偏好已清除'),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('AI 偏好设置', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('💡', '灯光偏好'),
                const SizedBox(height: 8),
                _buildLightCard(),
                const SizedBox(height: 20),
                _buildSectionHeader('🌡️', '温度偏好'),
                const SizedBox(height: 8),
                _buildTempCard(),
                const SizedBox(height: 20),
                _buildSectionHeader('🪟', '窗帘偏好'),
                const SizedBox(height: 8),
                _buildCurtainCard(),
                const SizedBox(height: 32),
                _buildClearButton(),
                const SizedBox(height: 16),
                _buildHint(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String emoji, String title) {
    final idx = title == '灯光偏好' ? 0 : title == '温度偏好' ? 1 : 2;
    final anim = CurvedAnimation(
      parent: _animController,
      curve: Interval(idx * 0.15, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildLightCard() {
    final anim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildSwitchTile('🌙', '床头灯', _bedsideLight, (v) {
                setState(() => _bedsideLight = v);
                _savePreference('bedside_light', v ? 'on' : 'off');
              }),
              const Divider(height: 1, color: Color(0xFF2D2D44)),
              _buildSwitchTile('💡', '卧室灯', _bedroomLight, (v) {
                setState(() => _bedroomLight = v);
                _savePreference('bedroom_light', v ? 'on' : 'off');
              }),
              const Divider(height: 1, color: Color(0xFF2D2D44)),
              _buildSwitchTile('🪔', '客厅灯', _livingLight, (v) {
                setState(() => _livingLight = v);
                _savePreference('living_light', v ? 'on' : 'off');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String emoji, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _green,
            inactiveTrackColor: const Color(0xFF374151),
            inactiveThumbColor: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  Widget _buildTempCard() {
    final anim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.9, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    const Text('🌡️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('空调温度', style: TextStyle(fontSize: 14, color: Colors.white))),
                    Text(
                      '${_acTemp.round()}°C',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF60a5fa)),
                    ),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Color.lerp(const Color(0xFF3B82F6), const Color(0xFFEF4444), (_acTemp - 16) / 14),
                  inactiveTrackColor: const Color(0xFF374151),
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFF667EEA).withOpacity(0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _acTemp,
                  min: 16,
                  max: 30,
                  divisions: 14,
                  onChanged: (v) => setState(() => _acTemp = v),
                  onChangeEnd: (v) => _debounceSave('ac_temp', v.round().toString()),
                ),
              ),
              const Divider(height: 1, color: Color(0xFF2D2D44)),
              _buildSwitchTile('❄️', '空调模式', _acCool, (v) {
                setState(() => _acCool = v);
                _savePreference('ac_mode', v ? 'cool' : 'heat');
              }),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _acCool ? '当前：制冷模式' : '当前：制热模式',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurtainCard() {
    final anim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('🪟', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('窗帘开度', style: TextStyle(fontSize: 14, color: Colors.white))),
                    Text(
                      '${_curtain.round()}%',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF60a5fa)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF60a5fa),
                    inactiveTrackColor: const Color(0xFF374151),
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xFF60a5fa).withOpacity(0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _curtain,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    onChanged: (v) => setState(() => _curtain = v),
                    onChangeEnd: (v) => _debounceSave('curtain', v.round().toString()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _clearAll,
        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
        label: const Text('清除所有偏好', style: TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF374151)),
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return const Center(
      child: Text(
        '💡 偏好会被 AI 自动应用到每次入住',
        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
      ),
    );
  }
}
