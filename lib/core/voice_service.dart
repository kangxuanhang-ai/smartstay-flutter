import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'api_client.dart';

enum VoiceState { idle, recording, transcribing, error }

class VoiceService {
  static final VoiceService instance = VoiceService._();
  VoiceService._();

  final _recorder = AudioRecorder();
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
    // Check microphone permission (skip on web - browser handles it)
    if (!kIsWeb) {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        _state = VoiceState.error;
        _stateController.add(_state);
        return false;
      }
    }

    try {
      // Check if recorder has permission
      if (!await _recorder.hasPermission()) {
        _state = VoiceState.error;
        _stateController.add(_state);
        return false;
      }

      // Start recording
      final config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
      );

      // Generate unique path (on web this is a virtual identifier)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = kIsWeb
          ? 'voice_$timestamp'
          : '${Directory.systemTemp.path}/voice_$timestamp.aac';
      await _recorder.start(config, path: path);

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
      final path = await _recorder.stop();
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

      MultipartFile file;
      if (kIsWeb) {
        // Web: audioPath is a blob URL, need to fetch and convert
        // For web, we'd need to use http to fetch the blob
        // Simplified: the record package on web returns a URL
        // We'll need to handle this differently on web
        final dio = Dio();
        final response = await dio.get<List<int>>(
          audioPath,
          options: Options(responseType: ResponseType.bytes),
        );
        file = MultipartFile.fromBytes(
          response.data!,
          filename: 'voice.wav',
        );
      } else {
        file = await MultipartFile.fromFile(audioPath);
      }

      final formData = FormData.fromMap({'file': file});
      final resp = await api.post('/api/ai/asr', data: formData);
      final text = resp.data['text'] as String?;

      // Delete temp file (native only)
      if (!kIsWeb) {
        try {
          File(audioPath).deleteSync();
        } catch (_) {}
      }

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
    try {
      await _recorder.stop();
    } catch (_) {}
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
    _recorder.dispose();
    _stateController.close();
    _durationController.close();
  }
}
