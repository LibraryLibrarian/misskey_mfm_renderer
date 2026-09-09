import 'package:flutter/widgets.dart';

import 'mfm_color_scheme.dart';

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

/// 絵文字ビルダーに渡す描画文脈。
@immutable
class MfmEmojiContext {
  const MfmEmojiContext({required this.fontSize, required this.scale});

  /// 現在の実効フォントサイズ（px）。本家のem計算の基準。
  final double fontSize;

  /// x2/x3/x4/scale fnの累積倍率。tadaやsmallのサイズ変更は含まない。
  ///
  /// scale fnは描画時の変形なので、[fontSize]には反映されない。
  final double scale;

  /// 本家と同じく2.5倍以上で原寸画像を使うべきか。
  ///
  /// 原寸URLを取得できる独自ビルダーで利用するためのヒント。
  /// 現在のmisskey_emojiの解決結果は原寸・縮小URLを区別しないため、
  /// MfmEmojiConfigによる自動切替は行わない。
  bool get useOriginalSize => scale >= 2.5;

  @override
  bool operator ==(Object other) =>
      other is MfmEmojiContext &&
      other.fontSize == fontSize &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(fontSize, scale);

  @override
  String toString() => 'MfmEmojiContext(fontSize: $fontSize, scale: $scale)';
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
    String? searchButtonLabel,
    this.useLocaleSearchButtonLabel = false,
    this.onClickableEvent,
    this.fontFamilyResolver,
    this.codeTheme,
    this.codeDarkTheme,
    this.lightColorScheme,
    this.darkColorScheme,
    this.brightness,
    this.showCodeBlockCopyButton,
    this.onCodeCopied,
    this.codeCopyTooltip,
    this.codeCopiedMessage,
  }) : searchButtonLabel = useLocaleSearchButtonLabel
           ? null
           : searchButtonLabel;

  /// ベースのテキストスタイル（指定しない場合はデフォルトを使用）
  final TextStyle? baseTextStyle;

  /// advancedMfm（position等の高度な機能）を有効化
  final bool enableAdvancedMfm;

  /// アニメーションを有効化（将来用）
  final bool enableAnimation;

  /// nyaize変換を有効化
  final bool enableNyaize;

  /// カスタム絵文字ビルダー
  /// nameにはコロンを除いた絵文字名が渡される（例: "wave"）。
  /// context.fontSizeを基準に高さを決める（本家の既定は2em）。
  /// ビルダーの結果はalphabeticベースラインに揃える。画像の下降量は
  /// ビルダー側で設定する（MfmCustomEmoji.baselineOffsetなど）。
  /// 本家のカスタム絵文字は`vertical-align: middle`なので、下降量は
  /// `高さ / 2 - context.fontSize * 0.25`が相当する。
  final Widget Function(String name, MfmEmojiContext context)? emojiBuilder;

  /// Unicode絵文字ビルダー
  /// emojiには絵文字文字列が渡される（例: "😀"）。
  /// 未指定時はネイティブの文字として描画する。Twemoji等の画像表示は
  /// このビルダーで実装し、context.fontSizeを高さの基準に使う
  /// （本家の既定は高さ1.25emで`vertical-align: -0.25em`。下降量は
  /// `context.fontSize * 0.25`が相当する）。
  /// ビルダーの結果はalphabeticベースラインに揃える。
  final Widget Function(String emoji, MfmEmojiContext context)?
  unicodeEmojiBuilder;

  /// リンクタップ時のコールバック
  final void Function(String url)? onLinkTap;

  /// メンションタップ時のコールバック。
  ///
  /// [author]または[localHost]からホストを解決できる場合、acctには
  /// 完全な文字列が渡される（例: "@user@example.com"）。解決情報がなく、
  /// 元のメンションにもホストがない場合はraw acct（例: "@user"）を渡す。
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
  /// 投稿者やMFMノードにホストがない場合の解決と、URLのself判定に使用する。
  /// URLではschemeを比較できないためhostベースの近似となり、portを含めた場合だけ
  /// URLのeffective portも比較する。
  final String? localHost;

  /// 検索ボタンのラベル
  ///
  /// nullの場合は現在のロケールから解決し、解決できない場合は"Search"を使用
  final String? searchButtonLabel;

  /// 継承または設定済みの[searchButtonLabel]を解除し、現在のロケールを使うか
  ///
  /// trueは[searchButtonLabel]より優先され、[searchButtonLabel]はnullになる。
  final bool useLocaleSearchButtonLabel;

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

  /// ライトモードで使用するMFM配色。
  ///
  /// nullの場合は継承設定を優先し、最終的に[MfmColorScheme.light]を使用する。
  final MfmColorScheme? lightColorScheme;

  /// ダークモードで使用するMFM配色。
  ///
  /// nullの場合は継承設定を優先し、最終的に[MfmColorScheme.dark]を使用する。
  final MfmColorScheme? darkColorScheme;

  /// 使用するテーマモード。
  ///
  /// nullの場合はMaterial、Cupertino、プラットフォームの順に周囲の設定から解決する。
  final Brightness? brightness;

  /// コードブロックのコピーボタンを表示するか
  /// デフォルトはtrue
  final bool? showCodeBlockCopyButton;

  /// コードをクリップボードへコピーした後のコールバック。
  ///
  /// codeにはコピーしたコード全文が渡される。指定時は既定のSnackBarを表示しない。
  /// nullの場合はScaffoldMessengerが存在するときだけSnackBarを表示する。
  final void Function(String code)? onCodeCopied;

  /// コードブロックのコピーボタンのアクセシビリティラベル。
  ///
  /// コピーボタンはMaterial依存を避けるためツールチップを表示せず、
  /// この文言はSemanticsのラベルとして機能する。
  /// nullの場合は現在のロケールが日本語なら「コピー」、それ以外は"Copy"を使用。
  final String? codeCopyTooltip;

  /// コードコピー完了時の既定のSnackBarメッセージ。
  ///
  /// nullの場合は現在のロケールが日本語なら「コードをコピーしました」、
  /// それ以外は"Copied to clipboard"を使用。[onCodeCopied]指定時は使用しない。
  final String? codeCopiedMessage;

  /// 設定をコピーして新しいインスタンスを作成。
  ///
  /// {@template mfm_render_config_copy_with_mention_context}
  /// [author]と[localHost]は、`null`または省略時に現在の値を維持する。
  /// 値を削除する場合は、対応する[clearAuthor]または[clearLocalHost]を
  /// `true`にする。値の指定と削除を同時に要求すると[ArgumentError]を投げる。
  /// {@endtemplate}
  MfmRenderConfig copyWith({
    TextStyle? baseTextStyle,
    bool? enableAdvancedMfm,
    bool? enableAnimation,
    bool? enableNyaize,
    Widget Function(String name, MfmEmojiContext context)? emojiBuilder,
    Widget Function(String emoji, MfmEmojiContext context)? unicodeEmojiBuilder,
    void Function(String url)? onLinkTap,
    void Function(String acct)? onMentionTap,
    void Function(String tag)? onHashtagTap,
    void Function(String query)? onSearchTap,
    MfmAuthorContext? author,
    String? localHost,
    bool clearAuthor = false,
    bool clearLocalHost = false,
    String? searchButtonLabel,
    bool? useLocaleSearchButtonLabel,
    void Function(String eventId)? onClickableEvent,
    String? Function(String fontType)? fontFamilyResolver,
    Map<String, TextStyle>? codeTheme,
    Map<String, TextStyle>? codeDarkTheme,
    MfmColorScheme? lightColorScheme,
    MfmColorScheme? darkColorScheme,
    Brightness? brightness,
    bool? showCodeBlockCopyButton,
    void Function(String code)? onCodeCopied,
    String? codeCopyTooltip,
    String? codeCopiedMessage,
  }) {
    if (clearAuthor && author != null) {
      throw ArgumentError.value(
        author,
        'author',
        'clearAuthorがtrueの場合は指定できません',
      );
    }
    if (clearLocalHost && localHost != null) {
      throw ArgumentError.value(
        localHost,
        'localHost',
        'clearLocalHostがtrueの場合は指定できません',
      );
    }

    final effectiveUseLocaleSearchButtonLabel =
        useLocaleSearchButtonLabel ??
        (searchButtonLabel == null && this.useLocaleSearchButtonLabel);
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
      author: clearAuthor ? null : author ?? this.author,
      localHost: clearLocalHost ? null : localHost ?? this.localHost,
      searchButtonLabel: effectiveUseLocaleSearchButtonLabel
          ? null
          : searchButtonLabel ?? this.searchButtonLabel,
      useLocaleSearchButtonLabel: effectiveUseLocaleSearchButtonLabel,
      onClickableEvent: onClickableEvent ?? this.onClickableEvent,
      fontFamilyResolver: fontFamilyResolver ?? this.fontFamilyResolver,
      codeTheme: codeTheme ?? this.codeTheme,
      codeDarkTheme: codeDarkTheme ?? this.codeDarkTheme,
      lightColorScheme: lightColorScheme ?? this.lightColorScheme,
      darkColorScheme: darkColorScheme ?? this.darkColorScheme,
      brightness: brightness ?? this.brightness,
      showCodeBlockCopyButton:
          showCodeBlockCopyButton ?? this.showCodeBlockCopyButton,
      onCodeCopied: onCodeCopied ?? this.onCodeCopied,
      codeCopyTooltip: codeCopyTooltip ?? this.codeCopyTooltip,
      codeCopiedMessage: codeCopiedMessage ?? this.codeCopiedMessage,
    );
  }
}
