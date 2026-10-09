import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_search.dart';

void main() {
  testWidgets(
    'pointer edits and button/IME submit the accepted raw value once',
    (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(_app(_search(onSearch: calls.add)));
      final field = find.byType(EditableText);
      expect(_editor(tester).controller.text, 'original');
      expect(_editor(tester).focusNode.hasFocus, isFalse);
      expect(
        tester
            .widget<CupertinoTextField>(find.byType(CupertinoTextField))
            .placeholder,
        'original',
      );
      await tester.tap(find.text('Search'));
      expect(calls, ['original']);
      for (final value in ['edited', '', '  ', '日本語 🔎 なに']) {
        final before = calls.length;
        await tester.tap(field);
        await tester.enterText(field, value);
        await tester.pump();
        expect(calls.length, before);
        if (value.isEmpty) {
          expect(find.text('original'), findsOneWidget);
          expect(_editor(tester).controller.text, isEmpty);
        }
        await tester.tap(find.text('Search'));
        expect(calls.length, before + 1);
        expect(calls.last, value);
        await tester.tap(field);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();
        expect(calls.length, before + 2);
        expect(calls.last, value);
        expect(_editor(tester).controller.text, value);
        expect(_editor(tester).controller.value.composing, TextRange.empty);
        expect(_editor(tester).focusNode.hasFocus, isFalse);
      }
    },
  );

  testWidgets('single-line accepted value stays raw even with nyaize enabled', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      _app(
        MfmText(
          text: 'なに Search',
          config: MfmRenderConfig(
            nyaizeMode: MfmNyaizeMode.enabled,
            onSearchTap: calls.add,
          ),
        ),
      ),
    );
    final field = tester.widget<CupertinoTextField>(
      find.byType(CupertinoTextField),
    );
    expect(field.autofocus, isFalse);
    expect(field.clearButtonMode, OverlayVisibilityMode.never);
    expect(_editor(tester).controller.text, 'なに');
    await tester.tap(find.text('Search'));
    expect(calls, ['なに']);
    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), '  なに /?& 🔎  \n');
    await tester.pump();
    expect(_editor(tester).controller.text, '  なに /?& 🔎  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(calls, ['なに', '  なに /?& 🔎  ']);
  });

  testWidgets(
    'ordinary config/locale updates preserve full editing value and '
    'use latest callback',
    (tester) async {
      final first = <String>[];
      final second = <String>[];
      Widget build({
        ValueChanged<String>? callback,
        String query = 'original',
        Locale locale = const Locale('en'),
        String? label,
        Color color = Colors.black,
      }) {
        return _app(
          Builder(
            builder: (context) => Localizations.override(
              context: context,
              locale: locale,
              child: _search(
                query: query,
                onSearch: callback,
                label: label,
                style: TextStyle(fontSize: 17, color: color),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(build(callback: first.add));
      await tester.tap(find.byType(EditableText));
      const value = TextEditingValue(
        text: '日本語 🔎 draft',
        selection: TextSelection(baseOffset: 1, extentOffset: 3),
        composing: TextRange(start: 0, end: 3),
      );
      tester.testTextInput.updateEditingValue(value);
      await tester.pump();
      final controller = _editor(tester).controller;
      final focus = _editor(tester).focusNode;
      for (final callback in <ValueChanged<String>?>[
        second.add,
        null,
        first.add,
      ]) {
        await tester.tap(find.byType(EditableText));
        tester.testTextInput.updateEditingValue(value);
        await tester.pump();
        await tester.pumpWidget(
          build(
            callback: callback,
            locale: const Locale('ja'),
            color: Colors.purple,
          ),
        );
        expect(_editor(tester).controller, same(controller));
        expect(controller.value, value);
        expect(focus.hasFocus, isTrue);
        expect(find.text('検索'), findsOneWidget);
        await tester.tap(find.text('検索'));
        expect(controller.text, value.text);
      }
      expect(first, [value.text]);
      expect(second, [value.text]);
      await tester.tap(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(value);
      await tester.pump();
      await tester.pumpWidget(
        build(callback: second.add, label: 'Find', query: 'replacement'),
      );
      expect(
        controller.value,
        const TextEditingValue(
          text: 'replacement',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );
      expect(focus.hasFocus, isTrue);
      await tester.tap(find.text('Find'));
      expect(second.last, 'replacement');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNot(same(focus)));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'IME composition commits through Search action, not '
    'editing-change callbacks',
    (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(_app(_search(onSearch: calls.add)));
      await tester.tap(find.byType(EditableText));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'にほんご',
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange(start: 0, end: 4),
        ),
      );
      await tester.pump();
      expect(calls, isEmpty);
      expect(
        _editor(tester).controller.value.composing,
        const TextRange(start: 0, end: 4),
      );
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '日本語 🔎',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(calls, ['日本語 🔎']);
      expect(_editor(tester).controller.value.composing, TextRange.empty);
      expect(_editor(tester).focusNode.hasFocus, isFalse);
    },
  );

  for (final mode in NavigationMode.values) {
    testWidgets(
      'disabled button rejects focus in ${mode.name} navigation, '
      'including while focused',
      (tester) async {
        final next = FocusNode();
        addTearDown(next.dispose);
        final calls = <String>[];
        Widget build({required bool enabled}) => _app(
          MediaQuery(
            data: MediaQueryData(navigationMode: mode),
            child: Column(
              children: [
                _search(onSearch: enabled ? calls.add : null),
                Focus(focusNode: next, child: const Text('Next focus target')),
              ],
            ),
          ),
        );
        await tester.pumpWidget(build(enabled: true));
        await tester.tap(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'still editable');
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final buttonContext = tester.element(find.text('Search'));
        final buttonFocus = Focus.of(buttonContext);
        expect(buttonFocus.hasFocus, isTrue);
        await tester.pumpWidget(build(enabled: false));
        await tester.pump();
        expect(buttonFocus.hasFocus, isFalse);
        expect(buttonFocus.canRequestFocus, isFalse);
        buttonFocus.requestFocus();
        await tester.pump();
        expect(buttonFocus.hasFocus, isFalse);
        await tester.tap(find.byType(EditableText));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(next.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(calls, isEmpty);
        expect(_editor(tester).controller.text, 'still editable');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('multiple fields own independent drafts', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      _app(
        MfmText(
          text: 'one Search\ntwo Search',
          config: MfmRenderConfig(onSearchTap: calls.add),
        ),
      ),
    );
    final fields = find.byType(EditableText);
    await tester.tap(fields.first);
    await tester.enterText(fields.first, 'first draft');
    await tester.tap(fields.last);
    await tester.enterText(fields.last, 'second draft');
    await tester.tap(find.text('Search').first);
    await tester.tap(find.text('Search').last);
    expect(calls, ['first draft', 'second draft']);
  });

  for (final host in ['material', 'cupertino', 'widgets', 'minimal']) {
    testWidgets('$host supports pointer focus basic input and submission', (
      tester,
    ) async {
      final calls = <String>[];
      final child = _search(onSearch: calls.add);
      await tester.pumpWidget(switch (host) {
        'material' => _app(child),
        'cupertino' => CupertinoApp(
          home: Align(alignment: Alignment.topLeft, child: child),
        ),
        'widgets' => WidgetsApp(
          color: Colors.white,
          builder: (_, _) => Align(alignment: Alignment.topLeft, child: child),
        ),
        _ => _bare(child),
      });
      final field = find.byType(EditableText);
      await tester.tap(field);
      await tester.pump();
      expect(_editor(tester).focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      await tester.enterText(field, 'host 日本語');
      await tester.pump();
      if (host == 'minimal') {
        final cupertino = tester.widget<CupertinoTextField>(
          find.byType(CupertinoTextField),
        );
        expect(cupertino.enableInteractiveSelection, isFalse);
        expect(cupertino.contextMenuBuilder, isNull);
        await tester.tap(field);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(field);
        await tester.pump(const Duration(milliseconds: 350));
        await tester.longPress(field);
        await tester.pump();
      }
      await tester.tap(find.text('Search'));
      expect(calls, ['host 日本語']);
      // This is a fresh focus tap, not a second tap in a double-tap sequence.
      await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
      await tester.tap(field);
      // Allow pointer-driven focus and the input connection to settle before
      // simulating the platform IME action, especially after web tap-outside.
      await tester.pump();
      expect(
        _editor(tester).focusNode.hasFocus,
        isTrue,
        reason: 'pointer refocus',
      );
      expect(
        tester.testTextInput.hasAnyClients,
        isTrue,
        reason: 'IME connection',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(calls, ['host 日本語', 'host 日本語']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'overlay without Cupertino localization opens English popup '
    'without changing Japanese label',
    (tester) async {
      await _useFlutterContextMenu(tester);
      await tester.pumpWidget(
        WidgetsApp(
          color: Colors.white,
          builder: (context, _) => Localizations.override(
            context: context,
            locale: const Locale('ja'),
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (_) => Align(
                    alignment: Alignment.topLeft,
                    child: _search(onSearch: (_) {}),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('検索'), findsOneWidget);
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'select me');
      await tester.longPress(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(
        find.byType(CupertinoAdaptiveTextSelectionToolbar),
        findsOneWidget,
      );
      final popupContext = tester.element(
        find.byType(CupertinoAdaptiveTextSelectionToolbar),
      );
      expect(Localizations.localeOf(popupContext), const Locale('en'));
      expect(CupertinoLocalizations.of(popupContext).copyButtonLabel, 'Copy');
      expect(find.text('検索'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'popup keeps field delegates and direction across differently '
    'localized root overlay',
    (tester) async {
      await _useFlutterContextMenu(tester);
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Localizations.override(
              context: context,
              locale: const Locale('ja'),
              delegates: const [_JapaneseCupertinoDelegate()],
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: _search(onSearch: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'select me');
      await tester.longPress(find.byType(EditableText));
      await tester.pumpAndSettle();
      final popupContext = tester.element(
        find.byType(CupertinoAdaptiveTextSelectionToolbar),
      );
      expect(Localizations.localeOf(popupContext), const Locale('ja'));
      expect(CupertinoLocalizations.of(popupContext).copyButtonLabel, 'コピー');
      expect(Directionality.of(popupContext), TextDirection.rtl);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'button Tab Enter Space and actual semantics actions are isolated '
    'from prose',
    (tester) async {
      final calls = <String>[];
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _app(
            MfmText(
              parsedNodes: const [
                TextNode('before '),
                SearchNode(query: 'original', content: 'original Search'),
                TextNode(' after'),
              ],
              config: MfmRenderConfig(
                onSearchTap: calls.add,
                searchButtonLabel: 'Find full label',
              ),
            ),
          ),
        );
        await tester.tap(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'draft');
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_editor(tester).focusNode.hasFocus, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(calls, ['draft', 'draft']);
        final node = tester.getSemantics(
          find.bySemanticsLabel('Find full label'),
        );
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.flagsCollection.isEnabled, Tristate.isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        tester
            .renderObject(find.byType(MfmText))
            .owner!
            .semanticsOwner!
            .performAction(node.id, SemanticsAction.tap);
        expect(calls, ['draft', 'draft', 'draft']);
        final prose = _semanticsNodes(tester).where((node) {
          final label = node.getSemanticsData().label;
          return label.contains('before') || label.contains('after');
        }).toList();
        expect(prose.map((node) => node.label).join(), contains('before'));
        expect(prose.map((node) => node.label).join(), contains('after'));
        for (final node in prose) {
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isFalse,
            reason: node.toStringDeep(),
          );
          expect(node.label, isNot(contains('Find full label')));
        }
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets(
    'direct AST link contains enabled and disabled search actions '
    'without tap fallthrough',
    (tester) async {
      final searches = <String>[];
      final links = <String>[];
      final semantics = tester.ensureSemantics();
      try {
        Widget build({required bool enabled}) => _app(
          MfmText(
            // This nesting tests the renderer directly, not parser syntax.
            parsedNodes: const [
              LinkNode(
                silent: true,
                url: 'https://example.test/',
                children: [
                  SearchNode(query: 'original', content: 'original Search'),
                ],
              ),
            ],
            config: MfmRenderConfig(
              onSearchTap: enabled ? searches.add : null,
              onLinkTap: links.add,
              searchButtonLabel: 'Find',
            ),
          ),
        );
        await tester.pumpWidget(build(enabled: true));
        await tester.tap(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'inside draft');
        await tester.tap(find.text('Find'));
        expect(searches, ['inside draft']);
        expect(links, isEmpty);
        var node = tester.getSemantics(find.bySemanticsLabel('Find'));
        tester
            .renderObject(find.byType(MfmText))
            .owner!
            .semanticsOwner!
            .performAction(node.id, SemanticsAction.tap);
        expect(searches, ['inside draft', 'inside draft']);
        expect(links, isEmpty);
        await tester.pumpWidget(build(enabled: false));
        expect(_editor(tester).controller.text, 'inside draft');
        node = tester.getSemantics(find.bySemanticsLabel('Find'));
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.flagsCollection.isEnabled, Tristate.isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
        await tester.tap(find.text('Find'));
        final gesture = find
            .ancestor(
              of: find.text('Find'),
              matching: find.byType(GestureDetector),
            )
            .first;
        await tester.tapAt(tester.getTopLeft(gesture) + const Offset(3, 3));
        await tester.tap(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'disabled draft');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();
        expect(searches, hasLength(2));
        expect(links, isEmpty);
        await tester.pumpWidget(build(enabled: true));
        expect(_editor(tester).controller.text, 'disabled draft');
        await tester.tap(find.text('Find'));
        expect(searches.last, 'disabled draft');
        expect(links, isEmpty);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final width in [100.0, 160.0, 320.0, 400.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'bounded width $width scale $scale fits long input and button',
        (tester) async {
          await tester.pumpWidget(
            _app(
              MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: SizedBox(
                  width: width,
                  child: _search(
                    query: 'very long 日本語 query that scrolls horizontally',
                    label: 'Very long search label 日本語',
                    onSearch: (_) {},
                  ),
                ),
              ),
            ),
          );
          expect(tester.getSize(find.byType(MfmSearch)).width, width);
          expect(
            tester.getSize(find.byType(CupertinoTextField)).height,
            greaterThanOrEqualTo(40),
          );
          final editor = _editor(tester);
          expect(editor.maxLines, 1);
          final button = tester.widget<Text>(
            find.text('Very long search label 日本語'),
          );
          expect(button.maxLines, 1);
          expect(button.overflow, TextOverflow.ellipsis);
          await tester.tap(find.byType(EditableText));
          await tester.enterText(
            find.byType(EditableText),
            '末尾まで長い入力を横スクロールして表示します 🔎',
          );
          await tester.pump();
          // Start the post-frame caret scroll, then advance its animation.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          final renderEditable = tester
              .state<EditableTextState>(find.byType(EditableText))
              .renderEditable;
          expect(
            renderEditable.offset.pixels,
            greaterThan(0),
            reason: renderEditable.toStringDeep(),
          );
          final labelRect = tester.getRect(
            find.text('Very long search label 日本語'),
          );
          final iconRect = tester.getRect(find.byType(Icon));
          final buttonGesture = find
              .ancestor(
                of: find.text('Very long search label 日本語'),
                matching: find.byType(GestureDetector),
              )
              .first;
          final buttonRect = tester.getRect(buttonGesture);
          expect(buttonRect.width, lessThanOrEqualTo(width * .6));
          expect(labelRect.top, greaterThanOrEqualTo(iconRect.bottom));
          expect(labelRect.left, greaterThanOrEqualTo(buttonRect.left));
          expect(labelRect.right, lessThanOrEqualTo(buttonRect.right));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('normal label and icon share a run at sufficient width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(SizedBox(width: 400, child: _search(onSearch: (_) {}))),
    );
    final label = tester.getRect(find.text('Search'));
    final icon = tester.getRect(find.byType(Icon));
    expect(label.center.dy, closeTo(icon.center.dy, .01));
    expect(label.left, greaterThanOrEqualTo(icon.right));
    final button = find
        .ancestor(
          of: find.text('Search'),
          matching: find.byType(GestureDetector),
        )
        .first;
    expect(tester.getSize(button).width, lessThan(240));
    expect(tester.takeException(), isNull);
  });

  testWidgets('nowrap and unbounded Row use finite search layout', (
    tester,
  ) async {
    await tester.pumpWidget(_app(Row(children: [_search(onSearch: (_) {})])));
    expect(tester.getSize(find.byType(MfmSearch)).width, 320);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 160,
          child: MfmText(
            text: 'original Search',
            nowrap: true,
            config: MfmRenderConfig(onSearchTap: (_) {}),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      '${brightness.name} fills missing editor colors from root palette',
      (tester) async {
        final palette = brightness == Brightness.dark
            ? const MfmColorScheme.dark()
            : const MfmColorScheme.light();
        await tester.pumpWidget(
          _app(
            MfmText(
              text: 'original Search',
              config: MfmRenderConfig(
                brightness: brightness,
                baseTextStyle: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        );
        final field = tester.widget<CupertinoTextField>(
          find.byType(CupertinoTextField),
        );
        expect(_editor(tester).style.color, palette.fg);
        expect(_editor(tester).style.fontFamily, isNull);
        expect(field.cursorColor, palette.accent);
        expect(field.keyboardAppearance, brightness);
        expect(
          (field.decoration!.border! as Border).left.color,
          palette.divider,
        );
        expect(field.decoration!.color, isNull);
      },
    );
  }

  testWidgets('unbounded fallback respects a larger parent minimum width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 360),
              // RichText passes loose constraints to WidgetSpan children;
              // test the internal layout's own minimum-width contract directly.
              child: const MfmSearch(
                query: 'original',
                label: 'Search',
                style: TextStyle(fontSize: 14),
                foreground: Colors.black,
                divider: Colors.grey,
                accent: Colors.blue,
                brightness: Brightness.light,
              ),
            ),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(MfmSearch)).width, 360);
    expect(tester.takeException(), isNull);
  });

  for (final wrapper in ['quote', 'bg', 'rainbow', 'x2']) {
    testWidgets('direct AST search under $wrapper keeps editable root style', (
      tester,
    ) async {
      const query = SearchNode(query: 'original', content: 'original Search');
      final node = wrapper == 'quote'
          ? const QuoteNode([query])
          : FnNode(
              name: wrapper,
              args: wrapper == 'bg' ? {'color': 'ff0000'} : {},
              children: const [query],
            );
      await tester.pumpWidget(
        _app(
          MfmText(
            parsedNodes: [node],
            config: MfmRenderConfig(
              enableAnimation: false,
              baseTextStyle: const TextStyle(fontSize: 18, color: Colors.brown),
              onSearchTap: (_) {},
            ),
          ),
        ),
      );
      expect(_editor(tester).style.fontSize, 18);
      expect(_editor(tester).style.color, Colors.brown);
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'draft');
      await tester.tap(find.text('Search'));
      expect(_editor(tester).controller.text, 'draft');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'foreground paint and explicit root typography survive Cupertino defaults',
    (tester) async {
      final paint = Paint()
        ..shader = const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 20));
      final style = TextStyle(
        fontSize: 19,
        fontFamily: 'custom-font',
        fontWeight: FontWeight.w700,
        foreground: paint,
        backgroundColor: Colors.yellow,
        letterSpacing: 2,
        decoration: TextDecoration.underline,
      );
      await tester.pumpWidget(_app(_search(style: style)));
      final actual = _editor(tester).style;
      expect(actual.fontSize, 19);
      expect(actual.fontFamily, 'custom-font');
      expect(actual.fontWeight, FontWeight.w700);
      expect(actual.foreground, same(paint));
      expect(actual.backgroundColor, Colors.yellow);
      expect(actual.letterSpacing, 2);
      expect(actual.decoration, TextDecoration.underline);
      expect(tester.takeException(), isNull);
    },
  );
}

EditableText _editor(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

Widget _search({
  String query = 'original',
  ValueChanged<String>? onSearch,
  String? label,
  TextStyle? style,
}) => MfmText(
  parsedNodes: [SearchNode(query: query, content: '$query Search')],
  config: MfmRenderConfig(
    onSearchTap: onSearch,
    searchButtonLabel: label,
    baseTextStyle: style,
  ),
);

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

Widget _bare(Widget child) => MediaQuery(
  data: const MediaQueryData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: DefaultTextStyle(
      style: const TextStyle(fontSize: 14),
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  ),
);

class _JapaneseCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const _JapaneseCupertinoLocalizations();

  @override
  String get copyButtonLabel => 'コピー';
}

class _JapaneseCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _JapaneseCupertinoDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(const _JapaneseCupertinoLocalizations());

  @override
  bool shouldReload(_JapaneseCupertinoDelegate old) => false;
}

Future<void> _useFlutterContextMenu(WidgetTester tester) async {
  if (!kIsWeb) return;
  final wasEnabled = BrowserContextMenu.enabled;
  // Flutter's web-test engine ignores platform messages without replying.
  // Acknowledge only menu setup/cleanup, as Flutter's own widget tests do;
  // the actual long-press toolbar and its localization remain under test.
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockMethodCallHandler(SystemChannels.contextMenu, (call) {
      expect(call.method, isIn(['enableContextMenu', 'disableContextMenu']));
      return Future<void>.value();
    });
  addTearDown(() async {
    try {
      if (wasEnabled) {
        await BrowserContextMenu.enableContextMenu();
      } else {
        await BrowserContextMenu.disableContextMenu();
      }
      expect(BrowserContextMenu.enabled, wasEnabled);
    } finally {
      messenger.setMockMethodCallHandler(SystemChannels.contextMenu, null);
    }
  });
  await BrowserContextMenu.disableContextMenu();
  expect(BrowserContextMenu.enabled, isFalse);
}

List<SemanticsNode> _semanticsNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester
        .renderObject(find.byType(MfmText))
        .owner!
        .semanticsOwner!
        .rootSemanticsNode!,
  );
  return nodes;
}
