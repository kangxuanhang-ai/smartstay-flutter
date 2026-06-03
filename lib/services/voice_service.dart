import 'dart:async';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _durationTimer;
  int _duration = 0;

  int get duration => _duration;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<void> startRecording() async {
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      final granted = await requestPermission();
      if (!granted) {
        throw Exception('麦克风权限被拒绝');
      }
    }

    _duration = 0;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: '',
    );

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _duration++;
    });
  }

  Future<String?> stopRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    final path = await _recorder.stop();
    return path;
  }

  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    await _recorder.cancel();
  }

  Future<bool> isRecording() async {
    return _recorder.isRecording();
  }

  void dispose() {
    _durationTimer?.cancel();
    _recorder.dispose();
  }
}
