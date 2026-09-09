# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Mi Light / Mi Dark準拠の `MfmColorScheme` と `MfmRenderConfig.lightColorScheme` / `darkColorScheme` を追加し、リンク、メンション、ハッシュタグ、引用、検索、border fn、unixtime、インラインコードの色をlight/dark別に設定可能にした（#50）。

### Fixed
- 引用を有限幅の親では行全幅のブロックとして表示し、前後のテキストと分離。幅が無制約の場合は自然幅にフォールバックする（#32）。
- 引用の余白を本家の `QUOTE_STYLE`（四辺margin 8px、padding 上下6px・左12px・右0px）に合わせ、幅3pxの左罫線と文字に `MfmColorScheme.fg` から累積opacityを適用するよう修正（#52）。
- 検索欄とボタンを `MfmColorScheme.divider` の枠線で隙間なく連結し、固定の青背景・白文字を削除して本家の外観に合わせた（#53）。

### Changed
- `enableAdvancedMfm` の効果範囲をx2/x3/x4の視覚的拡大、scale/position、全9種類のMFMアニメーションへ拡大。`MfmRenderConfig.useAnimation`（`enableAdvancedMfm && enableAnimation`）を追加し、advanced無効時はアニメーションも停止する。既定値は両フラグともtrueを維持する（#37）。
- advanced無効時もx2/x3/x4の公称倍率2/3/4は絵文字の描画文脈へ伝播するが、scale fnの変形・倍率伝播は停止する。アニメーション無効時は専用アニメーションwidgetを生成せず、tadaの150%フォントサイズ、rainbowの静的グラデーション、sparkleの素の子要素を維持する（#37）。
- **Breaking:** `emojiBuilder` / `unicodeEmojiBuilder` を `Widget Function(String, MfmEmojiContext)` に変更し、実効フォントサイズと累積スケールを渡すようにした（#47、#57）。
- **Breaking:** `MfmEmojiConfig.createDefault` / `fromResolver` の `emojiSize` の既定値を24px固定から実効フォントサイズの2倍（2em、引数はnull）に変更。固定サイズを維持する場合は `emojiSize: 24` を明示する（#47）。
- 絵文字の `WidgetSpan` をalphabeticベースライン揃えに変更。`MfmEmojiConfig` は `MfmCustomEmoji.baselineOffset` に本家のカスタム絵文字と同じ `vertical-align: middle` 相当の下降量（`size / 2 - フォントサイズ × 0.25`）を設定し、行の下降量にも反映する。Unicode絵文字を画像で描画する場合は高さ1.25em・下降量 `フォントサイズ × 0.25`（`vertical-align: -0.25em` 相当）を指定する（#57）。
- `scale` fnの累積倍率を `(|x| + |y|) / 2` から本家と同じ `max(|x|, |y|)` に修正。`$[scale.x=3,y=1]` の `MfmEmojiContext.scale` が2.0から3.0になり、`useOriginalSize` の判定も本家と一致する（#47）。
- `MfmEmojiContext.useOriginalSize` に原寸画像利用の判定（scale >= 2.5）を追加。`misskey_emoji` が原寸・縮小URLを区別しないため、自動切替は行わず独自ビルダー向けのヒントとして提供する（#47）。
- インラインコードの文字サイズ・色・太字などを親から継承し、余白と角丸をem相対に変更（#54）。
- **Breaking:** URL / link の既定の下線を削除して本家Misskeyと同じ下線なし表示へ変更し、リンク色を固定 `#0066CC` から選択中の `MfmColorScheme.link` へ変更（#50）。
- **Breaking:** `inlineCodeBgColorLight` / `inlineCodeBgColorDark` を削除し、インラインコード背景を `MfmColorScheme.bg` に統合。既定値はMi Light `#f9f9f9` / Mi Dark `#232323` となる。旧設定は `lightColorScheme: MfmColorScheme.light(bg: color)` / `darkColorScheme: MfmColorScheme.dark(bg: color)` へ移行する（#50）。
- 数式のカード表示・余白・中央寄せ・全幅化を廃止し、本家Misskeyと同じ装飾のない等幅テキストに変更（#51、見た目の変更）。

## [0.6.0-beta.1] - 2026-08-15

### Changed
- **Breaking:** `MfmEmojiConfig.createDefault()` で、呼び出し元が所有する `MisskeyClient` を必須化
  - 絵文字取得専用のHTTPクライアント生成を廃止し、アプリの接続設定・認証情報を再利用
  - `MfmEmojiConfigHandle.dispose()` はカタログとストアのみを破棄し、渡された `MisskeyClient` は破棄しない
- `misskey_api_core` への依存を廃止し、`misskey_client` と `misskey_emoji` 2.0の `EmojiSource` APIへ移行

### Removed
- **Breaking:** `MfmEmojiConfig.quickSetup()` / `createDefault()` から `serverUrl` 引数を削除
  - `misskey_client` 1.0.0-beta.6 で追加された `MisskeyClient.baseUrl` から導出するようになったため
  - 従来は `client` と `serverUrl` の両方を要求しており、食い違う値を渡せてしまう問題があった

- **Breaking:** `MfmEmojiConfig.quickSetup()` を削除。`serverUrl` の廃止により `createDefault()` と同一シグネチャになったため。`createDefault()` を使用すること

## [0.5.0] - 2026-08-10
### Added
- カスタム絵文字のURL・アスペクト比キャッシュを安定した識別子で分離する `cacheScope` を追加

### Fixed
- resolverクロージャを再生成する利用方法で、判明済みのアスペクト比が再利用されない問題を修正
- アスペクト比が未知の場合に `maxWidth` をプレースホルダの推定幅として使用し、実画像の表示後に逆方向のリフローが発生する問題を修正
- 幅0のプレースホルダ内で描画できないローディングインジケータを生成する問題を修正

## [0.4.0] - 2026-08-10
### Added
- `MfmEmojiConfig.quickSetup()` / `createDefault()` が返す設定に、永続ストアを解放する `dispose()` を追加
- `emojiStoreFactory` による絵文字ストアの注入に対応
- カスタム絵文字の既知アスペクト比を指定する `aspectRatio` を追加

### Changed
- `MfmEmojiConfig.quickSetup()` / `createDefault()` の戻り値を `MfmRenderConfig` のサブクラスである `MfmEmojiConfigHandle` に変更
  - `MfmRenderConfig` として扱う既存コードは変更不要
  - `copyWith()` で作成した設定はライフサイクルを共有し、いずれかを破棄するとすべて破棄済みになる

### Fixed
- `emoji_config_test` がユニットテスト内で実Isarを開き、ネイティブライブラリ不在やインスタンス名衝突で失敗する問題を修正
- カスタム絵文字の読み込み中に正方形の幅を確保して本文がリフローする問題を修正
- 判明済みのカスタム絵文字のアスペクト比を再利用し、再生成時のリフローを抑制

## [0.3.0] - 2026-08-08
### Added
- カスタム絵文字に任意の最大幅を設定する `maxWidth` / `emojiMaxWidth` を追加
- カタログ更新後にカスタム絵文字を再解決する `refreshListenable` / `emojiRefreshListenable` を追加

### Fixed
- 横長のカスタム絵文字が正方形領域内で極端に小さく表示される問題を修正
- カスタム絵文字のメモリキャッシュ生成時にアスペクト比が崩れる可能性がある問題を修正
- 親ウィジェットの再ビルド時に解決済みの同じカスタム絵文字が再解決される問題を修正
- カタログ同期後も未解決のカスタム絵文字や更新済みメタデータが反映されない問題を修正
- アニメーション関数の `speed` が0以下または1ms未満の場合に描画が失敗する問題を修正
- 負の `delay` を本家Misskeyと同様に経過済み時間として反映

## [0.2.0] - 2026-05-16
### Added
- Nyaize（猫モード相当のテキスト変換）に対応
  - `nyaize(String)` 純粋関数を公開API（`misskey_mfm_renderer` から直接 import 可）
  - 日本語 / 英語 / 韓国語の3言語で本家 Misskey と同等の変換規則
  - `MfmRenderConfig.enableNyaize` を `true` にすると `MfmText` のテキストノードへ自動適用
  - `link` / `quote` / `plain` 配下のサブツリーは本家挙動に準拠して変換対象外
  - URL / メンション / ハッシュタグ / 各種コード / 数式 / 絵文字 / 検索ノードは構造上テキストノードを経由しないため自然と除外

## [0.1.0] - 2026-02-09
Initial release of misskey_mfm_renderer - A Flutter widget library for rendering Misskey MFM (Misskey Flavored Markdown) content.

### Added

#### Text Formatting
- Bold (`**text**`)
- Italic (`*text*` / `<i>text</i>`)
- Strike (`~~text~~`)
- Small (`<small>text</small>`)
- Plain (`<plain>text</plain>`)

#### Block Elements
- Quote (`> text`)
- Center (`<center>text</center>`)
- Code Block (` ```code``` `)
- Inline Code (`` `code` ``)
- Math Block (`\[ formula \]`) - Displayed as plain text
- Math Inline (`\( formula \)`) - Displayed as plain text

#### Links & References
- URL (auto-detection)
- Link (`[label](url)`)
- Mention (`@user@host`)
- Hashtag (`#hashtag`)
- Search (`keyword Search`)

#### Emoji Support
- Unicode Emoji
- Custom Emoji with `misskey_emoji` integration
  - Automatic emoji metadata resolution
  - Image caching with `cached_network_image`
  - Fallback display for unavailable emojis
  - Animated emoji support (GIF, APNG, WebP)

#### fn Functions - Size
- x2 (`$[x2 text]`)
- x3 (`$[x3 text]`)
- x4 (`$[x4 text]`)

#### fn Functions - Transform
- Flip (`$[flip text]` / `$[flip.h,v text]`)
  - Horizontal flip
  - Vertical flip
  - Combined flip
- Rotate (`$[rotate.deg=45 text]`)
- Scale (`$[scale.x=2,y=2 text]`)
- Position (`$[position.x=1,y=1 text]`)

#### fn Functions - Style
- Foreground color (`$[fg.color=ff0000 text]`)
- Background color (`$[bg.color=00ff00 text]`)
- Border (`$[border.color=0000ff text]`)
- Font (`$[font.serif text]` / `$[font.monospace text]` / `$[font.cursive text]`)

#### fn Functions - Special
- Blur (`$[blur text]`)
- Ruby (furigana) (`$[ruby kanji furigana]`)
- Unixtime (`$[unixtime 1234567890]`)

#### fn Functions - Animation
- Spin (`$[spin text]` / `$[spin.x text]` / `$[spin.y text]`)
- Jump (`$[jump text]`)
- Bounce (`$[bounce text]`)
- Shake (`$[shake text]`)
- Twitch (`$[twitch text]`)
- Jelly (`$[jelly text]`)
- Tada (`$[tada text]`)
- Rainbow (`$[rainbow text]`)
- Sparkle (`$[sparkle text]`)

#### Configuration Options
- `MfmRenderConfig` for customizing rendering behavior
- Custom emoji builder support
- Unicode emoji builder support
- Callback support for links, mentions, hashtags, and search
- Custom font family resolver
- Text style customization
- Advanced MFM control (enable/disable position, etc.)
- Inline code/math background color customization

#### Helpers
- `MfmEmojiConfig.quickSetup()` for easy emoji configuration

#### Known Limitations
- **Math Rendering**: LaTeX formulas (`\(formula\)` and `\[formula\]`) are displayed as plain text. Math rendering support is planned for future releases.
- **Nyaize**: Text transformation feature is not yet implemented.
- **Font Types**: Some font types (emoji, math) fall back to default fonts due to platform limitations.
- **Text Selection**: Not supported by design for visual fidelity. If copy functionality is needed, implement it at the app level using the original MFM text.
- **Scale Limits**: Scale function is limited to 5x maximum (same as Misskey's official implementation for security reasons).
