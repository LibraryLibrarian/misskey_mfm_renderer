import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:path_provider/path_provider.dart';

import '../config/mfm_render_config.dart';
import '../widgets/mfm_custom_emoji.dart';

/// MFMカスタム絵文字のセットアップを簡略化するヘルパークラス
class MfmEmojiConfig {
  const MfmEmojiConfig._();

  /// シンプルなセットアップ（最も一般的な使用ケース）
  ///
  /// サーバーURLを指定するだけで永続化ストレージ込みのEmojiResolverとMfmRenderConfigを構築
  static Future<MfmRenderConfig> quickSetup({
    required String serverUrl,
    String? storagePath,
    double emojiSize = 24.0,
    Widget Function(BuildContext context, String name)? fallbackBuilder,
    SyncErrorCallback? onSyncError,
    bool autoSync = true,
  }) {
    final uri = _normalizeServerUrl(serverUrl);
    return createDefault(
      serverUrl: uri,
      storagePath: storagePath,
      emojiSize: emojiSize,
      fallbackBuilder: fallbackBuilder,
      onSyncError: onSyncError,
      autoSync: autoSync,
    );
  }

  /// カスタマイズ可能なセットアップ
  ///
  /// より詳細な制御が必要な場合に使用
  static Future<MfmRenderConfig> createDefault({
    required Uri serverUrl,
    String? storagePath,
    double emojiSize = 24.0,
    Widget Function(BuildContext context, String name)? fallbackBuilder,
    SyncErrorCallback? onSyncError,
    bool autoSync = true,
  }) async {
    final directory = (storagePath != null && storagePath.isNotEmpty)
        ? storagePath
        : (await getApplicationDocumentsDirectory()).path;

    await Directory(directory).create(recursive: true);

    final isar = await openEmojiIsarForServer(
      serverUrl,
      directory: directory,
    );

    final httpClient = MisskeyHttpClient(
      config: MisskeyApiConfig(baseUrl: serverUrl),
    );
    final api = MisskeyEmojiApi(httpClient);
    final store = IsarEmojiStore(isar);

    final catalog = PersistentEmojiCatalog(
      api: api,
      store: store,
      meta: MetaClient(httpClient),
      onSyncError: onSyncError,
    );
    final resolver = MisskeyEmojiResolver(catalog);

    if (autoSync) {
      unawaited(
        catalog.sync().catchError((Object error, StackTrace stackTrace) {
          if (error is Exception) {
            onSyncError?.call(error, stackTrace);
          }
        }),
      );
    }

    return fromResolver(
      resolver: resolver.call,
      emojiSize: emojiSize,
      fallbackBuilder: fallbackBuilder,
    );
  }

  /// 作成済みのResolverからConfigを構築
  static MfmRenderConfig fromResolver({
    required EmojiResolver resolver,
    double emojiSize = 24.0,
    Widget Function(BuildContext context, String name)? fallbackBuilder,
  }) {
    return MfmRenderConfig(
      emojiBuilder: (name) => MfmCustomEmoji(
        name: name,
        resolver: resolver,
        size: emojiSize,
        fallbackBuilder: fallbackBuilder,
      ),
    );
  }

  static Uri _normalizeServerUrl(String serverUrl) {
    final parsed = Uri.parse(serverUrl);
    if (parsed.hasScheme) {
      return parsed;
    }
    return Uri.parse('https://$serverUrl');
  }
}
