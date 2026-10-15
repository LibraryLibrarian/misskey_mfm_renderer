import 'package:flutter/material.dart';

/// 実行に必要な個別設定。コードは補助関数を含まない抜粋。
class ExampleSetupPanel extends StatelessWidget {
  const ExampleSetupPanel({
    super.key,
    required this.summary,
    required this.code,
  });

  final String? summary;
  final String? code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary != null) Text(summary!),
        if (code != null)
          ExpansionTile(
            title: const Text('使用設定'),
            subtitle: const Text('Dartコード抜粋・補助関数は参照先を確認'),
            tilePadding: EdgeInsets.zero,
            children: [
              SizedBox(
                width: double.infinity,
                child: SelectableText(
                  code!,
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
