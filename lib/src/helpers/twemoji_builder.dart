import 'package:flutter/widgets.dart';

import '../config/mfm_render_config.dart';
import '../widgets/mfm_emoji_baseline.dart';

/// Opt-in Twemoji PNG rendering for `MfmRenderConfig.unicodeEmojiBuilder`.
///
/// Supply an image source explicitly; there is no default CDN or bundled asset
/// set. Only sequences recognized by the installed MFM parser reach this helper
/// during normal rendering. This is not an emoji validator or a guarantee that
/// every sequence has a corresponding Twemoji asset.
@immutable
class MfmTwemojiBuilder {
  /// Creates a builder whose callback receives a lowercase PNG filename.
  ///
  /// For example, `❤️` requests `2764.png`. Variation selector FE0F is removed
  /// only when the sequence has no ZWJ. Empty input, FE0E text presentation and
  /// input containing only FE0F fall back without calling [imageProvider].
  ///
  /// The synchronous callback may run again on ordinary builds. Return stable
  /// image-provider keys. A null result displays the original Unicode; callback
  /// exceptions propagate, while image loading and decoding errors fall back.
  const MfmTwemojiBuilder({
    required ImageProvider<Object>? Function(String assetName) imageProvider,
  }) : _imageProvider = imageProvider;

  /// Uses [NetworkImage] and Flutter's cache for an explicit PNG directory.
  ///
  /// [baseUrl] must be an absolute HTTP(S) URL with a host, without user info,
  /// query or fragment (including empty markers). Its encoded directory path
  /// and port are preserved, with a trailing slash added when necessary.
  /// Construction does not fetch images. There is no persistent cache, retry
  /// policy or fallback CDN. Platform networking and web CORS rules apply.
  factory MfmTwemojiBuilder.network({required Uri baseUrl}) {
    if (!baseUrl.isAbsolute ||
        (baseUrl.scheme != 'http' && baseUrl.scheme != 'https') ||
        baseUrl.host.isEmpty ||
        baseUrl.userInfo.isNotEmpty ||
        baseUrl.authority.contains('@') ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'Expected an HTTP(S) directory URL '
            'without user info, query or fragment',
      );
    }
    final source = baseUrl.toString();
    final directory = source.endsWith('/') ? source : '$source/';
    return MfmTwemojiBuilder(
      imageProvider: (assetName) => NetworkImage('$directory$assetName'),
    );
  }

  final ImageProvider<Object>? Function(String assetName) _imageProvider;

  /// Builds a passive inline image with the original Unicode as its label.
  ///
  /// Images and transparent pending placeholders are 1.25em square, descending
  /// 0.25em below the baseline. Missing or failed images use the full context
  /// text style and natural text baseline without additional text scaling.
  /// Fallback remains a widget inside the renderer's WidgetSpan, not a native
  /// TextSpan, so surrounding shaping, wrapping and text extraction can differ.
  /// The parser may split FE0E into a separate node invisible to this method.
  Widget build(String emoji, MfmEmojiContext context) {
    final runes = emoji.runes.toList();
    final codePoints = runes.contains(0x200d)
        ? runes
        : runes.where((rune) => rune != 0xfe0f);
    final asset = codePoints.map((rune) => rune.toRadixString(16)).join('-');
    final provider = runes.contains(0xfe0e) || asset.isEmpty
        ? null
        : _imageProvider('$asset.png');
    return _Twemoji(emoji: emoji, emojiContext: context, provider: provider);
  }
}

class _Twemoji extends StatelessWidget {
  const _Twemoji({
    required this.emoji,
    required this.emojiContext,
    required this.provider,
  });

  final String emoji;
  final MfmEmojiContext emojiContext;
  final ImageProvider<Object>? provider;

  Widget _fallback() => Text(
    emoji,
    style: emojiContext.textStyle ?? TextStyle(fontSize: emojiContext.fontSize),
    textScaler: TextScaler.noScaling,
  );

  @override
  Widget build(BuildContext context) {
    final imageProvider = provider;
    final size = emojiContext.fontSize * 1.25;
    return Semantics(
      label: emoji,
      child: ExcludeSemantics(
        child: imageProvider == null
            ? _fallback()
            : Image(
                key: ValueKey((emoji, imageProvider)),
                image: imageProvider,
                width: size,
                height: size,
                fit: BoxFit.contain,
                // Explicitly avoid retaining a previous logical image.
                // ignore: avoid_redundant_argument_values
                gaplessPlayback: false,
                frameBuilder: (context, child, frame, synchronous) =>
                    MfmEmojiBaseline(
                      offset: emojiContext.fontSize * 0.25,
                      child: frame == null
                          ? SizedBox(width: size, height: size)
                          : child,
                    ),
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
      ),
    );
  }
}
