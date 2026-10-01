import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

List<SemanticsNode> _mentionNodes(WidgetTester tester) {
  final root = tester
      .renderObject(find.byType(MfmText))
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  final result = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    if (node.label.contains('@')) result.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return result;
}

Widget _host(String text, ValueChanged<String>? onTap, bool animation) =>
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 90,
          child: MfmText(
            text: text,
            config: MfmRenderConfig(
              baseTextStyle: const TextStyle(fontSize: 20),
              enableAnimation: animation,
              onMentionTap: onTap,
              mentionOptions: const MfmMentionOptions(
                presentation: MfmMentionPresentation.text,
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  for (final profile in [
    (template: 'BODY', animation: false),
    (template: '> BODY', animation: false),
    (template: r'$[rainbow BODY]', animation: false),
    (template: r'$[rainbow BODY]', animation: true),
  ]) {
    testWidgets('single text mention semantics: $profile', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final calls = <String>[];
        for (final tappable in [false, true, false]) {
          await tester.pumpWidget(
            _host(
              profile.template.replaceAll('BODY', '@alice@remote.test'),
              tappable ? calls.add : null,
              profile.animation,
            ),
          );
          expect(tester.takeException(), isNull);
          final nodes = _mentionNodes(tester);
          expect(nodes, hasLength(1));
          expect(nodes.single.label, '@alice@remote.test');
          expect(
            nodes.single.getSemanticsData().hasAction(SemanticsAction.tap),
            tappable,
          );
          if (tappable) {
            tester
                .renderObject(find.byType(MfmText))
                .owner!
                .semanticsOwner!
                .performAction(nodes.single.id, SemanticsAction.tap);
          }
        }
        expect(calls, ['@alice@remote.test']);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('adjacent mentions keep separate full labels and actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          'start @alice@remote.test mid @bob@other.test end',
          calls.add,
          false,
        ),
      );
      final nodes = _mentionNodes(tester);
      expect(nodes.map((node) => node.label), [
        '@alice@remote.test',
        '@bob@other.test',
      ]);
      final owner = tester
          .renderObject(find.byType(MfmText))
          .owner!
          .semanticsOwner!;
      for (final node in nodes) {
        owner.performAction(node.id, SemanticsAction.tap);
      }
      expect(calls, ['@alice@remote.test', '@bob@other.test']);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
