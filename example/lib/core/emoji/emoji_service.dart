import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

/// Misskey.ioの絵文字設定を管理するシングルトンサービス
class EmojiService {
  EmojiService._();

  static const String _misskeyIoUrl = 'https://misskey.io';
  static final EmojiService instance = EmojiService._();

  MfmRenderConfig? _config;
  Future<MfmRenderConfig>? _initFuture;

  /// 初期化済みかどうか
  bool get isInitialized => _config != null;

  /// 共有用のMFM設定を取得（初期化前に呼ぶとエラー）
  MfmRenderConfig get config {
    final config = _config;
    if (config == null) {
      throw StateError(
        'EmojiService is not initialized. Call initialize() first.',
      );
    }
    return config;
  }

  /// サービスを初期化（複数回呼んでも安全）
  Future<MfmRenderConfig> initialize() async {
    if (_config != null) return _config!;
    if (_initFuture != null) return _initFuture!;

    _initFuture = MfmEmojiConfig.quickSetup(
      serverUrl: _misskeyIoUrl,
    );
    try {
      _config = await _initFuture;
      return _config!;
    } finally {
      _initFuture = null;
    }
  }
}
