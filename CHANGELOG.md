# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

## 0.5.0 - 2026-08-10

### Added
- カスタム絵文字のURL・アスペクト比キャッシュを安定した識別子で分離する `cacheScope` を追加

### Fixed
- resolverクロージャを再生成する利用方法で、判明済みのアスペクト比が再利用されない問題を修正
- アスペクト比が未知の場合に `maxWidth` をプレースホルダの推定幅として使用し、実画像の表示後に逆方向のリフローが発生する問題を修正
- 幅0のプレースホルダ内で描画できないローディングインジケータを生成する問題を修正

## 0.4.0 - 2026-08-10

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

## 0.3.0 - 2026-08-08

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

## 0.2.0 - 2026-05-16

### Added
- Nyaize（猫モード相当のテキスト変換）に対応
  - `nyaize(String)` 純粋関数を公開API（`misskey_mfm_renderer` から直接 import 可）
  - 日本語 / 英語 / 韓国語の3言語で本家 Misskey と同等の変換規則
  - `MfmRenderConfig.enableNyaize` を `true` にすると `MfmText` のテキストノードへ自動適用
  - `link` / `quote` / `plain` 配下のサブツリーは本家挙動に準拠して変換対象外
  - URL / メンション / ハッシュタグ / 各種コード / 数式 / 絵文字 / 検索ノードは構造上テキストノードを経由しないため自然と除外

## 0.1.0 - 2026-02-09

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
