import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/builder/mfm_node_builder.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_mention.dart';

Widget host(Widget child, {double scale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

const style = TextStyle(fontSize: 20);
const base = MfmRenderConfig(baseTextStyle: style);

void main() {
  testWidgets('document changes retain valid mention semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    final config = base.copyWith(onLinkTap: (_) {}, onMentionTap: (_) {});
    for (final source in [
      'plain',
      '@a',
      'https://example.org',
      '@a',
      '#tag',
      '@a',
    ]) {
      await tester.pumpWidget(host(MfmText(text: source, config: config)));
      expect(tester.takeException(), isNull, reason: source);
    }
  });

  testWidgets('pending avatar retains geometry before and after delivery', (
    tester,
  ) async {
    final completer = Completer<ImageInfo>();
    final provider = _PendingAvatar(completer.future);
    await tester.pumpWidget(
      host(
        MfmText(
          text: '@a',
          config: base.copyWith(
            mentionOptions: MfmMentionOptions(avatarProvider: (_) => provider),
          ),
        ),
      ),
    );
    final before = tester.getRect(find.byType(ClipOval));
    expect(find.byType(RawImage), findsNothing);
    final image = await tester.runAsync(
      () => createTestImage(width: 2, height: 2),
    );
    completer.complete(ImageInfo(image: image!));
    await tester.pump();
    expect(tester.getRect(find.byType(ClipOval)), before);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
  });

  test('built-in image provider is created only for the local origin', () {
    final builder = MfmNodeBuilder(
      config: base.copyWith(
        mentionOptions: const MfmMentionOptions(
          localOrigin: 'https://local.test:8443',
        ),
      ),
      colorScheme: const MfmColorScheme.light(),
      effectiveStyle: style,
    );
    final span =
        builder.buildNode(
              const MentionNode(
                username: 'a',
                host: 'remote.test',
                acct: '@a@remote.test',
              ),
            )
            as WidgetSpan;
    final mention = span.child as MfmMention;
    expect(
      (mention.avatar! as NetworkImage).url,
      'https://local.test:8443/avatar/@a@remote.test',
    );
  });
  testWidgets('text presentation taps both actual name and host glyphs once', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      host(
        MfmText(
          text: '@alice@remote.test',
          config: base.copyWith(
            onMentionTap: calls.add,
            mentionOptions: const MfmMentionOptions(
              presentation: MfmMentionPresentation.text,
            ),
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText).first,
    );
    for (final offset in [1, 9]) {
      final box = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: offset, extentOffset: offset + 1),
          )
          .single;
      await tester.tapAt(paragraph.localToGlobal(box.toRect().center));
    }
    expect(calls, ['@alice@remote.test', '@alice@remote.test']);
  });
  testWidgets('animated rainbow continues filtering the capsule subtree', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const MfmText(text: r'$[rainbow @a]', config: base)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.ancestor(
        of: find.byType(MfmMention),
        matching: find.byType(ColorFiltered),
      ),
      findsWidgets,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'plain display names pass author and URL context but no mention',
    (tester) async {
      MfmEmojiContext? captured;
      await tester.pumpWidget(
        host(
          MfmText(
            text: 'Alice :wave: @alice',
            plain: true,
            nowrap: true,
            config: base.copyWith(
              author: const MfmAuthorContext(host: 'remote.test'),
              emojiUrls: const {'wave': 'https://fixture.invalid/wave.png'},
              emojiBuilder: (name, context) {
                captured = context;
                return const SizedBox.square(dimension: 20);
              },
            ),
          ),
        ),
      );
      expect(captured!.host, 'remote.test');
      expect(captured!.url, Uri.parse('https://fixture.invalid/wave.png'));
      expect(captured!.normal, isTrue);
      expect(find.byType(MfmMention), findsNothing);
      expect(
        tester.widget<RichText>(find.byType(RichText).first).text.toPlainText(),
        contains('@alice'),
      );
    },
  );

  testWidgets('null options defaults to offline capsule and object span', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MfmText(text: '@alice', config: base)));
    final capsule = tester.widget<MfmMention>(find.byType(MfmMention));
    expect(capsule.avatar, isNull);
    expect(capsule.color, const MfmColorScheme.light().mention);
    expect(find.byType(Image), findsNothing);
    final root = tester.widget<RichText>(find.byType(RichText).first);
    expect(root.text.toPlainText(), '￼');
    final span = (root.text as TextSpan).children!.single as WidgetSpan;
    expect(span.alignment, PlaceholderAlignment.baseline);
    expect(span.baseline, TextBaseline.alphabetic);
  });

  testWidgets('avatar, name, host and padding are real single taps', (
    tester,
  ) async {
    final calls = <String>[];
    final providers = <String>[];
    await tester.pumpWidget(
      host(
        MfmText(
          text: '@Alice@REMOTE.test',
          config: base.copyWith(
            onMentionTap: calls.add,
            mentionOptions: MfmMentionOptions(
              avatarProvider: (acct) {
                providers.add(acct);
                return null;
              },
            ),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(MfmMention));
    for (final offset in [
      const Offset(15, 15),
      const Offset(45, 15),
      Offset(rect.width - 20, 15),
      Offset(rect.width - 2, 2),
    ]) {
      await tester.tapAt(rect.topLeft + offset);
      expect(calls.last, '@Alice@REMOTE.test');
    }
    expect(calls, hasLength(4));
    expect(providers, ['@Alice@REMOTE.test']);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('avatar and gap scale once at $scale', (tester) async {
      await tester.pumpWidget(
        host(
          const MfmText(text: '@a', config: base),
          scale: scale,
        ),
      );
      final avatar = find.byType(ClipOval);
      final rect = tester.getRect(avatar);
      expect(rect.width, closeTo(30 * scale, .001));
      expect(rect.height, closeTo(30 * scale, .001));
      final padding = find
          .ancestor(of: avatar, matching: find.byType(Padding))
          .first;
      expect(
        tester.getRect(padding).width - rect.width,
        closeTo(4 * scale, .001),
      );
    });
  }

  for (final width in [0.0, 1.0, 10.0, 90.0, 600.0]) {
    for (final nowrap in [false, true]) {
      testWidgets('finite width $width nowrap $nowrap', (tester) async {
        await tester.pumpWidget(
          host(
            SizedBox(
              width: width,
              child: MfmText(
                text: '@alice@very.long.remote.example',
                config: base,
                nowrap: nowrap,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final box = tester.renderObject<RenderBox>(find.byType(MfmMention));
        expect(
          box.getDryLayout(BoxConstraints(maxWidth: width)).width.isFinite,
          isTrue,
        );
        expect(box.getMaxIntrinsicWidth(double.infinity).isFinite, isTrue);
        expect(
          box.getDryBaseline(
            BoxConstraints(maxWidth: width),
            TextBaseline.alphabetic,
          ),
          isNotNull,
        );
      });
    }
  }
  testWidgets('unbounded and intrinsic parents remain natural width', (
    tester,
  ) async {
    for (final child in [
      const UnconstrainedBox(
        child: MfmText(text: '@alice', config: base),
      ),
      const IntrinsicWidth(
        child: IntrinsicHeight(
          child: MfmText(text: '@alice', config: base),
        ),
      ),
    ]) {
      await tester.pumpWidget(host(child));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(MfmMention)).width, lessThan(300));
    }
  });

  for (final tappable in [false, true]) {
    testWidgets('one full semantics label, tap iff callback $tappable', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var calls = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 60,
            child: MfmText(
              text: '@alice@remote.test',
              config: base.copyWith(
                onMentionTap: tappable ? (_) => calls++ : null,
              ),
            ),
          ),
        ),
      );
      final nodes = tester
          .renderObject(find.byType(MfmMention))
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!;
      final labels = <SemanticsNode>[];
      void visit(SemanticsNode node) {
        if (node.label.contains('@alice')) labels.add(node);
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(nodes);
      expect(labels, hasLength(1));
      expect(labels.single.label, '@alice@remote.test');
      expect(
        labels.single.getSemanticsData().hasAction(SemanticsAction.tap),
        tappable,
      );
      if (tappable) {
        tester
            .renderObject(find.byType(MfmMention))
            .owner!
            .semanticsOwner!
            .performAction(
              labels.single.id,
              SemanticsAction.tap,
            );
        expect(calls, 1);
      }
      semantics.dispose();
    });
  }

  testWidgets('provider null is authoritative; text does not call provider', (
    tester,
  ) async {
    var count = 0;
    final options = MfmMentionOptions(
      localOrigin: 'https://local.test',
      avatarProvider: (_) {
        count++;
        return null;
      },
    );
    await tester.pumpWidget(
      host(
        MfmText(
          text: '@a',
          config: base.copyWith(mentionOptions: options),
        ),
      ),
    );
    expect(count, 1);
    expect(find.byType(Image), findsNothing);
    await tester.pumpWidget(
      host(
        MfmText(
          text: '@a@remote.test',
          config: base.copyWith(
            mentionOptions: MfmMentionOptions(
              presentation: MfmMentionPresentation.text,
              localOrigin: options.localOrigin,
              avatarProvider: options.avatarProvider,
            ),
          ),
        ),
      ),
    );
    expect(count, 1);
    expect(find.byType(MfmMention), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('origin-only fallback does not change raw callback or provider', (
    tester,
  ) async {
    final calls = <String>[];
    final providers = <String>[];
    await tester.pumpWidget(
      host(
        MfmText(
          text: '@a',
          config: base.copyWith(
            onMentionTap: calls.add,
            mentionOptions: MfmMentionOptions(
              localOrigin: 'https://local.test',
              avatarProvider: (acct) {
                providers.add(acct);
                return null;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(MfmMention));
    expect(calls, ['@a']);
    expect(providers, ['@a']);
  });

  for (final source in [
    '@a',
    '<small>@a</small>',
    '<small><small>@a</small></small>',
    '> @a',
    r'$[fg.ff000080 @a]',
    r'$[rainbow @a]',
  ]) {
    testWidgets('capsule role color and one cumulative opacity: $source', (
      tester,
    ) async {
      const color = Color(0x8086B300);
      final paint = Paint()..color = const Color(0x80445566);
      await tester.pumpWidget(
        host(
          MfmText(
            text: source,
            config: base.copyWith(
              enableAnimation: false,
              baseTextStyle: TextStyle(fontSize: 20, foreground: paint),
              lightColorScheme: const MfmColorScheme.light(mention: color),
            ),
          ),
        ),
      );
      final mention = tester.widget<MfmMention>(find.byType(MfmMention));
      expect(mention.color, color);
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(MfmMention),
          matching: find.byType(Text),
        ),
      );
      final textStyle = text.textSpan!.style!;
      expect(
        (textStyle.foreground?.color ?? textStyle.color)!.toARGB32(),
        color.toARGB32(),
      );
      expect(textStyle.foreground?.shader, isNull);
      expect(paint.color.toARGB32(), 0x80445566);
      final opacity = tester.widgetList<Opacity>(
        find.ancestor(
          of: find.byType(MfmMention),
          matching: find.byType(Opacity),
        ),
      );
      if (source.startsWith('<small>')) {
        expect(opacity, hasLength(1));
        expect(
          opacity.single.opacity,
          closeTo(source.contains('<small><small>') ? .49 : .7, .001),
        );
      }
    });
  }

  testWidgets('viewer role and parsed IPv6 content', (tester) async {
    await tester.pumpWidget(
      host(
        MfmText(
          parsedNodes: const [
            MentionNode(
              username: 'Alice',
              host: '[2001:db8::1]',
              acct: '@Alice@[2001:db8::1]',
            ),
          ],
          config: base.copyWith(
            localHost: '[2001:0db8:0:0:0:0:0:1]',
            mentionOptions: const MfmMentionOptions(
              viewerAcct: '@alice@[2001:db8::1]',
            ),
          ),
        ),
      ),
    );
    final mention = tester.widget<MfmMention>(find.byType(MfmMention));
    expect(mention.host, isEmpty);
    expect(mention.color, const MfmColorScheme.light().mentionMe);
  });

  testWidgets('memory image and failed image retain avatar geometry', (
    tester,
  ) async {
    final png = (await tester.runAsync(() async {
      final image = await createTestImage(width: 2, height: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    }))!;
    for (final bytes in [
      png,
      Uint8List.fromList([1, 2, 3]),
    ]) {
      await tester.pumpWidget(
        host(
          MfmText(
            text: '@a',
            config: base.copyWith(
              mentionOptions: MfmMentionOptions(
                avatarProvider: (_) => MemoryImage(bytes),
              ),
            ),
          ),
        ),
      );
      final before = tester.getSize(find.byType(ClipOval));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ClipOval)), before);
      expect(before, const Size(30, 30));
      if (identical(bytes, png)) {
        expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      } else {
        expect(find.byType(RawImage), findsNothing);
      }
    }
  });
}

class _PendingAvatar extends ImageProvider<_PendingAvatar> {
  const _PendingAvatar(this.future);
  final Future<ImageInfo> future;

  @override
  Future<_PendingAvatar> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingAvatar key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(future);
}
