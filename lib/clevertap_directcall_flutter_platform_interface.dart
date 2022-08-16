import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'clevertap_directcall_flutter_method_channel.dart';

abstract class ClevertapDirectcallFlutterPlatform extends PlatformInterface {
  /// Constructs a ClevertapDirectcallFlutterPlatform.
  ClevertapDirectcallFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static ClevertapDirectcallFlutterPlatform _instance = MethodChannelClevertapDirectcallFlutter();

  /// The default instance of [ClevertapDirectcallFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelClevertapDirectcallFlutter].
  static ClevertapDirectcallFlutterPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ClevertapDirectcallFlutterPlatform] when
  /// they register themselves.
  static set instance(ClevertapDirectcallFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
