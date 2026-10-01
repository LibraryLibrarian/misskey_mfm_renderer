import 'package:flutter/widgets.dart';

import '../config/mfm_unixtime_options.dart';
import '../fn/animated/mfm_rainbow_text.dart';
import '../utils/unixtime.dart';
import '../utils/unixtime_scheduler.dart';

/// ピルの文字だけを更新する。MfmTextの再parseやancestor設定を必要としない。
class MfmUnixtimeLabel extends StatefulWidget {
  const MfmUnixtimeLabel({
    super.key,
    required this.timestamp,
    required this.options,
    required this.style,
    required this.nowrap,
    required this.rainbowScope,
    required this.rainbowForeground,
  });

  final int? timestamp;
  final MfmUnixtimeOptions options;
  final TextStyle style;
  final bool nowrap;
  final MfmRainbowScope? rainbowScope;
  final bool rainbowForeground;

  @override
  State<MfmUnixtimeLabel> createState() => _MfmUnixtimeLabelState();
}

class _MfmUnixtimeLabelState extends State<MfmUnixtimeLabel> {
  Locale _locale = const Locale('en');
  String _label = '';
  bool _subscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
  }

  @override
  void didUpdateWidget(MfmUnixtimeLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refresh();
  }

  void _refresh() {
    _locale =
        widget.options.locale ??
        Localizations.maybeLocaleOf(context) ??
        const Locale('en');
    _label = _format();
    final subscribe =
        unixtimeDateTime(widget.timestamp) != null &&
        widget.options.autoUpdate &&
        widget.options.mode != MfmUnixtimeMode.absolute;
    if (subscribe == _subscribed) return;
    _subscribed = subscribe;
    if (subscribe) {
      UnixtimeScheduler.instance.subscribe(_tick);
    } else {
      UnixtimeScheduler.instance.unsubscribe(_tick);
    }
  }

  String _format([DateTime? sharedNow]) {
    final options = widget.options;
    final context = MfmUnixtimeFormatContext(
      dateTime: unixtimeDateTime(widget.timestamp),
      now: options.now?.call() ?? sharedNow ?? DateTime.now(),
      locale: _locale,
      mode: options.mode,
    );
    return (options.formatter ?? formatUnixtime)(context);
  }

  void _tick(DateTime now) {
    final label = _format(now);
    if (label != _label) setState(() => _label = label);
  }

  @override
  void dispose() {
    if (_subscribed) UnixtimeScheduler.instance.unsubscribe(_tick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      _label,
      style: widget.style.copyWith(inherit: false),
      softWrap: !widget.nowrap,
      maxLines: widget.nowrap ? 1 : null,
      overflow: widget.nowrap ? TextOverflow.ellipsis : TextOverflow.clip,
    );
    final scope = widget.rainbowScope;
    return scope == null
        ? text
        : MfmRainbowText(
            scope: scope,
            text: text,
            rainbowForeground: widget.rainbowForeground,
          );
  }
}
