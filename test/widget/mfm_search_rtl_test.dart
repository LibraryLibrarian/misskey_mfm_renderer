import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_search.dart';

Future<void> _pumpSearch(WidgetTester tester, TextDirection direction) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: MfmText(
            text: '検索語 検索',
            config: MfmRenderConfig(onSearchTap: (_) {}),
          ),
        ),
      ),
    ),
  );
  expect(find.byType(MfmSearch), findsOneWidget);
  expect(find.byType(CupertinoTextField), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Finder get _button => find.descendant(
  of: find.descendant(
    of: find.byType(MfmSearch),
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.button == true,
    ),
  ),
  matching: find.byWidgetPredicate(
    (widget) => widget is Container && widget.decoration is BoxDecoration,
  ),
);

// BoxBorder resolves logical edges while painting rather than exposing resolve.
Border _resolveBorder(BoxBorder border, TextDirection direction) {
  if (border is Border) return border;
  final directional = border as BorderDirectional;
  final rtl = direction == TextDirection.rtl;
  return Border(
    top: directional.top,
    bottom: directional.bottom,
    left: rtl ? directional.end : directional.start,
    right: rtl ? directional.start : directional.end,
  );
}

void main() {
  for (final direction in TextDirection.values) {
    final rtl = direction == TextDirection.rtl;
    final name = rtl ? 'RTL' : 'LTR';

    testWidgets('$name search field rounds only its outer edge', (
      tester,
    ) async {
      await _pumpSearch(tester, direction);
      final field = find.byType(CupertinoTextField);
      expect(_button, findsOneWidget);
      final fieldBounds = tester.getRect(field);
      final buttonBounds = tester.getRect(_button);
      expect(
        rtl ? buttonBounds.right : fieldBounds.right,
        closeTo(rtl ? fieldBounds.left : buttonBounds.left, 0.001),
        reason: 'The field and button must meet in the requested direction.',
      );
      final decoration = tester.widget<CupertinoTextField>(field).decoration!;
      expect(
        decoration.borderRadius!.resolve(direction),
        rtl
            ? const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
      );
      expect(_resolveBorder(decoration.border!, direction).isUniform, isTrue);
      expect(
        _resolveBorder(decoration.border!, direction).top.style,
        BorderStyle.solid,
      );
    });

    testWidgets('$name search button rounds only its outer edge', (
      tester,
    ) async {
      await _pumpSearch(tester, direction);
      expect(_button, findsOneWidget);
      final decoration =
          tester.widget<Container>(_button).decoration! as BoxDecoration;
      expect(
        decoration.borderRadius!.resolve(direction),
        rtl
            ? const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              )
            : const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
      );
    });

    testWidgets(
      '$name search button borders outer edge without doubling seam',
      (tester) async {
        await _pumpSearch(tester, direction);
        expect(_button, findsOneWidget);
        final decoration =
            tester.widget<Container>(_button).decoration! as BoxDecoration;
        final border = _resolveBorder(decoration.border!, direction);
        expect(
          [border.top.style, border.bottom.style],
          [BorderStyle.solid, BorderStyle.solid],
        );
        expect(
          [border.left, border.right],
          rtl ? [border.top, BorderSide.none] : [BorderSide.none, border.top],
          reason:
              'Only the outer edge needs a button border; the field already '
              'draws the shared seam.',
        );
      },
    );
  }
}
