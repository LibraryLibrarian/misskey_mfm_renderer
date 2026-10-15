import 'package:flutter/material.dart';

import '../core/emoji/example_startup.dart';
import '../core/widgets/example_page.dart';
import '../features/catalog/data/mfm_examples.dart';
import '../features/catalog/presentation/catalog_tab.dart';
import '../features/playground/application/playground_controller.dart';
import '../features/playground/presentation/playground_tab.dart';
import 'widgets/settings_drawer.dart';

/// ホーム画面
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.emojiStatus});

  final ExampleEmojiStatus emojiStatus;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final _playground = PlaygroundController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _drawerOpen = false;
  bool _confirming = false;

  @override
  void dispose() {
    _playground.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail = constraints.maxWidth >= 600;
        return Scaffold(
          key: _scaffoldKey,
          endDrawer: SettingsDrawer(emojiStatus: widget.emojiStatus),
          onEndDrawerChanged: (open) => setState(() => _drawerOpen = open),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Row(
              children: [
                if (useNavigationRail) ...[
                  SafeArea(
                    child: NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _selectDestination,
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.list_alt_outlined),
                          selectedIcon: Icon(Icons.list_alt),
                          label: Text('カタログ'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.edit_note_outlined),
                          selectedIcon: Icon(Icons.edit_note),
                          label: Text('プレイグラウンド'),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  key: const Key('pageRegion'),
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      TickerMode(
                        enabled: _selectedIndex == 0,
                        child: CatalogTab(
                          onTryExample: _loadExample,
                          onOpenSettings: _openSettings,
                          canHandleBack: _selectedIndex == 0 && !_drawerOpen,
                        ),
                      ),
                      TickerMode(
                        enabled: _selectedIndex == 1,
                        child: ExamplePage(
                          title: 'MFM Renderer',
                          onOpenSettings: _openSettings,
                          child: PlaygroundTab(
                            controller: _playground,
                            onClear: _clearText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: useNavigationRail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.list_alt_outlined),
                      selectedIcon: Icon(Icons.list_alt),
                      label: 'カタログ',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.edit_note_outlined),
                      selectedIcon: Icon(Icons.edit_note),
                      label: 'プレイグラウンド',
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _openSettings() => _scaffoldKey.currentState!.openEndDrawer();

  Future<void> _loadExample(MfmExample example) async {
    await _withDiscardConfirmation(() {
      _playground.load(example);
      _selectDestination(1);
    });
  }

  Future<void> _clearText() async {
    await _withDiscardConfirmation(_playground.clearText);
  }

  Future<void> _withDiscardConfirmation(VoidCallback apply) async {
    if (_confirming) return;
    if (!_playground.needsDiscardConfirmation) {
      apply();
      return;
    }
    _confirming = true;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('編集した本文を破棄しますか？'),
          content: const Text('現在の本文への変更は失われます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('破棄して続ける'),
            ),
          ],
        ),
      );
      if (mounted && accepted == true) apply();
    } finally {
      _confirming = false;
    }
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
