import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

/// Misskey.ioの絵文字設定を管理するシングルトンサービス
class EmojiService {
  EmojiService._();

  static const String _misskeyIoUrl = 'https://misskey.io';
  static final EmojiService instance = EmojiService._();

  MfmEmojiConfigHandle? _config;
  Future<MfmEmojiConfigHandle>? _initFuture;
  Future<void>? _disposeFuture;

  /// 初期化済みかどうか
  bool get isInitialized => _config != null;

  /// 共有用のMFM設定を取得（初期化前に呼ぶとエラー）
  MfmEmojiConfigHandle get config {
    final config = _config;
    if (config == null) {
      throw StateError(
        'EmojiService is not initialized. Call initialize() first.',
      );
    }
    return config;
  }

  /// サービスを初期化（複数回呼んでも安全）
  Future<MfmEmojiConfigHandle> initialize() async {
    final disposeFuture = _disposeFuture;
    if (disposeFuture != null) {
      await disposeFuture;
    }

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

  /// 永続ストアなど、絵文字設定が所有するリソースを解放
  Future<void> dispose() => _disposeFuture ??= _dispose();

  Future<void> _dispose() async {
    final pending = _initFuture;
    try {
      final config = _config ?? (pending == null ? null : await pending);
      _config = null;
      await config?.dispose();
    } finally {
      _disposeFuture = null;
    }
  }
}
