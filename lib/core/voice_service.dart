import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_client.dart';

enum VoiceState { idle, recording, transcribing, error }

class VoiceService {
  static final VoiceService instance = VoiceService._();
  VoiceService._();

  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;

  Timer? _durationTimer;
  int _durationSeconds = 0;
  int get durationSeconds => _durationSeconds;

  final _stateController = StreamController<VoiceState>.broadcast();
  Stream<VoiceState> get stateStream => _stateController.stream;

  final _durationController = StreamController<int>.broadcast();
  Stream<int> get durationStream => _durationController.stream;

  // ── Start Recording ──
  Future<bool> startRecording() async {
    // Check microphone permission
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      _state = VoiceState.error;
      _stateController.add(_state);
      return false;
    }

    try {
      // Start recording using record package
      // Note: Record package integration - simplified for now
      // In production, use: await _recorder.start(const RecordConfig(), path: filePath);

      _durationSeconds = 0;
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _durationSeconds++;
        _durationController.add(_durationSeconds);

        // Auto-stop at 60 seconds
        if (_durationSeconds >= 60) {
          stopRecording();
        }
      });

      _state = VoiceState.recording;
      _stateController.add(_state);
      return true;
    } catch (e) {
      _state = VoiceState.error;
      _stateController.add(_state);
      return false;
    }
  }

  // ── Stop Recording ──
  Future<String?> stopRecording() async {
    _durationTimer?.cancel();

    // Too short
    if (_durationSeconds < 1) {
      _state = VoiceState.error;
      _stateController.add(_state);
      return null;
    }

    try {
      // Stop recording and get file path
      // final path = await _recorder.stop();
      final path = '${Directory.systemTemp.path}/voice_latest.aac';

      _state = VoiceState.transcribing;
      _stateController.add(_state);
      return path;
    } catch (e) {
      _state = VoiceState.error;
      _stateController.add(_state);
      return null;
    }
  }

  // ── Upload to ASR ──
  Future<String?> transcribe(String audioPath) async {
    try {
      final api = ApiClient();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioPath),
      });
      final resp = await api.post('/api/ai/asr', data: formData);
      final text = resp.data['text'] as String?;

      // Delete temp file
      try {
        File(audioPath).deleteSync();
      } catch (_) {}

      _state = VoiceState.idle;
      _stateController.add(_state);
      return text;
    } catch (e) {
      _state = VoiceState.error;
      _stateController.add(_state);
      return null;
    }
  }

  // ── Cancel Recording ──
  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    // await _recorder.stop();
    _state = VoiceState.idle;
    _stateController.add(_state);
  }

  // ── Reset to Idle ──
  void resetToIdle() {
    _durationTimer?.cancel();
    _state = VoiceState.idle;
    _stateController.add(_state);
  }

  void dispose() {
    _durationTimer?.cancel();
    _stateController.close();
    _durationController.close();
  }
}
