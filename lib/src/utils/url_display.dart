import 'package:punycoder/punycoder.dart';

/// URLを表示用に分解した内部モデル。
final class UrlDisplayParts {
  const UrlDisplayParts({
    required this.scheme,
    required this.host,
    required this.path,
    required this.query,
    required this.fragment,
    required this.isSelf,
    this.port,
  });

  /// `http`または`https`。
  final String scheme;

  /// percent escapeとPunycodeをUnicodeへ戻したホスト名。IPv6は角括弧を含む。
  final String host;

  /// 明示された既定値以外のport。未指定または既定portの場合はnull。
  final String? port;

  /// percent decode済みのpath。空のroot pathは`/`。
  final String path;

  /// `?`を含むpercent decode済みのquery。queryがなければ空文字。
  final String query;

  /// `#`を含むpercent decode済みのfragment。fragmentがなければ空文字。
  final String fragment;

  /// `localHost`とのhostベース比較で自インスタンス宛てと判定されたか。
  final bool isSelf;

  @override
  bool operator ==(Object other) {
    return other is UrlDisplayParts &&
        other.scheme == scheme &&
        other.host == host &&
        other.port == port &&
        other.path == path &&
        other.query == query &&
        other.fragment == fragment &&
        other.isSelf == isSelf;
  }

  @override
  int get hashCode => Object.hash(
    scheme,
    host,
    port,
    path,
    query,
    fragment,
    isSelf,
  );

  @override
  String toString() {
    return 'UrlDisplayParts('
        'scheme: $scheme, '
        'host: $host, '
        'port: $port, '
        'path: $path, '
        'query: $query, '
        'fragment: $fragment, '
        'isSelf: $isSelf'
        ')';
  }
}

/// http(s) URLを表示用パートへ分解する。
///
/// [localHost]は完全なoriginではなくhost文字列しか持たない現APIに合わせ、
/// schemeを比較しない近似判定に使う。portが含まれる場合だけURLのeffective
/// portも比較する。
UrlDisplayParts? parseUrlDisplay(String value, {String? localHost}) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      !uri.hasAuthority ||
      uri.host.isEmpty) {
    return null;
  }

  final decodedHost = _decodeHost(uri.host);
  final local = _parseLocalHost(localHost);
  final normalizedHost = _normalizeHost(decodedHost);
  final isSelf =
      local != null &&
      normalizedHost.isNotEmpty &&
      normalizedHost == local.host &&
      (local.port == null || local.port == uri.port);

  final encodedPath = uri.path.isEmpty ? '/' : uri.path;
  return UrlDisplayParts(
    scheme: uri.scheme,
    host: uri.host.contains(':') ? '[$decodedHost]' : decodedHost,
    port: uri.hasPort ? uri.port.toString() : null,
    path: _safeDecode(encodedPath),
    query: uri.query.isNotEmpty ? _safeDecode('?${uri.query}') : '',
    fragment: uri.fragment.isNotEmpty ? _safeDecode('#${uri.fragment}') : '',
    isSelf: isSelf,
  );
}

String _safeDecode(String value) {
  if (!value.contains('%') || !_hasValidPercentEscapes(value)) {
    return value;
  }
  try {
    return Uri.decodeComponent(value);
  } on FormatException {
    return value;
  }
}

bool _hasValidPercentEscapes(String value) {
  for (var index = 0; index < value.length; index++) {
    final codeUnit = value.codeUnitAt(index);
    if (codeUnit > 0x7f) {
      return false;
    }
    if (codeUnit != 0x25) {
      continue;
    }
    if (index + 2 >= value.length ||
        !_isHexDigit(value.codeUnitAt(index + 1)) ||
        !_isHexDigit(value.codeUnitAt(index + 2))) {
      return false;
    }
    index += 2;
  }
  return true;
}

bool _isHexDigit(int codeUnit) {
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x46) ||
      (codeUnit >= 0x61 && codeUnit <= 0x66);
}

String _decodeHost(String host) {
  final decoded = _safeDecode(host);
  try {
    return domainToUnicode(decoded);
  } on FormatException {
    return decoded;
  }
}

String _normalizeHost(String host) {
  var normalized = _decodeHost(host).toLowerCase();
  while (normalized.endsWith('.')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

_NormalizedLocalHost? _parseLocalHost(String? value) {
  if (value == null) {
    return null;
  }

  final authority = value.trim();
  if (authority.isEmpty) {
    return null;
  }

  String host;
  int? port;
  if (authority.startsWith('[')) {
    final closingBracket = authority.indexOf(']');
    if (closingBracket <= 1) {
      return null;
    }
    host = authority.substring(1, closingBracket);
    final remainder = authority.substring(closingBracket + 1);
    if (remainder.isNotEmpty) {
      if (!remainder.startsWith(':')) {
        return null;
      }
      port = int.tryParse(remainder.substring(1));
      if (port == null) {
        return null;
      }
    }
  } else {
    final firstColon = authority.indexOf(':');
    final lastColon = authority.lastIndexOf(':');
    if (firstColon >= 0 && firstColon == lastColon) {
      host = authority.substring(0, lastColon);
      port = int.tryParse(authority.substring(lastColon + 1));
      if (port == null) {
        return null;
      }
    } else {
      host = authority;
    }
  }

  final normalizedHost = _normalizeHost(host);
  if (normalizedHost.isEmpty) {
    return null;
  }
  return _NormalizedLocalHost(host: normalizedHost, port: port);
}

final class _NormalizedLocalHost {
  const _NormalizedLocalHost({required this.host, this.port});

  final String host;
  final int? port;
}
