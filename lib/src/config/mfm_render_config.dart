import 'package:flutter/widgets.dart';

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
    this.fontFamilyResolver,
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

  /// 設定をコピーして新しいインスタンスを作成
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
    String? Function(String fontType)? fontFamilyResolver,
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
      fontFamilyResolver: fontFamilyResolver ?? this.fontFamilyResolver,
    );
  }
}
