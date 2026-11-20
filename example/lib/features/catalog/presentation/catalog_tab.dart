import 'package:flutter/material.dart';

import '../../../core/widgets/example_page.dart';
import '../data/catalog_navigation.dart';
import '../data/mfm_examples.dart';
import 'widgets/catalog_lists.dart';

/// タブを離れても閲覧中の階層を維持するカタログ。
class CatalogTab extends StatefulWidget {
  const CatalogTab({
    super.key,
    required this.onTryExample,
    required this.onOpenSettings,
    required this.canHandleBack,
  });

  final ValueChanged<MfmExample> onTryExample;
  final VoidCallback onOpenSettings;
  final bool canHandleBack;

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<void>(
      enabled: widget.canHandleBack,
      onPopWithResult: (_) {
        // enabled=falseでもcallbackが呼ばれる場合がある。
        if (!widget.canHandleBack) return;
        final navigator = _navigatorKey.currentState;
        if (navigator != null && navigator.canPop()) navigator.maybePop();
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => ExamplePage(
            title: 'MFM Renderer',
            onOpenSettings: _openSettings,
            child: CatalogMenuList(
              menu: CatalogNavigation.root,
              onSelect: _openNode,
            ),
          ),
        ),
      ),
    );
  }

  void _openSettings() => widget.onOpenSettings();

  void _back() => _navigatorKey.currentState!.maybePop();

  void _openNode(CatalogNode node) {
    _navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ExamplePage(
          title: node.title,
          onBack: _back,
          onOpenSettings: _openSettings,
          child: switch (node) {
            CatalogMenu() => CatalogMenuList(menu: node, onSelect: _openNode),
            CatalogExamplePage() => CatalogDetailList(
              page: node,
              onTryExample: (example) => widget.onTryExample(example),
            ),
          },
        ),
      ),
    );
  }
}
