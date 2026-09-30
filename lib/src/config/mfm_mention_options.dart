import 'package:flutter/widgets.dart';

/// メンションの行内表示方法。
enum MfmMentionPresentation { capsule, text }

/// 未正規化の解決済みacctからアバターを取得する。nullはplaceholderを表す。
typedef MfmMentionAvatarProvider = ImageProvider<Object>? Function(String acct);

/// メンションの表示設定。未指定でもcapsule表示で、暗黙の画像通信は行わない。
///
/// 継承時はオブジェクト全体を置換する。空のoptionsで祖先の画像取得設定を解除できる。
@immutable
class MfmMentionOptions {
  const MfmMentionOptions({
    this.presentation = MfmMentionPresentation.capsule,
    this.viewerAcct,
    this.localOrigin,
    this.avatarProvider,
  });

  final MfmMentionPresentation presentation;

  /// 閲覧者。`@username`または`@username@authority`。投稿者とは独立。
  /// host省略時はlocalHostまたはlocalOriginが必要。
  final String? viewerAcct;

  /// 明示的なhttp(s) origin。指定時だけ組込みの /avatar/@acct を使用する。
  /// userinfo/query/fragmentやroot以外のpathは不可。最終設定のbuild時に検証する。
  final String? localOrigin;

  /// 最優先の画像取得方法。nullを返してもlocalOriginへfallbackしない。
  /// text表示では呼ばれない。
  final MfmMentionAvatarProvider? avatarProvider;
}
