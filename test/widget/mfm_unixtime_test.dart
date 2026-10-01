import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_parser/misskey_mfm_parser.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_rainbow_text.dart';
import 'package:misskey_mfm_renderer/src/utils/unixtime_scheduler.dart';
import 'package:misskey_mfm_renderer/src/widgets/mfm_unixtime_label.dart';

Widget host({
  String text = r'$[unixtime 0]',
  MfmUnixtimeOptions? options,
  Locale? locale,
  bool nowrap = false,
  bool animation = false,
  double width = 500,
}) {
  Widget child = Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(
        width: width,
        child: MfmText(
          text: text,
          nowrap: nowrap,
          config: MfmRenderConfig(
            enableAnimation: animation,
            unixtimeOptions: options,
          ),
        ),
      ),
    ),
  );
  if (locale != null) {
    child = Localizations(
      locale: locale,
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: child,
    );
  }
  return child;
}

void main() {
  Future<void> resume(WidgetTester tester) async {
    final previous = tester.binding.lifecycleState;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.binding.handleAppLifecycleStateChanged(
        previous ?? AppLifecycleState.detached,
      );
    });
  }

  testWidgets('minimal host, prefix and invalid retain a decorative clock', (
    tester,
  ) async {
    for (final source in ['0suffix', 'bad', '8640000000001']) {
      await tester.pumpWidget(host(text: '\$[unixtime $source]'));
      expect(find.byType(Icon), findsOneWidget);
      expect(
        find.text('None'),
        source == '0suffix' ? findsNothing : findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byType(Icon),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'locale precedence, ambient changes, unsupported custom context',
    (tester) async {
      const absolute = MfmUnixtimeOptions(mode: MfmUnixtimeMode.absolute);
      await tester.pumpWidget(
        host(options: absolute, locale: const Locale('ja')),
      );
      expect(tester.widget<Text>(find.byType(Text)).data, contains('1970/1/1'));
      await tester.pumpWidget(
        host(options: absolute, locale: const Locale('en', 'GB')),
      );
      expect(
        tester.widget<Text>(find.byType(Text)).data,
        contains('1/1/1970,'),
      );
      await tester.pumpWidget(
        host(
          options: const MfmUnixtimeOptions(
            mode: MfmUnixtimeMode.absolute,
            locale: Locale('ja'),
          ),
          locale: const Locale('en'),
        ),
      );
      expect(tester.widget<Text>(find.byType(Text)).data, contains('1970/1/1'));
      MfmUnixtimeFormatContext? received;
      await tester.pumpWidget(
        host(
          options: MfmUnixtimeOptions(
            locale: const Locale('fr', 'CA'),
            formatter: (context) {
              received = context;
              return 'custom';
            },
            autoUpdate: false,
          ),
        ),
      );
      expect(received!.locale, const Locale('fr', 'CA'));
      expect(received!.dateTime!.isUtc, isFalse);
      expect(received!.mode, MfmUnixtimeMode.detail);
      await tester.pumpWidget(
        host(
          text: r'$[unixtime bad]',
          options: MfmUnixtimeOptions(
            formatter: (context) {
              expect(context.dateTime, isNull);
              return 'invalid custom';
            },
          ),
        ),
      );
      expect(find.text('invalid custom'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('locale and widget updates format once per frame', (
    tester,
  ) async {
    var reads = 0;
    final formatted = <String>[];
    MfmUnixtimeOptions options(MfmUnixtimeMode mode) => MfmUnixtimeOptions(
      mode: mode,
      autoUpdate: false,
      now: () => DateTime.fromMillisecondsSinceEpoch(++reads * 1000),
      formatter: (context) {
        final label =
            '${context.locale.languageCode}:${context.mode.name}:'
            '${context.now.millisecondsSinceEpoch}';
        formatted.add(label);
        return label;
      },
    );
    final detail = options(MfmUnixtimeMode.detail);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

    await tester.pumpWidget(host(options: detail, locale: const Locale('en')));
    expect(formatted, ['en:detail:1000']);
    final state = tester.state(find.byType(MfmUnixtimeLabel));

    // localeはMfmTextとlabel両方の依存関係を同時に変更する。
    await tester.pumpWidget(host(options: detail, locale: const Locale('ja')));
    expect(formatted, ['en:detail:1000', 'ja:detail:2000']);
    expect(tester.state(find.byType(MfmUnixtimeLabel)), same(state));

    await tester.pumpWidget(
      host(
        options: options(MfmUnixtimeMode.absolute),
        locale: const Locale('ja'),
      ),
    );
    expect(formatted, ['en:detail:1000', 'ja:detail:2000', 'ja:absolute:3000']);
    expect(reads, 3);
    expect(find.text('ja:absolute:3000'), findsOneWidget);
  });

  testWidgets('dependencies-only update formats a retained label once', (
    tester,
  ) async {
    var reads = 0;
    var formats = 0;
    final label = MfmUnixtimeLabel(
      timestamp: 0,
      options: MfmUnixtimeOptions(
        autoUpdate: false,
        now: () => DateTime.fromMillisecondsSinceEpoch(++reads * 1000),
        formatter: (context) {
          formats++;
          return '${context.locale.languageCode}:$formats';
        },
      ),
      style: const TextStyle(fontSize: 14),
      nowrap: false,
      rainbowScope: null,
      rainbowForeground: false,
    );
    Widget localized(Locale locale) => Localizations(
      locale: locale,
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: Directionality(textDirection: TextDirection.ltr, child: label),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

    await tester.pumpWidget(localized(const Locale('en')));
    expect(find.text('en:1'), findsOneWidget);
    await tester.pumpWidget(localized(const Locale('ja')));
    expect(find.text('ja:2'), findsOneWidget);
    expect(reads, 2);
    expect(formats, 2);
    expect(tester.widget(find.byType(MfmUnixtimeLabel)), same(label));
  });

  testWidgets(
    'options inherit whole, explicit empty resets, clear inherits again',
    (tester) async {
      const inherited = MfmRenderConfig(
        unixtimeOptions: MfmUnixtimeOptions(
          locale: Locale('ja'),
          mode: MfmUnixtimeMode.absolute,
        ),
      );
      for (final config in [
        const MfmRenderConfig(),
        const MfmRenderConfig(unixtimeOptions: MfmUnixtimeOptions()),
        const MfmRenderConfig(
          unixtimeOptions: MfmUnixtimeOptions(),
        ).copyWith(clearUnixtimeOptions: true),
      ]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MfmConfig(
              config: inherited,
              child: MfmText(text: r'$[unixtime bad]', config: config),
            ),
          ),
        );
        expect(
          find.text(config.unixtimeOptions == null ? '日時の解析に失敗' : 'None'),
          findsOneWidget,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'shared 10s cadence updates labels, not parent, under TickerMode off',
    (tester) async {
      await resume(tester);
      var now = DateTime.fromMillisecondsSinceEpoch(0);
      var reads = 0;
      final options = MfmUnixtimeOptions(
        mode: MfmUnixtimeMode.relative,
        now: () {
          reads++;
          return now;
        },
      );
      await tester.pumpWidget(
        TickerMode(
          enabled: false,
          child: host(text: r'$[unixtime 0] $[unixtime 0]', options: options),
        ),
      );
      expect(reads, 2);
      final parent = tester.element(find.byType(MfmText));
      final root = tester.widget<RichText>(find.byType(RichText).first);
      final labels = tester.stateList(find.byType(MfmUnixtimeLabel)).toList();
      now = now.add(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 9999));
      expect(reads, 2);
      await tester.pump(const Duration(milliseconds: 1));
      expect(reads, 4);
      expect(find.text('10s ago'), findsNWidgets(2));
      expect(tester.element(find.byType(MfmText)), same(parent));
      expect(tester.widget<RichText>(find.byType(RichText).first), same(root));
      expect(tester.stateList(find.byType(MfmUnixtimeLabel)).toList(), labels);
      final text = tester.widget<Text>(find.byType(Text).first);
      await tester.pump(const Duration(seconds: 10));
      expect(reads, 6);
      expect(tester.widget<Text>(find.byType(Text).first), same(text));
      // 巻戻しもtickの実時計から再計算する。
      now = DateTime.fromMillisecondsSinceEpoch(0);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Just now'), findsNWidgets(2));
    },
  );

  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.detached,
  ]) {
    testWidgets(
      'first and additional mount while $state do not tick until resume',
      (tester) async {
        await resume(tester);
        tester.binding.handleAppLifecycleStateChanged(state);
        var reads = 0;
        var now = DateTime.fromMillisecondsSinceEpoch(0);
        final options = MfmUnixtimeOptions(
          mode: MfmUnixtimeMode.relative,
          now: () {
            reads++;
            return now;
          },
        );
        await tester.pumpWidget(host(options: options));
        tester.binding.scheduleForcedFrame();
        await tester.pump();
        await tester.pump(const Duration(seconds: 30));
        expect(reads, 1);
        await tester.pumpWidget(
          host(text: r'$[unixtime 0] $[unixtime 0]', options: options),
        );
        tester.binding.scheduleForcedFrame();
        await tester.pump();
        final initial = reads;
        now = now.add(const Duration(seconds: 40));
        await tester.pump(const Duration(seconds: 30));
        expect(reads, initial);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(reads, initial + 2);
        expect(find.text('40s ago'), findsNWidgets(2));
        await tester.pump(const Duration(seconds: 10));
        expect(reads, initial + 4);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump(const Duration(seconds: 10));
        expect(reads, initial + 6);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump(const Duration(seconds: 30));
        expect(reads, initial + 6);
      },
    );
  }

  testWidgets(
    'dynamic options and validity reconcile subscription',
    (tester) async {
      await resume(tester);
      var reads = 0;
      var alternateReads = 0;
      DateTime clock() {
        reads++;
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      for (final sample in [
        (MfmUnixtimeMode.absolute, true, '0', false),
        (MfmUnixtimeMode.relative, true, 'bad', false),
        (MfmUnixtimeMode.relative, false, '0', false),
        (MfmUnixtimeMode.detail, true, '0', true),
        (MfmUnixtimeMode.relative, true, '10', true),
      ]) {
        await tester.pumpWidget(
          host(
            text: '\$[unixtime ${sample.$3}]',
            options: MfmUnixtimeOptions(
              mode: sample.$1,
              autoUpdate: sample.$2,
              now: clock,
            ),
          ),
        );
        final before = reads;
        await tester.pump(const Duration(seconds: 10));
        expect(reads, before + (sample.$4 ? 1 : 0));
      }
      await tester.pumpWidget(
        host(
          options: MfmUnixtimeOptions(
            now: () {
              alternateReads++;
              return DateTime.fromMillisecondsSinceEpoch(100000);
            },
          ),
        ),
      );
      final previous = reads;
      await tester.pump(const Duration(seconds: 10));
      expect(reads, previous);
      expect(alternateReads, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 30));
      expect(alternateReads, 2);
      // 新規mountは共有時計の古い値ではなく、その時点のclockを使う。
      await tester.pumpWidget(
        host(
          options: MfmUnixtimeOptions(
            mode: MfmUnixtimeMode.relative,
            now: () => DateTime.fromMillisecondsSinceEpoch(70000),
          ),
        ),
      );
      expect(find.text('1m ago'), findsOneWidget);
    },
  );

  testWidgets(
    'scheduler creates one timer and removes listeners safely during dispatch',
    (tester) async {
      await resume(tester);
      final scheduler = UnixtimeScheduler.instance;
      var timers = 0;
      final delivered = <DateTime>[];
      void second(DateTime now) => delivered.add(now);
      void first(DateTime now) {
        delivered.add(now);
        scheduler.unsubscribe(second);
      }

      void third(DateTime now) => delivered.add(now);
      runZoned(
        () {
          scheduler
            ..subscribe(first)
            ..subscribe(second)
            ..subscribe(third);
        },
        zoneSpecification: ZoneSpecification(
          createPeriodicTimer: (self, parent, zone, duration, callback) {
            timers++;
            return parent.createPeriodicTimer(zone, duration, callback);
          },
        ),
      );
      expect(timers, 1);
      await tester.pump(const Duration(seconds: 10));
      expect(delivered.length, 2);
      expect(delivered.first, same(delivered.last));
      scheduler
        ..unsubscribe(first)
        ..unsubscribe(third);
      await tester.pump(const Duration(seconds: 20));
      expect(delivered.length, 2);
    },
  );

  testWidgets(
    'nowrap semantics, wrapping and isolated child',
    (tester) async {
      await resume(tester);
      final semantics = tester.ensureSemantics();

      var now = DateTime.fromMillisecondsSinceEpoch(0);
      final options = MfmUnixtimeOptions(now: () => now);
      await tester.pumpWidget(host(width: 180, nowrap: true, options: options));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(find.bySemanticsLabel(text.data!), findsOneWidget);
      now = now.add(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 10));
      expect(
        find.bySemanticsLabel(tester.widget<Text>(find.byType(Text)).data!),
        findsOneWidget,
      );
      await tester.pumpWidget(host(width: 180, options: options));
      expect(tester.widget<Text>(find.byType(Text)).maxLines, isNull);
      expect(tester.getSize(find.byType(Text)).height, greaterThan(20));
      expect(tester.takeException(), isNull);
      final rich = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere(
            (rich) =>
                rich.text is TextSpan &&
                (rich.text as TextSpan).children?.any(
                      (span) => span is WidgetSpan,
                    ) ==
                    true,
          );
      final child =
          ((rich.text as TextSpan).children!.firstWhere(
                    (span) => span is WidgetSpan,
                  )
                  as WidgetSpan)
              .child;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: UnconstrainedBox(child: child),
        ),
      );
      expect(find.byType(Text), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('first child only through direct nodes and public parser', (
    tester,
  ) async {
    for (final children in <List<MfmNode>>[
      [],
      const [TextNode('bad'), TextNode('0')],
      const [
        BoldNode([TextNode('0')]),
        TextNode('0'),
      ],
    ]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MfmText(
            parsedNodes: [
              FnNode(name: 'unixtime', args: const {}, children: children),
            ],
          ),
        ),
      );
      expect(find.text('None'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    }
    for (final input in ['**0**0', 'not-a-date', '1700000000suffix', '0x10']) {
      await tester.pumpWidget(host(text: '\$[unixtime $input]'));
      expect(find.byType(Icon), findsOneWidget);
      expect(
        find.text('None'),
        input.startsWith('**') || input == 'not-a-date'
            ? findsOneWidget
            : findsNothing,
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final animation in [false, true]) {
    testWidgets(
      'rainbow keeps state and scope across clock ticks: $animation',
      (tester) async {
        await resume(tester);
        var now = DateTime.fromMillisecondsSinceEpoch(0);
        await tester.pumpWidget(
          host(
            text: r'$[rainbow <small>$[unixtime 0]</small>]',
            animation: animation,
            options: MfmUnixtimeOptions(
              mode: MfmUnixtimeMode.relative,
              now: () => now,
            ),
          ),
        );
        final state = tester.state(find.byType(MfmUnixtimeLabel));
        final scope = tester
            .widget<MfmUnixtimeLabel>(find.byType(MfmUnixtimeLabel))
            .rainbowScope;
        now = now.add(const Duration(seconds: 10));
        await tester.pump(const Duration(seconds: 10));
        expect(tester.state(find.byType(MfmUnixtimeLabel)), same(state));
        expect(
          tester
              .widget<MfmUnixtimeLabel>(find.byType(MfmUnixtimeLabel))
              .rainbowScope,
          same(scope),
        );
        final rich = tester.widget<RichText>(
          find.descendant(
            of: find.byType(MfmUnixtimeLabel),
            matching: find.byWidgetPredicate((widget) => widget is RichText),
          ),
        );
        expect(rich.text.toPlainText(), '10s ago');
        if (!animation) {
          expect(scope, isNotNull);
          expect(find.byType(MfmRainbowText), findsOneWidget);
          expect(rich.text, isA<MfmRainbowSpan>());
          expect((rich.text as MfmRainbowSpan).opacity, closeTo(0.7, 1e-6));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('actual glyph baseline matches at scale $scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: host(
            width: 780,
            text: r'abc$[unixtime 0]ghi',
            options: const MfmUnixtimeOptions(mode: MfmUnixtimeMode.absolute),
          ),
        ),
      );
      final label = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(MfmUnixtimeLabel),
          matching: find.byType(RichText),
        ),
      );
      final outer = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere(
            (paragraph) => paragraph.text.toPlainText().startsWith('abc'),
          );
      double glyphBaseline(RenderParagraph paragraph) {
        const selection = TextSelection(baseOffset: 0, extentOffset: 1);
        final glyph = paragraph.getBoxesForSelection(selection).first;
        final painter = TextPainter(
          text: TextSpan(
            text: paragraph.text.toPlainText()[0],
            style: paragraph.text.style,
          ),
          textDirection: TextDirection.ltr,
          textScaler: paragraph.textScaler,
        )..layout();
        final offset =
            painter.computeLineMetrics().first.baseline -
            painter.getBoxesForSelection(selection).first.top;
        painter.dispose();
        return paragraph.localToGlobal(Offset(0, glyph.top + offset)).dy;
      }

      // Flutterの行高の整数丸めによる半pixel以内の差だけを許容する。
      expect(glyphBaseline(label), closeTo(glyphBaseline(outer), 0.5));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
