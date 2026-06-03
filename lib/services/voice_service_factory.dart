import 'voice_service_base.dart';
import 'voice_service_stub.dart'
    if (dart.library.io) 'voice_service_io.dart'
    if (dart.library.html) 'voice_service_web_impl.dart';

/// 创建平台对应的录音服务
VoiceServiceBase createVoiceService() => createVoiceServiceImpl();
