import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

/// MFMコードブロックウィジェット
///
/// シンタックスハイライト、横スクロール、コピーボタンを備えたコードブロック表示
class MfmCodeBlock extends StatelessWidget {
  const MfmCodeBlock({
    required this.code,
    this.language,
    required this.theme,
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

  /// コピーボタンを表示するか
  final bool showCopyButton;

  /// コピー完了時のコールバック。指定時は既定のSnackBarを表示しない。
  final void Function(String code)? onCodeCopied;

  /// コピーボタンのツールチップ。nullの場合は現在のロケールから解決する。
  final String? copyTooltip;

  /// 既定のSnackBarメッセージ。nullの場合は現在のロケールから解決する。
  final String? copiedMessage;

  /// コードのフォントサイズ。nullの場合はHighlightViewの既定値を使用する。
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final isJapanese =
        Localizations.maybeLocaleOf(context)?.languageCode == 'ja';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // コードブロック本体（横スクロール対応）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              code,
              language: language ?? 'plaintext',
              theme: theme,
              padding: EdgeInsets.zero,
              textStyle: TextStyle(
                fontFamily: 'monospace',
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

  /// テーマから背景色を取得
  Color _getBackgroundColor() {
    // themeから背景色を取得、またはデフォルト色を返す
    final rootStyle = theme['root'];
    if (rootStyle?.backgroundColor != null) {
      return rootStyle!.backgroundColor!;
    }
    // デフォルト色（ライトグレー）
    return const Color(0xFFF5F5F5);
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
  final String tooltip;
  final String copiedMessage;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // widgets.dartのみのツリーではTooltipが必要とするOverlayがない場合がある。
    final canShowTooltip = Overlay.maybeOf(context) != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Opacity(
        opacity: _isHovered ? 0.8 : 0.5,
        child: Semantics(
          label: canShowTooltip ? null : widget.tooltip,
          child: IconButton(
            icon: const Icon(Icons.content_copy, size: 18),
            onPressed: _copyToClipboard,
            tooltip: canShowTooltip ? widget.tooltip : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
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
