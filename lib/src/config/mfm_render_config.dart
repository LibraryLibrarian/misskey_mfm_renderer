import 'package:flutter/widgets.dart';

/// MFMを含むコンテンツの投稿者情報。
///
/// 本家Misskeyの`MkMfm`へ渡される`author`のうち、レンダリング時の
/// ホスト解決に必要な情報を表す。将来ほかの投稿者依存の描画情報を
/// 追加できるよう、ホスト文字列を直接設定する代わりに独立した型とする。
@immutable
class MfmAuthorContext {
  const MfmAuthorContext({this.host});

  /// 投稿者が所属するリモートホスト。
  ///
  /// ローカルユーザーの場合は`null`。
  final String? host;
}

const _authorNotSet = _AuthorNotSet();
const _localHostNotSet = _LocalHostNotSet();

class _AuthorNotSet extends MfmAuthorContext {
  const _AuthorNotSet();
}

class _LocalHostNotSet {
  const _LocalHostNotSet();
}

/// MFMレンダリングの設定クラス
class MfmRenderConfig {
  const MfmRenderConfig({
    this.baseTextStyle,
    this.enableAdvancedMfm = true,
    this.enableAnimation = true,
    this.enableNyaize = false,
    this.emojiBuilder,
    this.unicodeEmojiBuilder,
    this.onLinkTap,
    this.onMentionTap,
    this.onHashtagTap,
    this.onSearchTap,
    this.author,
    this.localHost,
    this.onClickableEvent,
    this.fontFamilyResolver,
    this.codeTheme,
    this.codeDarkTheme,
    this.brightness,
    this.showCodeBlockCopyButton,
    this.inlineCodeBgColorLight,
    this.inlineCodeBgColorDark,
  });

  /// ベースのテキストスタイル（指定しない場合はデフォルトを使用）
  final TextStyle? baseTextStyle;

  /// advancedMfm（position等の高度な機能）を有効化
  final bool enableAdvancedMfm;

  /// アニメーションを有効化（将来用）
  final bool enableAnimation;

  /// nyaize変換を有効化
  final bool enableNyaize;

  /// カスタム絵文字ビルダー
  /// nameにはコロンを除いた絵文字名が渡される（例: "wave"）
  final Widget Function(String name)? emojiBuilder;

  /// Unicode絵文字ビルダー
  /// emojiには絵文字文字列が渡される（例: "😀"）
  final Widget Function(String emoji)? unicodeEmojiBuilder;

  /// リンクタップ時のコールバック
  final void Function(String url)? onLinkTap;

  /// メンションタップ時のコールバック
  /// acctには完全なacct文字列が渡される（例: "@user@example.com"）
  final void Function(String acct)? onMentionTap;

  /// ハッシュタグタップ時のコールバック
  /// tagにはハッシュを除いたタグ名が渡される（例: "misskey"）
  final void Function(String tag)? onHashtagTap;

  /// 検索タップ時のコールバック
  final void Function(String query)? onSearchTap;

  /// MFMを含むコンテンツの投稿者情報。
  final MfmAuthorContext? author;

  /// 表示中のローカルMisskeyインスタンスのホスト。
  ///
  /// 投稿者やMFMノードにホストがない場合の解決に使用する。
  final String? localHost;

  /// clickable fn関数のイベントコールバック
  /// eventIdにはclickable.ev引数の値が渡される
  final void Function(String eventId)? onClickableEvent;

  /// フォントファミリー名を解決するカスタムリゾルバー
  /// nullの場合はデフォルトのプラットフォーム固有フォントを使用
  ///
  /// MFMの`$[font.xxx]`構文で使用されるフォントタイプ（'serif', 'monospace'等）を
  /// 実際のフォントファミリー名に変換
  ///
  /// 例: Google Fontsを使用する場合
  /// ```dart
  /// MfmRenderConfig(
  ///   fontFamilyResolver: (type) {
  ///     switch (type) {
  ///       case 'monospace':
  ///         return GoogleFonts.robotoMono().fontFamily;
  ///       case 'serif':
  ///         return GoogleFonts.notoSerif().fontFamily;
  ///       default:
  ///         return null; // デフォルトに任せる
  ///     }
  ///   },
  /// )
  /// ```
  final String? Function(String fontType)? fontFamilyResolver;

  /// コードブロックのシンタックスハイライトテーマ（ライトモード）
  /// nullの場合はデフォルトのgithubテーマを使用
  final Map<String, TextStyle>? codeTheme;

  /// コードブロックのシンタックスハイライトテーマ（ダークモード）
  /// nullの場合はcodeThemeを使用、それもnullならgithub-darkテーマを使用
  final Map<String, TextStyle>? codeDarkTheme;

  /// 現在のテーマモード（内部使用、MfmTextが自動設定）
  final Brightness? brightness;

  /// コードブロックのコピーボタンを表示するか
  /// デフォルトはtrue
  final bool? showCodeBlockCopyButton;

  /// インラインコード・数式の背景色（ライトモード）
  /// nullの場合は #F5F5F5 を使用（Misskey本家に準拠）
  final Color? inlineCodeBgColorLight;

  /// インラインコード・数式の背景色（ダークモード）
  /// nullの場合は #121212 を使用（Misskey本家に準拠）
  final Color? inlineCodeBgColorDark;

  /// 設定をコピーして新しいインスタンスを作成。
  ///
  /// [author]と[localHost]は、省略すると現在の値を維持し、`null`を
  /// 明示すると値を削除する。
  MfmRenderConfig copyWith({
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
    MfmAuthorContext? author = _authorNotSet,
    Object? localHost = _localHostNotSet,
    void Function(String eventId)? onClickableEvent,
    String? Function(String fontType)? fontFamilyResolver,
    Map<String, TextStyle>? codeTheme,
    Map<String, TextStyle>? codeDarkTheme,
    Brightness? brightness,
    bool? showCodeBlockCopyButton,
    Color? inlineCodeBgColorLight,
    Color? inlineCodeBgColorDark,
  }) {
    return MfmRenderConfig(
      baseTextStyle: baseTextStyle ?? this.baseTextStyle,
      enableAdvancedMfm: enableAdvancedMfm ?? this.enableAdvancedMfm,
      enableAnimation: enableAnimation ?? this.enableAnimation,
      enableNyaize: enableNyaize ?? this.enableNyaize,
      emojiBuilder: emojiBuilder ?? this.emojiBuilder,
      unicodeEmojiBuilder: unicodeEmojiBuilder ?? this.unicodeEmojiBuilder,
      onLinkTap: onLinkTap ?? this.onLinkTap,
      onMentionTap: onMentionTap ?? this.onMentionTap,
      onHashtagTap: onHashtagTap ?? this.onHashtagTap,
      onSearchTap: onSearchTap ?? this.onSearchTap,
      author: identical(author, _authorNotSet) ? this.author : author,
      localHost: identical(localHost, _localHostNotSet)
          ? this.localHost
          : localHost as String?,
      onClickableEvent: onClickableEvent ?? this.onClickableEvent,
      fontFamilyResolver: fontFamilyResolver ?? this.fontFamilyResolver,
      codeTheme: codeTheme ?? this.codeTheme,
      codeDarkTheme: codeDarkTheme ?? this.codeDarkTheme,
      brightness: brightness ?? this.brightness,
      showCodeBlockCopyButton:
          showCodeBlockCopyButton ?? this.showCodeBlockCopyButton,
      inlineCodeBgColorLight:
          inlineCodeBgColorLight ?? this.inlineCodeBgColorLight,
      inlineCodeBgColorDark:
          inlineCodeBgColorDark ?? this.inlineCodeBgColorDark,
    );
  }
}
