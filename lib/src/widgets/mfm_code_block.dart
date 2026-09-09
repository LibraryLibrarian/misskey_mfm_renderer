import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

import '../config/mfm_color_scheme.dart';

/// MFMコードブロックウィジェット
///
/// シンタックスハイライト、横スクロール、コピーボタンを備えたコードブロック表示
class MfmCodeBlock extends StatelessWidget {
  const MfmCodeBlock({
    required this.code,
    this.language,
    required this.theme,
    required this.colorScheme,
    this.showCopyButton = true,
    this.onCodeCopied,
    this.copyTooltip,
    this.copiedMessage,
    this.fontSize,
    super.key,
  });

  /// コード内容
  final String code;

  /// プログラミング言語（nullの場合はplaintextとして扱う）
  final String? language;

  /// シンタックスハイライトテーマ
  final Map<String, TextStyle> theme;

  /// コードブロックの配色
  final MfmColorScheme colorScheme;

  /// コピーボタンを表示するか
  final bool showCopyButton;

  /// コピー完了時のコールバック。指定時は既定のSnackBarを表示しない。
  final void Function(String code)? onCodeCopied;

  /// コピーボタンのアクセシビリティラベル。
  ///
  /// Material依存を避けるためツールチップは表示せず、Semanticsのラベルとして扱う。
  /// nullの場合は現在のロケールから解決する。
  final String? copyTooltip;

  /// 既定のSnackBarメッセージ。nullの場合は現在のロケールから解決する。
  final String? copiedMessage;

  /// コードのフォントサイズ。nullの場合はHighlightViewの既定値を使用する。
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final isJapanese =
        Localizations.maybeLocaleOf(context)?.languageCode == 'ja';
    final effectiveFontSize =
        fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14.0;
    final resolvedTheme = _resolveTheme();
    final backgroundColor = resolvedTheme['root']!.backgroundColor!;
    final isHighlighted = language != null;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        vertical: isHighlighted ? 0 : effectiveFontSize * 0.5,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: colorScheme.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // コードブロック本体（横スクロール対応）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(effectiveFontSize),
            child: HighlightView(
              code,
              language: language ?? 'plaintext',
              theme: resolvedTheme,
              padding: EdgeInsets.zero,
              textStyle: TextStyle(
                fontFamily: 'Consolas',
                fontFamilyFallback: const [
                  'Monaco',
                  'Andale Mono',
                  'Ubuntu Mono',
                  'monospace',
                ],
                fontSize: fontSize,
              ),
            ),
          ),
          // コピーボタン（右上）
          if (showCopyButton)
            Positioned(
              top: 8,
              right: 8,
              child: _CopyButton(
                code: code,
                onCodeCopied: onCodeCopied,
                tooltip: copyTooltip ?? (isJapanese ? 'コピー' : 'Copy'),
                copiedMessage:
                    copiedMessage ??
                    (isJapanese ? 'コードをコピーしました' : 'Copied to clipboard'),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, TextStyle> _resolveTheme() {
    final rootStyle = theme['root'] ?? const TextStyle();
    final resolvedRootStyle = language == null
        ? rootStyle.copyWith(
            color: colorScheme.fg,
            backgroundColor: colorScheme.bg,
          )
        : rootStyle.copyWith(
            backgroundColor: rootStyle.backgroundColor ?? colorScheme.bg,
          );

    return {...theme, 'root': resolvedRootStyle};
  }
}

/// コピーボタンウィジェット
class _CopyButton extends StatefulWidget {
  const _CopyButton({
    required this.code,
    required this.onCodeCopied,
    required this.tooltip,
    required this.copiedMessage,
  });

  final String code;
  final void Function(String code)? onCodeCopied;

  /// アクセシビリティラベルとして使用する文言。
  final String tooltip;
  final String copiedMessage;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // IconButtonとTooltipはMaterial（およびOverlay）を必要とするため、
    // CupertinoApp/WidgetsApp直下でも動作するようにwidgets.dartのみで構成する。
    // ツールチップの文言はSemanticsのラベルとして提供する。
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _copyToClipboard,
          child: Opacity(
            opacity: _isHovered ? 0.8 : 0.5,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Center(child: Icon(Icons.content_copy, size: 18)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    final code = widget.code;
    final onCodeCopied = widget.onCodeCopied;
    await Clipboard.setData(ClipboardData(text: code));
    if (onCodeCopied != null) {
      onCodeCopied(code);
    } else if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(widget.copiedMessage),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
