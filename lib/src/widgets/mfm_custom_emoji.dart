import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

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
    this.aspectRatio,
    this.refreshListenable,
    this.fallbackBuilder,
    this.errorBuilder,
    this.loadingBuilder,
  }) : assert(size > 0),
       assert(maxWidth == null || maxWidth > 0),
       assert(
         aspectRatio == null ||
             (aspectRatio > 0 && aspectRatio < double.infinity),
       );

  final String name;
  final EmojiResolver resolver;

  /// The displayed height of the emoji in logical pixels.
  final double size;

  /// The optional maximum displayed width of the emoji in logical pixels.
  ///
  /// When omitted, the image uses its natural aspect ratio without a width
  /// limit, matching Misskey's standard custom emoji rendering.
  final double? maxWidth;

  /// The image's known width-to-height ratio.
  ///
  /// Supplying this avoids layout changes even before the image is loaded for
  /// the first time. When omitted, decoded ratios are retained in a bounded
  /// in-memory cache and reused by later widgets for the same emoji.
  final double? aspectRatio;

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
  static final _LruCache<String, double> _aspectRatios = _LruCache(256);
  static final _LruCache<_EmojiCacheKey, String> _resolvedUrls = _LruCache(
    256,
  );
  static final Set<String> _observingUrls = {};

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

          final url = emoji.url.toString();
          _resolvedUrls[_cacheKey] = url;
          final suppliedAspectRatio = widget.aspectRatio;
          if (suppliedAspectRatio != null) {
            _aspectRatios[url] = suppliedAspectRatio;
          }
          _observeAspectRatio(context, url);

          final image = CachedNetworkImage(
            imageUrl: url,
            height: widget.size,
            fit: BoxFit.contain,
            memCacheHeight: _memCacheHeight(context),
            placeholder: (BuildContext context, String _) =>
                _loadingWidget(context, _aspectRatios[url]),
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

        return _loadingWidget(context, _knownAspectRatio);
      },
    );
  }

  _EmojiCacheKey get _cacheKey => _EmojiCacheKey(
    resolver: widget.resolver,
    name: widget.name,
  );

  double? get _knownAspectRatio {
    final suppliedAspectRatio = widget.aspectRatio;
    if (suppliedAspectRatio != null) {
      return suppliedAspectRatio;
    }
    final url = _resolvedUrls[_cacheKey];
    return url == null ? null : _aspectRatios[url];
  }

  void _observeAspectRatio(BuildContext context, String url) {
    if (_aspectRatios[url] != null || !_observingUrls.add(url)) {
      return;
    }

    final imageProvider = ResizeImage.resizeIfNeeded(
      null,
      _memCacheHeight(context),
      CachedNetworkImageProvider(url),
    );
    final stream = imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (imageInfo, _) {
        stream.removeListener(listener);
        _MfmCustomEmojiState._observingUrls.remove(url);

        final width = imageInfo.image.width;
        final height = imageInfo.image.height;
        if (width > 0 && height > 0) {
          _MfmCustomEmojiState._aspectRatios[url] = width / height;
        }
      },
      onError: (Object _, StackTrace? _) {
        stream.removeListener(listener);
        _MfmCustomEmojiState._observingUrls.remove(url);
      },
    );
    stream.addListener(listener);
  }

  int _memCacheHeight(BuildContext context) {
    final devicePixelRatio =
        MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    return (widget.size * devicePixelRatio).ceil();
  }

  Widget _loadingWidget(BuildContext context, double? aspectRatio) {
    return widget.loadingBuilder?.call(context) ??
        _defaultLoadingWidget(aspectRatio);
  }

  Widget _defaultLoadingWidget(double? aspectRatio) {
    final maxWidth = widget.maxWidth;
    final width = aspectRatio == null
        ? maxWidth ?? 0.0
        : math.min(widget.size * aspectRatio, maxWidth ?? double.infinity);

    return SizedBox(
      width: width,
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

class _EmojiCacheKey {
  const _EmojiCacheKey({
    required this.resolver,
    required this.name,
  });

  final EmojiResolver resolver;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is _EmojiCacheKey &&
      other.resolver == resolver &&
      other.name == name;

  @override
  int get hashCode => Object.hash(resolver, name);
}

class _LruCache<K, V> {
  _LruCache(this.maximumSize) : assert(maximumSize > 0);

  final int maximumSize;
  final LinkedHashMap<K, V> _values = LinkedHashMap<K, V>();

  V? operator [](K key) {
    if (!_values.containsKey(key)) {
      return null;
    }
    final value = _values.remove(key) as V;
    _values[key] = value;
    return value;
  }

  void operator []=(K key, V value) {
    _values.remove(key);
    _values[key] = value;
    if (_values.length > maximumSize) {
      _values.remove(_values.keys.first);
    }
  }
}
