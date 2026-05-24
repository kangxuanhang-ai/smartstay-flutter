import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_client.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<Object, RoomState> {
  RoomBloc() : super(const RoomState()) {
    on<RoomFetched>(_onFetched);
    on<LightToggled>(_onLightToggled);
    on<CurtainChanged>(_onCurtainChanged);
    on<ACTemperatureChanged>(_onACTemperatureChanged);
    on<ACModeToggled>(_onACModeToggled);
  }

  final _api = ApiClient();
  Timer? _debounceTimer;

  Future<void> _onFetched(RoomFetched event, Emitter<RoomState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      final resp = await _api.get('/api/rooms/my-room');
      final r = resp.data as Map<String, dynamic>;
      final devices = r['device_states'] as Map<String, dynamic>? ?? {};

      emit(RoomState(
        roomNumber: r['room_number'] ?? '',
        roomType: r['room_type'] ?? '',
        basePrice: (r['base_price'] ?? 0) / 100,
        currentPrice: (r['current_price'] ?? 0) / 100,
        roomStatus: r['status'] ?? '',
        livingLight: devices['living_light'] == true,
        bedroomLight: devices['bedroom_light'] == true,
        bedsideLight: devices['bedside_light'] == true,
        curtain: (devices['curtain'] as num?)?.toInt() ?? 50,
        acTemp: (devices['ac_temp'] as num?)?.toInt() ?? 24,
        acCool: devices['ac_mode'] != 'heat',
      ));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  // ── 乐观更新：UI 立即变，网络 500ms 防抖 ──

  Future<void> _onLightToggled(LightToggled event, Emitter<RoomState> emit) async {
    final current = event.lightKey == 'living_light'
        ? state.livingLight
        : event.lightKey == 'bedroom_light'
            ? state.bedroomLight
            : state.bedsideLight;

    if (event.lightKey == 'living_light') {
      emit(state.copyWith(livingLight: !current));
    } else if (event.lightKey == 'bedroom_light') {
      emit(state.copyWith(bedroomLight: !current));
    } else {
      emit(state.copyWith(bedsideLight: !current));
    }

    _debouncePost(event.lightKey, !current);
  }

  Future<void> _onCurtainChanged(CurtainChanged event, Emitter<RoomState> emit) async {
    emit(state.copyWith(curtain: event.value));
    _debouncePost('curtain', event.value);
  }

  Future<void> _onACTemperatureChanged(ACTemperatureChanged event, Emitter<RoomState> emit) async {
    final temp = event.temp.clamp(16, 30);
    emit(state.copyWith(acTemp: temp));
    _debouncePost('ac_temp', temp);
  }

  Future<void> _onACModeToggled(ACModeToggled event, Emitter<RoomState> emit) async {
    final newMode = !state.acCool;
    emit(state.copyWith(acCool: newMode));
    _debouncePost('ac_mode', newMode ? 'cool' : 'heat');
  }

  void _debouncePost(String device, dynamic value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _api.post('/api/rooms/my-room/device', data: {
          'device': device,
          'state': value is bool ? {'on': value} : {'value': value},
        });
      } catch (_) {}
    });
  }
}
