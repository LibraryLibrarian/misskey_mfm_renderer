import 'package:example/features/catalog/data/mfm_examples.dart';
import 'package:example/features/playground/application/playground_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlaygroundController controller;
  final examples = MfmExamples.categories.expand((c) => c.examples);
  final displayName = examples.singleWhere((e) => e.name == 'Display Name');
  final bold = examples.singleWhere((e) => e.name == 'Bold');

  setUp(() => controller = PlaygroundController());
  tearDown(() => controller.dispose());

  test('load, edit, clear and release preserve the intended state', () {
    expect(controller.needsDiscardConfirmation, isFalse);
    controller.load(displayName);
    expect(controller.example, same(displayName));
    expect(controller.text, displayName.mfm);
    expect(controller.needsDiscardConfirmation, isFalse);

    controller.editor.text = 'edited';
    expect(controller.needsDiscardConfirmation, isTrue);
    expect(controller.example, same(displayName));
    controller.clearText();
    expect(controller.text, isEmpty);
    expect(controller.example, same(displayName));
    expect(controller.needsDiscardConfirmation, isFalse);
    controller.editor.text = displayName.mfm;
    expect(controller.needsDiscardConfirmation, isTrue);

    const selection = TextSelection(baseOffset: 1, extentOffset: 3);
    controller.editor.selection = selection;
    controller.releaseOverrides();
    expect(controller.text, displayName.mfm);
    expect(controller.editor.selection, selection);
    expect(controller.example, isNull);
  });

  test('same example reloads and another example replaces all overrides', () {
    controller.load(displayName);
    final revision = controller.loadRevision;
    controller.editor.text = 'edit';
    controller.load(displayName);
    expect(controller.loadRevision, revision + 1);
    expect(controller.text, displayName.mfm);
    expect(controller.needsDiscardConfirmation, isFalse);
    controller.load(bold);
    expect(controller.example, same(bold));
    expect(controller.example!.config, isNull);
    expect(controller.example!.plain, isNull);
    expect(controller.example!.nowrap, isNull);
    controller.editor.clear();
    expect(controller.needsDiscardConfirmation, isFalse);
  });

  test('selection and composing changes do not notify the preview', () {
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.editor.selection = const TextSelection.collapsed(offset: 1);
    controller.editor.value = controller.editor.value.copyWith(
      composing: const TextRange(start: 0, end: 1),
    );
    expect(notifications, 0);
    controller.editor.text = 'changed';
    expect(notifications, 1);
    controller.load(bold);
    expect(notifications, 2);
    controller.load(bold);
    expect(notifications, 3);
  });
}
