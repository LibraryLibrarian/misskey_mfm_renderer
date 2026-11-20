import 'package:punycoder/punycoder.dart';

import '../config/mfm_render_config.dart';

/// Strict mention authority, separate from the URL display heuristic.
final class MentionAuthority {
  const MentionAuthority(this.display, this.identity, this.port);

  final String display;
  final String identity;
  final int? port;

  bool matches(MentionAuthority other) =>
      identity == other.identity && port == other.port;
}

MentionAuthority? parseMentionAuthority(String value) {
  if (value.isEmpty || RegExp(r'[\s/@?#%\\]').hasMatch(value)) return null;
  String host;
  String? portText;
  String identity;
  if (value.startsWith('[')) {
    final end = value.indexOf(']');
    if (end < 2) return null;
    host = value.substring(0, end + 1);
    final suffix = value.substring(end + 1);
    if (suffix.isNotEmpty) {
      if (!suffix.startsWith(':')) return null;
      portText = suffix.substring(1);
    }
    try {
      identity = Uri.parseIPv6Address(value.substring(1, end)).join('.');
    } on FormatException {
      return null;
    }
  } else {
    final parts = value.split(':');
    if (parts.length > 2) return null;
    host = parts.first;
    if (parts.length == 2) portText = parts.last;
    if (host.endsWith('.')) host = host.substring(0, host.length - 1);
    if (host.isEmpty) return null;
    try {
      host = domainToUnicode(host);
      final labels = host.split('.');
      if (labels.any(
        (label) =>
            label.isEmpty ||
            label.startsWith('-') ||
            label.endsWith('-') ||
            !RegExp(r'^[\p{L}\p{N}\p{M}-]+$', unicode: true).hasMatch(label),
      )) {
        return null;
      }
      final ascii = domainToAscii(host);
      if (ascii.length > 253 || ascii.split('.').any((s) => s.length > 63)) {
        return null;
      }
      if (RegExp(r'^[0-9.]+$').hasMatch(host)) {
        identity = Uri.parseIPv4Address(host).join('.');
      } else {
        identity = host.toLowerCase();
      }
    } on FormatException {
      return null;
    }
  }
  int? port;
  if (portText != null) {
    if (!RegExp(r'^[0-9]+$').hasMatch(portText)) return null;
    port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) return null;
  }
  return MentionAuthority(
    '$host${portText == null ? '' : ':$portText'}',
    identity,
    port,
  );
}

String? _nonEmpty(String? value) =>
    value == null || value.isEmpty ? null : value;

/// Validate after inheritance, even without mentions or in text mode.
void validateMentionConfig(MfmRenderConfig config) {
  final options = config.mentionOptions;
  final rawOrigin = options?.localOrigin;
  if (rawOrigin != null) {
    final origin = Uri.tryParse(rawOrigin);
    final rawAuthority = mentionOriginAuthority(rawOrigin);
    final authority = rawAuthority == null
        ? null
        : parseMentionAuthority(rawAuthority);
    if (origin == null ||
        !origin.isAbsolute ||
        (origin.scheme != 'http' && origin.scheme != 'https') ||
        !origin.hasAuthority ||
        origin.userInfo.isNotEmpty ||
        origin.authority.contains('@') ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/') ||
        authority == null) {
      throw ArgumentError.value(
        rawOrigin,
        'localOrigin',
        'Expected an HTTP(S) origin',
      );
    }
    final rawLocal = config.localHost;
    if (rawLocal != null) {
      final local = parseMentionAuthority(rawLocal);
      final defaultPort = origin.scheme == 'https' ? 443 : 80;
      if (local == null ||
          local.identity != authority.identity ||
          (local.port ?? defaultPort) != (authority.port ?? defaultPort)) {
        throw ArgumentError.value(
          rawLocal,
          'localHost',
          'Conflicts with localOrigin',
        );
      }
    }
  }
  final viewer = options?.viewerAcct;
  if (viewer != null && _viewerIdentity(config) == null) {
    throw ArgumentError.value(
      viewer,
      'viewerAcct',
      'Expected @username[@authority] with a local context',
    );
  }
}

({String username, MentionAuthority authority})? _viewerIdentity(
  MfmRenderConfig config,
) {
  final viewer = config.mentionOptions?.viewerAcct;
  if (viewer == null) return null;
  final match = RegExp(r'^@([A-Za-z0-9_]+)(?:@(.+))?$').firstMatch(viewer);
  if (match == null || match.end != viewer.length) return null;
  final rawHost =
      match.group(2) ??
      config.localHost ??
      mentionOriginAuthority(config.mentionOptions?.localOrigin);
  final host = rawHost == null ? null : parseMentionAuthority(rawHost);
  if (host == null) return null;
  return (username: match.group(1)!.toLowerCase(), authority: host);
}

final class MentionDisplay {
  const MentionDisplay({
    required this.name,
    required this.host,
    required this.isSelf,
    required this.avatarAcct,
  });
  final String name;
  final String host;
  final bool isSelf;
  final String avatarAcct;
  String get label => '$name$host';
}

MentionDisplay resolveMentionDisplay({
  required String username,
  required String? nodeHost,
  required MfmRenderConfig config,
}) {
  final originHost = mentionOriginAuthority(config.mentionOptions?.localOrigin);
  final rawHost =
      _nonEmpty(nodeHost) ??
      _nonEmpty(config.author?.host) ??
      _nonEmpty(config.localHost) ??
      originHost;
  final host = rawHost == null ? null : parseMentionAuthority(rawHost);
  final localRaw = _nonEmpty(config.localHost) ?? originHost;
  final local = localRaw == null ? null : parseMentionAuthority(localRaw);
  final viewer = _viewerIdentity(config);
  final isLocal = host != null && local != null && host.matches(local);
  return MentionDisplay(
    name: '@$username',
    host: rawHost == null || isLocal ? '' : '@${host?.display ?? rawHost}',
    isSelf:
        host != null &&
        viewer != null &&
        RegExp(r'^[A-Za-z0-9_]+$').hasMatch(username) &&
        username.toLowerCase() == viewer.username &&
        host.matches(viewer.authority),
    avatarAcct: '@$username${rawHost == null ? '' : '@$rawHost'}',
  );
}

/// Keep raw authority spelling and explicit ports lost by Uri normalization.
String? mentionOriginAuthority(String? origin) {
  if (origin == null) return null;
  final match = RegExp(
    r'^https?://([^/?#]+)(?:/)?$',
    caseSensitive: false,
  ).firstMatch(origin);
  return match != null && match.end == origin.length ? match.group(1) : null;
}

/// Use only the explicitly configured local server, never the mention host.
Uri mentionAvatarUri(String origin, String acct) {
  final uri = Uri.parse(origin);
  final host = uri.host.contains(':')
      ? uri.host
      : domainToAscii(Uri.decodeComponent(uri.host));
  return uri.replace(host: host, pathSegments: ['avatar', acct]);
}
