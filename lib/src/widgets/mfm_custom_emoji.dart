import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

class MfmCustomEmoji extends StatefulWidget {
  const MfmCustomEmoji({
    super.key,
    required this.name,
    required this.resolver,
    this.size = 24.0,
    this.maxWidth,
    this.refreshListenable,
    this.fallbackBuilder,
    this.errorBuilder,
    this.loadingBuilder,
  }) : assert(size > 0),
       assert(maxWidth == null || maxWidth > 0);

  final String name;
  final EmojiResolver resolver;

  /// The displayed height of the emoji in logical pixels.
  final double size;

  /// The optional maximum displayed width of the emoji in logical pixels.
  ///
  /// When omitted, the image uses its natural aspect ratio without a width
  /// limit, matching Misskey's standard custom emoji rendering.
  final double? maxWidth;

  /// An optional signal that causes the emoji metadata to be resolved again.
  ///
  /// Use this when the resolver's backing catalog has been synchronized or
  /// otherwise invalidated. Successful results are retained across ordinary
  /// parent rebuilds until this signal is notified.
  final Listenable? refreshListenable;
  final Widget Function(BuildContext context, String name)? fallbackBuilder;
  final Widget Function(BuildContext context, String name, Object error)?
  errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;

  @override
  State<MfmCustomEmoji> createState() => _MfmCustomEmojiState();
}

class _MfmCustomEmojiState extends State<MfmCustomEmoji> {
  late Future<EmojiImage?> _emojiFuture;
  bool _retryOnUpdate = false;

  @override
  void initState() {
    super.initState();
    widget.refreshListenable?.addListener(_refresh);
    _resolveEmoji();
  }

  @override
  void didUpdateWidget(MfmCustomEmoji oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable?.removeListener(_refresh);
      widget.refreshListenable?.addListener(_refresh);
    }
    if (oldWidget.name != widget.name ||
        oldWidget.resolver != widget.resolver ||
        _retryOnUpdate) {
      _resolveEmoji();
    }
  }

  @override
  void dispose() {
    widget.refreshListenable?.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) {
      return;
    }
    setState(_resolveEmoji);
  }

  void _resolveEmoji() {
    final future = widget.resolver(widget.name);
    _emojiFuture = future;
    _retryOnUpdate = false;
    unawaited(
      future.then<void>(
        (emoji) {
          if (identical(_emojiFuture, future)) {
            _retryOnUpdate = emoji == null;
          }
        },
        onError: (Object _, StackTrace _) {
          if (identical(_emojiFuture, future)) {
            _retryOnUpdate = true;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EmojiImage?>(
      future: _emojiFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return _errorWidget(context, snapshot.error!);
          }

          final emoji = snapshot.data;
          if (emoji == null) {
            return _fallbackWidget(context);
          }

          final image = CachedNetworkImage(
            imageUrl: emoji.url.toString(),
            height: widget.size,
            fit: BoxFit.contain,
            memCacheHeight: _memCacheHeight(context),
            placeholder: (BuildContext context, String url) =>
                widget.loadingBuilder?.call(context) ?? _defaultLoadingWidget(),
            errorWidget: (BuildContext context, String url, Object error) =>
                _errorWidget(context, error),
            fadeInDuration: const Duration(milliseconds: 150),
            fadeOutDuration: const Duration(milliseconds: 100),
          );

          final maxWidth = widget.maxWidth;
          if (maxWidth == null) {
            return image;
          }
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: image,
          );
        }

        return widget.loadingBuilder?.call(context) ?? _defaultLoadingWidget();
      },
    );
  }

  int _memCacheHeight(BuildContext context) {
    final devicePixelRatio =
        MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    return (widget.size * devicePixelRatio).ceil();
  }

  Widget _defaultLoadingWidget() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
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
    return widget.fallbackBuilder?.call(context, widget.name) ??
        Text(
          ':${widget.name}:',
          style: DefaultTextStyle.of(
            context,
          ).style.copyWith(fontSize: widget.size * 0.6),
        );
  }

  Widget _errorWidget(BuildContext context, Object error) {
    return widget.errorBuilder?.call(context, widget.name, error) ??
        _fallbackWidget(context);
  }
}
