import 'package:flutter/material.dart';

/// 実行に必要な個別設定。コードは補助関数を含まない抜粋。
class ExampleSetupPanel extends StatelessWidget {
  const ExampleSetupPanel({
    super.key,
    required this.summary,
    required this.code,
    this.expansionStorageKey,
  });

  final String? summary;
  final String? code;
  final PageStorageKey<String>? expansionStorageKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary != null) Text(summary!),
        if (code != null)
          ExpansionTile(
            key: expansionStorageKey,
            title: const Text('使用設定'),
            subtitle: const Text('Dartコード抜粋・補助関数は参照先を確認'),
            tilePadding: EdgeInsets.zero,
            children: [
              SizedBox(
                width: double.infinity,
                child: SelectableText(
                  code!,
                  // SelectableText内部のscrollと展開状態の保存先を分ける。
                  key: expansionStorageKey == null
                      ? null
                      : const PageStorageKey('setup-code-scroll'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
