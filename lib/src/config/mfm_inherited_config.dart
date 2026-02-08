import 'package:flutter/widgets.dart';

import 'mfm_render_config.dart';

/// アプリ全体でMFM設定を共有するInheritedWidget
class MfmConfig extends InheritedWidget {
  const MfmConfig({
    super.key,
    required this.config,
    required super.child,
  });

  final MfmRenderConfig config;

  /// 最も近いMfmConfigを取得（nullを許容）
  static MfmRenderConfig? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MfmConfig>()?.config;
  }

  /// 最も近いMfmConfigを取得（必須）
  static MfmRenderConfig of(BuildContext context) {
    final config = maybeOf(context);
    assert(config != null, 'No MfmConfig found in context');
    return config!;
  }

  @override
  bool updateShouldNotify(MfmConfig oldWidget) {
    return config != oldWidget.config;
  }
}
