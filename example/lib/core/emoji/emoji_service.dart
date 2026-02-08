import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:path_provider/path_provider.dart';

/// Misskey.ioの絵文字リゾルバーを管理するシングルトンサービス
class EmojiService {
  EmojiService._();

  static const String _misskeyIoUrl = 'https://misskey.io';
  static final EmojiService instance = EmojiService._();

  late final MisskeyEmojiResolver _resolver;
  late final PersistentEmojiCatalog _catalog;
  late final Isar _isar;

  bool _initialized = false;
  Future<void>? _initFuture;

  /// 初期化済みかどうか
  bool get isInitialized => _initialized;

  /// 絵文字リゾルバーを取得（初期化前に呼ぶとエラー）
  MisskeyEmojiResolver get resolver {
    if (!_initialized) {
      throw StateError(
        'EmojiService is not initialized. Call initialize() first.',
      );
    }
    return _resolver;
  }

  /// 絵文字カタログを取得（初期化前に呼ぶとエラー）
  PersistentEmojiCatalog get catalog {
    if (!_initialized) {
      throw StateError(
        'EmojiService is not initialized. Call initialize() first.',
      );
    }
    return _catalog;
  }

  /// サービスを初期化（複数回呼んでも安全）
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    _initFuture = _doInitialize();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _doInitialize() async {
    final dir = await getApplicationDocumentsDirectory();
    final baseUrl = Uri.parse(_misskeyIoUrl);

    _isar = await openEmojiIsarForServer(baseUrl, directory: dir.path);

    final httpClient = MisskeyHttpClient(
      config: MisskeyApiConfig(baseUrl: baseUrl),
    );
    final api = MisskeyEmojiApi(httpClient);
    final store = IsarEmojiStore(_isar);

    _catalog = PersistentEmojiCatalog(
      api: api,
      store: store,
      meta: MetaClient(httpClient),
    );

    _resolver = MisskeyEmojiResolver(_catalog);

    // 初回同期はバックグラウンドで実行（失敗してもアプリは起動させる）
    unawaited(
      _catalog.sync().catchError((Object e) {
        // 初回同期失敗時も起動は継続
        debugPrint('初回絵文字同期に失敗: $e');
      }),
    );

    _initialized = true;
  }

  /// 強制的に絵文字を再同期
  Future<void> sync({bool force = true}) async {
    if (!_initialized) {
      throw StateError('EmojiService is not initialized.');
    }
    await _catalog.sync(force: force);
  }

  /// リソースの解放
  Future<void> dispose() async {
    if (_initialized) {
      await _isar.close();
      _initialized = false;
    }
  }
}
