import 'dart:ui';

import 'package:flutter/foundation.dart';

/// MFMの描画に使用する解決済みのテーマ色。
///
/// 各フィールドはMisskeyテーマ内の参照を解決した単色であり、相互に連動しない。
/// たとえば[accent]だけを変更しても、[mention]などの色は追随しない。
@immutable
final class MfmColorScheme {
  const MfmColorScheme({
    required this.accent,
    required this.link,
    required this.hashtag,
    required this.mention,
    required this.mentionMe,
    required this.fg,
    required this.bg,
    required this.divider,
    required this.panel,
  });

  /// MisskeyのMi Lightテーマに基づく配色。
  const MfmColorScheme.light({
    this.accent = const Color(0xFF86B300),
    this.link = const Color(0xFF44A4C1),
    this.hashtag = const Color(0xFFFF9156),
    this.mention = const Color(0xFF86B300),
    this.mentionMe = const Color(0xFF00B346),
    this.fg = const Color(0xFF676767),
    this.bg = const Color(0xFFF9F9F9),
    this.divider = const Color(0xFFE8E8E8),
    this.panel = const Color(0xFFFFFFFF),
  });

  /// MisskeyのMi Darkテーマに基づく配色。
  const MfmColorScheme.dark({
    this.accent = const Color(0xFF86B300),
    this.link = const Color(0xFF86B300),
    this.hashtag = const Color(0xFF4CB8D4),
    this.mention = const Color(0xFFDA6D35),
    this.mentionMe = const Color(0xFFD44C4C),
    this.fg = const Color(0xFFC7D1D8),
    this.bg = const Color(0xFF232323),
    this.divider = const Color.fromRGBO(255, 255, 255, 0.14),
    this.panel = const Color(0xFF2D2D2D),
  });

  final Color accent;
  final Color link;
  final Color hashtag;
  final Color mention;
  final Color mentionMe;
  final Color fg;
  final Color bg;
  final Color divider;
  final Color panel;

  MfmColorScheme copyWith({
    Color? accent,
    Color? link,
    Color? hashtag,
    Color? mention,
    Color? mentionMe,
    Color? fg,
    Color? bg,
    Color? divider,
    Color? panel,
  }) {
    return MfmColorScheme(
      accent: accent ?? this.accent,
      link: link ?? this.link,
      hashtag: hashtag ?? this.hashtag,
      mention: mention ?? this.mention,
      mentionMe: mentionMe ?? this.mentionMe,
      fg: fg ?? this.fg,
      bg: bg ?? this.bg,
      divider: divider ?? this.divider,
      panel: panel ?? this.panel,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MfmColorScheme &&
        other.accent == accent &&
        other.link == link &&
        other.hashtag == hashtag &&
        other.mention == mention &&
        other.mentionMe == mentionMe &&
        other.fg == fg &&
        other.bg == bg &&
        other.divider == divider &&
        other.panel == panel;
  }

  @override
  int get hashCode => Object.hash(
    accent,
    link,
    hashtag,
    mention,
    mentionMe,
    fg,
    bg,
    divider,
    panel,
  );

  @override
  String toString() {
    return 'MfmColorScheme('
        'accent: $accent, '
        'link: $link, '
        'hashtag: $hashtag, '
        'mention: $mention, '
        'mentionMe: $mentionMe, '
        'fg: $fg, '
        'bg: $bg, '
        'divider: $divider, '
        'panel: $panel'
        ')';
  }
}
