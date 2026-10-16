import 'package:flutter/material.dart';

/// 各タブ・カタログの階層で共有する画面枠。
class ExamplePage extends StatelessWidget {
  const ExamplePage({
    super.key,
    required this.title,
    required this.onOpenSettings,
    required this.child,
    this.onBack,
  });

  final String title;
  final VoidCallback onOpenSettings;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        leading: onBack == null ? null : BackButton(onPressed: onBack),
        actions: [
          IconButton(
            key: const Key('openSettingsButton'),
            tooltip: '表示設定',
            icon: const Icon(Icons.tune),
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: SafeArea(top: false, child: child),
    );
  }
}
