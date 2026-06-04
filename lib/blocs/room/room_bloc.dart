import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api_client.dart';
import '../../core/ws_service.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<Object, RoomState> {
  final _api = ApiClient();
  final _ws = WsService();
  StreamSubscription? _wsSub;
  final Map<String, Timer> _debounceTimers = {};

  RoomBloc() : super(const RoomState()) {
    on<RoomFetched>(_onFetched);
    on<LightToggled>(_onLightToggled);
    on<CurtainChanged>(_onCurtainChanged);
    on<ACTemperatureChanged>(_onACTemperatureChanged);
    on<ACModeToggled>(_onACModeToggled);

    _wsSub = _ws.events.listen((msg) {
      if (msg['event'] == 'device_state_change') {
        add(RoomFetched());
      }
    });
  }

  Future<void> _onFetched(RoomFetched event, Emitter<RoomState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      final resp = await _api.get('/api/rooms/my-room');
      final r = resp.data as Map<String, dynamic>;
      final devices = r['device_states'] as Map<String, dynamic>? ?? {};

      final livingLight = _extractBool(devices['living_light']);
      final bedroomLight = _extractBool(devices['bedroom_light']);
      final bedsideLight = _extractBool(devices['bedside_light']);
      final curtain = _extractInt(devices['curtain'], fallback: 50);
      final acTemp = _extractInt(devices['ac_temp'], fallback: 24);
      final acMode = devices['ac_mode'];
      final acCool = acMode is Map ? acMode['value'] != 'heat' : acMode != 'heat';

      emit(RoomState(
        roomNumber: r['room_number'] ?? '', roomType: r['room_type'] ?? '',
        basePrice: (r['base_price'] ?? 0) / 100, currentPrice: (r['current_price'] ?? 0) / 100,
        roomStatus: r['status'] ?? '',
        livingLight: livingLight, bedroomLight: bedroomLight, bedsideLight: bedsideLight,
        curtain: curtain, acTemp: acTemp, acCool: acCool,
      ));
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String msg;
      if (statusCode == 404) {
        msg = '您当前没有入住中的房间，请先办理入住';
      } else if (statusCode == 401) {
        msg = '登录已过期，请重新登录';
      } else if (statusCode == 403) {
        msg = '无权限访问房间控制';
      } else {
        msg = '网络异常，请检查网络后重试';
      }
      emit(state.copyWith(loading: false, error: msg));
    } catch (_) {
      emit(state.copyWith(loading: false, error: '加载房间数据失败，请稍后重试'));
    }
  }

  /// 兼容 {on: true/false} 和直接 true/false 两种格式
  bool _extractBool(dynamic value) {
    if (value is bool) return value;
    if (value is Map) return value['on'] == true || value['value'] == true;
    return false;
  }

  /// 兼容 {value: 45} 和直接 45 两种格式
  int _extractInt(dynamic value, {required int fallback}) {
    if (value is num) return value.toInt();
    if (value is Map) {
      final v = value['value'];
      if (v is num) return v.toInt();
    }
    return fallback;
  }

  Future<void> _onLightToggled(LightToggled e, Emitter<RoomState> emit) async {
    final current = e.lightKey == 'living_light' ? state.livingLight : e.lightKey == 'bedroom_light' ? state.bedroomLight : state.bedsideLight;
    if (e.lightKey == 'living_light') emit(state.copyWith(livingLight: !current));
    else if (e.lightKey == 'bedroom_light') emit(state.copyWith(bedroomLight: !current));
    else emit(state.copyWith(bedsideLight: !current));
    _debouncePost(e.lightKey, !current, emit);
  }

  Future<void> _onCurtainChanged(CurtainChanged e, Emitter<RoomState> emit) async {
    emit(state.copyWith(curtain: e.value));
    _debouncePost('curtain', e.value, emit);
  }

  Future<void> _onACTemperatureChanged(ACTemperatureChanged e, Emitter<RoomState> emit) async {
    final temp = e.temp.clamp(16, 30);
    emit(state.copyWith(acTemp: temp));
    _debouncePost('ac_temp', temp, emit);
  }

  Future<void> _onACModeToggled(ACModeToggled e, Emitter<RoomState> emit) async {
    final newMode = !state.acCool;
    emit(state.copyWith(acCool: newMode));
    _debouncePost('ac_mode', newMode ? 'cool' : 'heat', emit);
  }

  void _debouncePost(String device, dynamic value, Emitter<RoomState> emit) {
    _debounceTimers[device]?.cancel();
    _debounceTimers[device] = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _api.post('/api/rooms/my-room/device', data: {
          'device': device, 'state': value is bool ? {'on': value} : {'value': value},
        });
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          emit(state.copyWith(error: '未入住，设备控制不可用'));
        } else if (statusCode == 401) {
          emit(state.copyWith(error: '登录已过期，请重新登录'));
        } else {
          emit(state.copyWith(error: '设备控制失败，请重试'));
        }
      } catch (_) {
        emit(state.copyWith(error: '设备控制失败'));
      }
    });
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    for (final t in _debounceTimers.values) { t.cancel(); }
    return super.close();
  }
}
