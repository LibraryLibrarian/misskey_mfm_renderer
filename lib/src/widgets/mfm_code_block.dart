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

  @override
  Widget build(BuildContext context) {
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
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          // コピーボタン（右上）
          if (showCopyButton)
            Positioned(
              top: 8,
              right: 8,
              child: _CopyButton(code: code),
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
  const _CopyButton({required this.code});

  final String code;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Opacity(
        opacity: _isHovered ? 0.8 : 0.5,
        child: IconButton(
          icon: const Icon(Icons.content_copy, size: 18),
          onPressed: _copyToClipboard,
          tooltip: 'コピー',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.code));
    // SnackBarで通知
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('コードをコピーしました'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
