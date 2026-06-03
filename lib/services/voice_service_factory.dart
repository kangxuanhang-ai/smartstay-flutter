import 'voice_service_stub.dart'
    if (dart.library.io) 'voice_service_io.dart'
    if (dart.library.html) 'voice_service_web_impl.dart';

/// 创建平台对应的录音服务
/// Native: 使用 record 包
/// Web: 使用原生 MediaRecorder API（绕过 record 包的类型问题）
VoiceServiceBase createVoiceService() => createVoiceServiceImpl();
