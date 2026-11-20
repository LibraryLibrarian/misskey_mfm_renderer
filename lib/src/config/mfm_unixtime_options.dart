import 'package:flutter/widgets.dart';
import 'package:timeago/timeago.dart' as timeago;

/// 日時の表示方法。既定は絶対日時と相対日時を併記するdetail。
enum MfmUnixtimeMode { detail, relative, absolute }

/// 日時ラベル全体を生成する。invalidも[context]のdateTimeがnullで通知する。
typedef MfmUnixtimeFormatter =
    String Function(MfmUnixtimeFormatContext context);

/// formatterへ渡す、1回の表示に使用する日時と解決済みlocale。
@immutable
class MfmUnixtimeFormatContext {
  const MfmUnixtimeFormatContext({
    required this.dateTime,
    required this.now,
    required this.locale,
    required this.mode,
  });

  /// local日時。解析できない場合はnull。
  final DateTime? dateTime;
  final DateTime now;

  /// 組込み書式のEnglish fallback前のlocale。
  final Locale locale;
  final MfmUnixtimeMode mode;
}

/// 日時の表示設定。継承時はオブジェクト全体を置換する。
@immutable
class MfmUnixtimeOptions {
  const MfmUnixtimeOptions({
    this.mode = MfmUnixtimeMode.detail,
    this.locale,
    this.formatter,
    this.now,
    this.autoUpdate = true,
  });

  final MfmUnixtimeMode mode;

  /// 未指定時はLocalizations、なければEnglish。組込みは日英に対応。
  final Locale? locale;
  final MfmUnixtimeFormatter? formatter;

  /// アプリ管理の時計。ラベルのformatごとに一度読み取る。
  final DateTime Function()? now;

  /// 有効日時のdetail/relativeだけを10秒周期で更新する。
  /// absoluteではformatterがnowを参照しても購読しない。
  /// falseでも通常のrebuildや設定・locale変更時には再formatする。
  final bool autoUpdate;
}

/// 有効入力に対する従来のtimeago表示（global locale・未来表現）を維持する。
/// first-child解析とinvalidの旧動作は復元しない。
String mfmLegacyUnixtimeFormatter(MfmUnixtimeFormatContext context) {
  final dateTime = context.dateTime;
  if (dateTime == null) {
    return context.locale.languageCode == 'ja' ? '日時の解析に失敗' : 'None';
  }
  return timeago.format(dateTime, clock: context.now);
}
