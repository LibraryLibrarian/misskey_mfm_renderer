import 'package:flutter/material.dart';

import '../features/catalog/presentation/catalog_tab.dart';
import '../features/playground/presentation/playground_tab.dart';
import 'widgets/settings_drawer.dart';

/// ホーム画面
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.emojiInitialized});

  final bool emojiInitialized;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    CatalogTab(),
    PlaygroundTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail = constraints.maxWidth >= 600;
        return Scaffold(
          appBar: AppBar(
            title: const Text('MFM Renderer'),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  key: const Key('openSettingsDrawerButton'),
                  tooltip: '表示設定',
                  icon: const Icon(Icons.tune),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),
          endDrawer: SettingsDrawer(emojiInitialized: widget.emojiInitialized),
          body: useNavigationRail
              ? Row(
                  children: [
                    NavigationRail(
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
                    const VerticalDivider(width: 1),
                    Expanded(child: _pageStack),
                  ],
                )
              : _pageStack,
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

  Widget get _pageStack =>
      IndexedStack(index: _selectedIndex, children: _pages);

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
