import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:misskey_emoji/misskey_emoji.dart';

class MfmCustomEmoji extends StatefulWidget {
  const MfmCustomEmoji({
    super.key,
    required this.name,
    this.resolver,
    this.url,
    this.size = 24.0,
    this.baselineOffset,
    this.maxWidth,
    this.aspectRatio,
    this.cacheScope,
    this.refreshListenable,
    this.fallbackBuilder,
    this.fallbackTextStyle,
    this.errorBuilder,
    this.loadingBuilder,
  }) : assert(resolver != null || url != null),
       assert(size > 0),
       assert(
         baselineOffset == null ||
             (baselineOffset > double.negativeInfinity &&
                 baselineOffset < double.infinity),
       ),
       assert(maxWidth == null || maxWidth > 0),
       assert(
         aspectRatio == null ||
             (aspectRatio > 0 && aspectRatio < double.infinity),
       );

  final String name;

  /// Resolves the emoji when [url] is omitted.
  final EmojiResolver? resolver;

  /// A direct image URL, taking precedence over [resolver].
  ///
  /// Image errors use [errorBuilder] or the shortcode fallback; they never
  /// retry through [resolver]. At least one of [url] or [resolver] is required.
  final Uri? url;

  /// The displayed height of the emoji in logical pixels.
  final double size;

  /// Distance in logical pixels from the baseline down to the emoji box bottom.
  ///
  /// Misskey aligns a custom emoji with `vertical-align: middle`, so pass
  /// `size / 2 - context.fontSize * 0.25` from a custom emoji builder. For a
  /// Unicode emoji image, Misskey uses a 1.25em height with
  /// `vertical-align: -0.25em`, so pass `context.fontSize * 0.25` instead.
  ///
  /// Negative values are allowed and place the box bottom above the baseline,
  /// which happens with a small fixed [size] and a large font size. When
  /// omitted, the child's natural baseline is used. MfmEmojiConfig supplies the
  /// custom emoji value automatically, even with a fixed emojiSize.
  /// Standard shortcode fallback text always uses its natural baseline.
  final double? baselineOffset;

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

  /// A stable namespace used to scope cached URLs and aspect ratios.
  ///
  /// Widgets sharing this value must resolve the same [name] to the same URL
  /// for a given backing-data state. Include every captured input that can
  /// affect the result, such as a host or account. A Dart record such as
  /// `(resolverOwner, preferredHost)` can combine multiple inputs.
  ///
  /// When omitted, [resolver] itself (or [url] for URL-only images) is used.
  /// Direct [url] values also separate cache entries within the same scope.
  /// This value only controls cache reuse; changing [resolver] or [url] still
  /// causes the emoji to be resolved again.
  final Object? cacheScope;

  /// An optional signal that causes the emoji metadata to be resolved again.
  ///
  /// Use this when the resolver's backing catalog has been synchronized or
  /// otherwise invalidated. Successful results are retained across ordinary
  /// parent rebuilds until this signal is notified.
  final Listenable? refreshListenable;

  /// Style for the standard `:name:` fallback, independent of image [size].
  ///
  /// Defaults to DefaultTextStyle at its natural 1em size and alphabetic
  /// baseline. [baselineOffset] applies only to images and custom builders.
  final TextStyle? fallbackTextStyle;

  final Widget Function(BuildContext context, String name)? fallbackBuilder;
  final Widget Function(BuildContext context, String name, Object error)?
  errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Clears the process-wide custom emoji layout caches.
  @visibleForTesting
  static void debugClearCaches() => _MfmCustomEmojiState._debugClearCaches();

  @override
  State<MfmCustomEmoji> createState() => _MfmCustomEmojiState();
}

class _MfmCustomEmojiState extends State<MfmCustomEmoji> {
  static final _LruCache<String, double> _aspectRatios = _LruCache(256);
  static final _LruCache<_EmojiCacheKey, String> _resolvedUrls = _LruCache(
    256,
  );
  static final Set<String> _observingUrls = {};
  static int _cacheGeneration = 0;

  late Future<Uri?> _emojiFuture;
  bool _retryOnUpdate = false;

  // Image callbacks rebuild below this State. Notify the render wrapper
  // directly when the error branch changes its baseline policy, without
  // rebuilding or re-resolving the image during a descendant build.
  final ValueNotifier<bool> _imageUsesNaturalBaseline = ValueNotifier(false);

  static void _debugClearCaches() {
    _cacheGeneration++;
    _aspectRatios.clear();
    _resolvedUrls.clear();
    _observingUrls.clear();
  }

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
        oldWidget.url != widget.url ||
        _cacheScopeOf(oldWidget) != _cacheScopeOf(widget) ||
        _retryOnUpdate) {
      _resolveEmoji();
    }
  }

  @override
  void dispose() {
    widget.refreshListenable?.removeListener(_refresh);
    _imageUsesNaturalBaseline.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) {
      return;
    }
    setState(_resolveEmoji);
  }

  void _resolveEmoji() {
    final url = widget.url;
    final future = url != null
        ? Future<Uri?>.value(url)
        : widget.resolver!(widget.name).then((emoji) => emoji?.url);
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
    return FutureBuilder<Uri?>(
      future: _emojiFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return _errorWidget(context, snapshot.error!);
          }

          final resolvedUrl = snapshot.data;
          if (resolvedUrl == null) {
            return _fallbackWidget(context);
          }

          final url = resolvedUrl.toString();
          _resolvedUrls[_cacheKey] = url;
          final suppliedAspectRatio = widget.aspectRatio;
          if (suppliedAspectRatio != null) {
            _aspectRatios[url] = suppliedAspectRatio;
          }
          _observeAspectRatio(context, url);

          return _withBaseline(
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              imageBuilder: (context, provider) {
                _imageUsesNaturalBaseline.value = false;
                return _constrainImage(
                  Image(
                    image: ResizeImage.resizeIfNeeded(
                      null,
                      _memCacheHeight(context),
                      provider,
                    ),
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                );
              },
              memCacheHeight: _memCacheHeight(context),
              placeholder: (BuildContext context, String _) {
                _imageUsesNaturalBaseline.value = false;
                return _constrainImage(
                  _loadingWidget(
                    context,
                    _aspectRatios[url],
                    imageLoading: true,
                  ),
                );
              },
              errorWidget: (BuildContext context, String url, Object error) {
                _imageUsesNaturalBaseline.value =
                    widget.errorBuilder == null &&
                    widget.fallbackBuilder == null;
                return _errorWidget(context, error, imageError: true);
              },
              fadeInDuration: const Duration(milliseconds: 150),
              fadeOutDuration: const Duration(milliseconds: 100),
            ),
            useNaturalBaseline: _imageUsesNaturalBaseline,
          );
        }

        return _loadingWidget(context, _knownAspectRatio);
      },
    );
  }

  // Keep image constraints inside each branch. The baseline instead wraps the
  // whole cross-fade, whose height can differ from either child's height.
  // Standard error text opts out of that image baseline.
  Widget _constrainImage(Widget child) {
    final maxWidth = widget.maxWidth;
    return maxWidth == null
        ? child
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          );
  }

  Widget _withBaseline(
    Widget child, {
    ValueListenable<bool>? useNaturalBaseline,
  }) {
    final offset = widget.baselineOffset;
    return offset == null
        ? child
        : _EmojiBaseline(
            offset: offset,
            useNaturalBaseline: useNaturalBaseline,
            child: child,
          );
  }

  _EmojiCacheKey get _cacheKey => _EmojiCacheKey(
    scope: _cacheScopeOf(widget),
    name: widget.name,
    url: widget.url,
  );

  Object _cacheScopeOf(MfmCustomEmoji target) =>
      target.cacheScope ?? target.resolver ?? target.url!;

  double? get _knownAspectRatio {
    final suppliedAspectRatio = widget.aspectRatio;
    if (suppliedAspectRatio != null) {
      return suppliedAspectRatio;
    }
    final url = widget.url?.toString() ?? _resolvedUrls[_cacheKey];
    return url == null ? null : _aspectRatios[url];
  }

  void _observeAspectRatio(BuildContext context, String url) {
    if (_aspectRatios[url] != null || !_observingUrls.add(url)) {
      return;
    }
    final cacheGeneration = _cacheGeneration;

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
        if (cacheGeneration != _MfmCustomEmojiState._cacheGeneration) {
          return;
        }
        _MfmCustomEmojiState._observingUrls.remove(url);

        final width = imageInfo.image.width;
        final height = imageInfo.image.height;
        if (width > 0 && height > 0) {
          _MfmCustomEmojiState._aspectRatios[url] = width / height;
        }
      },
      onError: (Object _, StackTrace? _) {
        stream.removeListener(listener);
        if (cacheGeneration != _MfmCustomEmojiState._cacheGeneration) {
          return;
        }
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

  Widget _loadingWidget(
    BuildContext context,
    double? aspectRatio, {
    bool imageLoading = false,
  }) {
    final child =
        widget.loadingBuilder?.call(context) ??
        _defaultLoadingWidget(aspectRatio);
    return imageLoading ? child : _withBaseline(child);
  }

  Widget _defaultLoadingWidget(double? aspectRatio) {
    if (aspectRatio == null) {
      return SizedBox(width: 0, height: widget.size);
    }

    final maxWidth = widget.maxWidth;
    final width = math.min(
      widget.size * aspectRatio,
      maxWidth ?? double.infinity,
    );

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

  Widget _fallbackWidget(BuildContext context, {bool imageError = false}) {
    final custom = widget.fallbackBuilder?.call(context, widget.name);
    if (custom != null) {
      return imageError ? _constrainImage(custom) : _withBaseline(custom);
    }
    return Text(
      ':${widget.name}:',
      style: widget.fallbackTextStyle ?? DefaultTextStyle.of(context).style,
    );
  }

  Widget _errorWidget(
    BuildContext context,
    Object error, {
    bool imageError = false,
  }) {
    final custom = widget.errorBuilder?.call(context, widget.name, error);
    if (custom != null) {
      return imageError ? _constrainImage(custom) : _withBaseline(custom);
    }
    return _fallbackWidget(context, imageError: imageError);
  }
}

// Baseline shifts its child to an existing baseline; it does not assign an
// image a baseline above its bottom. Report a baseline without moving or
// resizing the box, so the paragraph reserves the descent as well as ascent.
class _EmojiBaseline extends SingleChildRenderObjectWidget {
  const _EmojiBaseline({
    required this.offset,
    this.useNaturalBaseline,
    required super.child,
  });

  final double offset;
  final ValueListenable<bool>? useNaturalBaseline;

  @override
  _RenderEmojiBaseline createRenderObject(BuildContext context) =>
      _RenderEmojiBaseline(offset, useNaturalBaseline);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEmojiBaseline renderObject,
  ) {
    renderObject
      ..offset = offset
      ..useNaturalBaseline = useNaturalBaseline;
  }
}

class _RenderEmojiBaseline extends RenderProxyBox {
  _RenderEmojiBaseline(this._offset, this._useNaturalBaseline);

  double _offset;
  ValueListenable<bool>? _useNaturalBaseline;

  ValueListenable<bool>? get useNaturalBaseline => _useNaturalBaseline;

  set useNaturalBaseline(ValueListenable<bool>? value) {
    if (identical(_useNaturalBaseline, value)) return;
    if (attached) _useNaturalBaseline?.removeListener(markNeedsLayout);
    _useNaturalBaseline = value;
    if (attached) _useNaturalBaseline?.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _useNaturalBaseline?.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _useNaturalBaseline?.removeListener(markNeedsLayout);
    super.detach();
  }

  double get offset => _offset;

  set offset(double value) {
    if (_offset == value) return;
    _offset = value;
    markNeedsLayout();
  }

  late double _baseline;

  @override
  void performLayout() {
    super.performLayout();
    _baseline = size.height - _offset;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _useNaturalBaseline?.value ?? false
      ? super.computeDistanceToActualBaseline(baseline)
      : _baseline;

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => _useNaturalBaseline?.value ?? false
      ? super.computeDryBaseline(constraints, baseline)
      : getDryLayout(constraints).height - _offset;
}

class _EmojiCacheKey {
  const _EmojiCacheKey({
    required this.scope,
    required this.name,
    required this.url,
  });

  final Object scope;
  final String name;
  final Uri? url;

  @override
  bool operator ==(Object other) =>
      other is _EmojiCacheKey &&
      other.scope == scope &&
      other.name == name &&
      other.url == url;

  @override
  int get hashCode => Object.hash(scope, name, url);
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

  void clear() => _values.clear();
}
