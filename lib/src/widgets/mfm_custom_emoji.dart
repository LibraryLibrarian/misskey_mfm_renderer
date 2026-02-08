import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

class MfmCustomEmoji extends StatelessWidget {
  const MfmCustomEmoji({
    super.key,
    required this.name,
    required this.resolver,
    this.size = 24.0,
    this.fallbackBuilder,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String name;
  final EmojiResolver resolver;
  final double size;
  final Widget Function(BuildContext context, String name)? fallbackBuilder;
  final Widget Function(BuildContext context, String name, Object error)?
  errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EmojiImage?>(
      future: resolver(name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return _errorWidget(context, snapshot.error!);
          }

          final emoji = snapshot.data;
          if (emoji == null) {
            return _fallbackWidget(context);
          }

          return CachedNetworkImage(
            imageUrl: emoji.url.toString(),
            width: size,
            height: size,
            fit: BoxFit.contain,
            memCacheWidth: _memCacheSize,
            memCacheHeight: _memCacheSize,
            placeholder: (BuildContext context, String url) =>
                loadingBuilder?.call(context) ?? _defaultLoadingWidget(),
            errorWidget: (BuildContext context, String url, Object error) =>
                _errorWidget(context, error),
            fadeInDuration: const Duration(milliseconds: 150),
            fadeOutDuration: const Duration(milliseconds: 100),
          );
        }

        return loadingBuilder?.call(context) ?? _defaultLoadingWidget();
      },
    );
  }

  int? get _memCacheSize => size > 64 ? (size * 2).toInt() : null;

  Widget _defaultLoadingWidget() {
    return SizedBox(
      width: size,
      height: size,
      child: const Center(
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _fallbackWidget(BuildContext context) {
    return fallbackBuilder?.call(context, name) ??
        Text(
          ':$name:',
          style: DefaultTextStyle.of(
            context,
          ).style.copyWith(fontSize: size * 0.6),
        );
  }

  Widget _errorWidget(BuildContext context, Object error) {
    return errorBuilder?.call(context, name, error) ?? _fallbackWidget(context);
  }
}
