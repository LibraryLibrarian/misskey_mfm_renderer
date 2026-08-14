import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_emoji/misskey_emoji.dart';
import 'package:path_provider/path_provider.dart';

import '../config/mfm_render_config.dart';
import '../widgets/mfm_custom_emoji.dart';

/// カスタム絵文字の永続ストアを生成するファクトリー
///
/// 返したストアの所有権は[MfmEmojiConfigHandle]へ移り、
/// [MfmEmojiConfigHandle.dispose]で破棄される。
typedef MfmEmojiStoreFactory =
    FutureOr<EmojiStore> Function({
      required Uri serverUrl,
      required String directory,
    });

/// 永続ストアのライフサイクルを所有するMFMレンダリング設定
///
/// [MfmRenderConfig]としてそのまま利用できる。
/// 不要になったら[dispose]を呼び、Isarなどのリソースを解放すること。
class MfmEmojiConfigHandle extends MfmRenderConfig {
  MfmEmojiConfigHandle._({
    required MfmRenderConfig config,
    required _MfmEmojiConfigLifecycle lifecycle,
  }) : _lifecycle = lifecycle,
       super(
         baseTextStyle: config.baseTextStyle,
         enableAdvancedMfm: config.enableAdvancedMfm,
         enableAnimation: config.enableAnimation,
         enableNyaize: config.enableNyaize,
         emojiBuilder: config.emojiBuilder,
         unicodeEmojiBuilder: config.unicodeEmojiBuilder,
         onLinkTap: config.onLinkTap,
         onMentionTap: config.onMentionTap,
         onHashtagTap: config.onHashtagTap,
         onSearchTap: config.onSearchTap,
         onClickableEvent: config.onClickableEvent,
         fontFamilyResolver: config.fontFamilyResolver,
         codeTheme: config.codeTheme,
         codeDarkTheme: config.codeDarkTheme,
         brightness: config.brightness,
         showCodeBlockCopyButton: config.showCodeBlockCopyButton,
         inlineCodeBgColorLight: config.inlineCodeBgColorLight,
         inlineCodeBgColorDark: config.inlineCodeBgColorDark,
       );

  final _MfmEmojiConfigLifecycle _lifecycle;

  /// この設定が破棄済み、または破棄中かどうか
  bool get isDisposed => _lifecycle.isDisposed;

  /// 自動同期の完了を待ち、永続ストアなどのリソースを解放する
  ///
  /// 複数回呼び出しても安全。
  Future<void> dispose() => _lifecycle.dispose();

  /// 設定値を変更しつつ、元のハンドルと同じリソース所有権を共有する。
  ///
  /// いずれかのコピーで[dispose]を呼ぶと、同じライフサイクルを共有する
  /// すべてのコピーが破棄済みになる。
  @override
  MfmEmojiConfigHandle copyWith({
    TextStyle? baseTextStyle,
    bool? enableAdvancedMfm,
    bool? enableAnimation,
    bool? enableNyaize,
    Widget Function(String name)? emojiBuilder,
    Widget Function(String emoji)? unicodeEmojiBuilder,
    void Function(String url)? onLinkTap,
    void Function(String acct)? onMentionTap,
    void Function(String tag)? onHashtagTap,
    void Function(String query)? onSearchTap,
    void Function(String eventId)? onClickableEvent,
    String? Function(String fontType)? fontFamilyResolver,
    Map<String, TextStyle>? codeTheme,
    Map<String, TextStyle>? codeDarkTheme,
    Brightness? brightness,
    bool? showCodeBlockCopyButton,
    Color? inlineCodeBgColorLight,
    Color? inlineCodeBgColorDark,
  }) {
    final config = super.copyWith(
      baseTextStyle: baseTextStyle,
      enableAdvancedMfm: enableAdvancedMfm,
      enableAnimation: enableAnimation,
      enableNyaize: enableNyaize,
      emojiBuilder: emojiBuilder,
      unicodeEmojiBuilder: unicodeEmojiBuilder,
      onLinkTap: onLinkTap,
      onMentionTap: onMentionTap,
      onHashtagTap: onHashtagTap,
      onSearchTap: onSearchTap,
      onClickableEvent: onClickableEvent,
      fontFamilyResolver: fontFamilyResolver,
      codeTheme: codeTheme,
      codeDarkTheme: codeDarkTheme,
      brightness: brightness,
      showCodeBlockCopyButton: showCodeBlockCopyButton,
      inlineCodeBgColorLight: inlineCodeBgColorLight,
      inlineCodeBgColorDark: inlineCodeBgColorDark,
    );
    return MfmEmojiConfigHandle._(config: config, lifecycle: _lifecycle);
  }
}

class _MfmEmojiConfigLifecycle {
  _MfmEmojiConfigLifecycle({
    required EmojiCatalog catalog,
    required Future<void>? autoSyncFuture,
    required ValueNotifier<int>? autoSyncNotifier,
  }) : _catalog = catalog,
       _autoSyncFuture = autoSyncFuture,
       _autoSyncNotifier = autoSyncNotifier;

  final EmojiCatalog _catalog;
  final Future<void>? _autoSyncFuture;
  final ValueNotifier<int>? _autoSyncNotifier;

  Future<void>? _disposeFuture;

  bool get isDisposed => _disposeFuture != null;

  Future<void> dispose() => _disposeFuture ??= _dispose();

  Future<void> _dispose() async {
    try {
      try {
        final autoSyncFuture = _autoSyncFuture;
        if (autoSyncFuture != null) {
          await autoSyncFuture;
        }
      } finally {
        await _catalog.dispose();
      }
    } finally {
      _autoSyncNotifier?.dispose();
    }
  }
}

/// MFMカスタム絵文字のセットアップを簡略化するヘルパークラス
class MfmEmojiConfig {
  const MfmEmojiConfig._();

  /// 永続化ストレージ込みのEmojiResolverとMfmRenderConfigを構築
  ///
  /// 接続先は[client]から導出され、サーバーごとに永続ストアが分離される。
  /// [client]の所有権は呼び出し元にあり、返されたハンドルの破棄対象には含まれない。
  /// [emojiSize]は表示上の高さ、[emojiMaxWidth]は任意の最大幅として扱われる。
  /// [emojiRefreshListenable]が通知すると絵文字メタデータを再解決する。
  /// [emojiStoreFactory]を指定すると、Isarを開かずに任意のストアを利用できる。
  static Future<MfmEmojiConfigHandle> createDefault({
    required MisskeyClient client,
    String? storagePath,
    double emojiSize = 24.0,
    double? emojiMaxWidth,
    Listenable? emojiRefreshListenable,
    Widget Function(BuildContext context, String name)? fallbackBuilder,
    SyncErrorCallback? onSyncError,
    bool autoSync = true,
    MfmEmojiStoreFactory? emojiStoreFactory,
  }) async {
    final directory = (storagePath != null && storagePath.isNotEmpty)
        ? storagePath
        : (await getApplicationDocumentsDirectory()).path;

    await Directory(directory).create(recursive: true);

    final store = await (emojiStoreFactory ?? _createDefaultStore)(
      serverUrl: client.baseUrl,
      directory: directory,
    );

    final catalog = PersistentEmojiCatalog(
      source: MisskeyClientEmojiSource(client),
      store: store,
      onSyncError: onSyncError,
    );
    final resolver = MisskeyEmojiResolver(catalog);

    var effectiveRefreshListenable = emojiRefreshListenable;
    ValueNotifier<int>? autoSyncNotifier;
    Future<void>? autoSyncFuture;

    if (autoSync) {
      autoSyncNotifier = ValueNotifier(0);
      effectiveRefreshListenable = emojiRefreshListenable == null
          ? autoSyncNotifier
          : Listenable.merge([emojiRefreshListenable, autoSyncNotifier]);
      autoSyncFuture = catalog
          .sync()
          .catchError((Object error, StackTrace stackTrace) {
            if (error is Exception) {
              onSyncError?.call(error, stackTrace);
            }
          })
          .whenComplete(() => autoSyncNotifier!.value++);
      unawaited(autoSyncFuture);
    }

    final config = MfmRenderConfig(
      emojiBuilder: _createEmojiBuilder(
        resolver: resolver.call,
        cacheScope: resolver,
        emojiSize: emojiSize,
        emojiMaxWidth: emojiMaxWidth,
        emojiRefreshListenable: effectiveRefreshListenable,
        fallbackBuilder: fallbackBuilder,
      ),
    );
    return MfmEmojiConfigHandle._(
      config: config,
      lifecycle: _MfmEmojiConfigLifecycle(
        catalog: catalog,
        autoSyncFuture: autoSyncFuture,
        autoSyncNotifier: autoSyncNotifier,
      ),
    );
  }

  /// 作成済みのResolverからConfigを構築
  ///
  /// [emojiSize]は表示上の高さ、[emojiMaxWidth]は任意の最大幅として扱われる。
  /// [emojiRefreshListenable]が通知すると絵文字メタデータを再解決する。
  static MfmRenderConfig fromResolver({
    required EmojiResolver resolver,
    double emojiSize = 24.0,
    double? emojiMaxWidth,
    Listenable? emojiRefreshListenable,
    Widget Function(BuildContext context, String name)? fallbackBuilder,
  }) {
    return MfmRenderConfig(
      emojiBuilder: _createEmojiBuilder(
        resolver: resolver,
        cacheScope: resolver,
        emojiSize: emojiSize,
        emojiMaxWidth: emojiMaxWidth,
        emojiRefreshListenable: emojiRefreshListenable,
        fallbackBuilder: fallbackBuilder,
      ),
    );
  }

  static Widget Function(String name) _createEmojiBuilder({
    required EmojiResolver resolver,
    required Object cacheScope,
    required double emojiSize,
    required double? emojiMaxWidth,
    required Listenable? emojiRefreshListenable,
    required Widget Function(BuildContext context, String name)?
    fallbackBuilder,
  }) {
    return (name) => MfmCustomEmoji(
      name: name,
      resolver: resolver,
      cacheScope: cacheScope,
      size: emojiSize,
      maxWidth: emojiMaxWidth,
      refreshListenable: emojiRefreshListenable,
      fallbackBuilder: fallbackBuilder,
    );
  }

  static Future<EmojiStore> _createDefaultStore({
    required Uri serverUrl,
    required String directory,
  }) async {
    final isar = await openEmojiIsarForServer(
      serverUrl,
      directory: directory,
    );
    return IsarEmojiStore(isar, ownsIsar: true);
  }
}
