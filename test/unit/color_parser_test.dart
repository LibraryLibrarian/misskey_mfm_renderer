import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/src/utils/color_parser.dart';

void main() {
  group('ColorParser', () {
    group('parse', () {
      group('6桁の16進カラー', () {
        test('先頭に#がある場合、正しくパースできる', () {
          final color = ColorParser.parse('#FF0000');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFFFF0000)));
        });

        test('先頭に#がない場合、正しくパースできる', () {
          final color = ColorParser.parse('00FF00');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFF00FF00)));
        });

        test('小文字でも正しくパースできる', () {
          final color = ColorParser.parse('#ff00ff');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFFFF00FF)));
        });

        test('大文字小文字混合でも正しくパースできる', () {
          final color = ColorParser.parse('#aAbBcC');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFFAABBCC)));
        });

        test('白色（#FFFFFF）をパースできる', () {
          final color = ColorParser.parse('#FFFFFF');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFFFFFFFF)));
        });

        test('黒色（#000000）をパースできる', () {
          final color = ColorParser.parse('#000000');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFF000000)));
        });
      });

      group('3桁の16進カラー（短縮形式）', () {
        test('3桁のカラーコードが6桁に展開される', () {
          final color = ColorParser.parse('#F00');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFFFF0000)));
        });

        test('先頭に#がない3桁でもパースできる', () {
          final color = ColorParser.parse('0F0');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFF00FF00)));
        });

        test('小文字3桁でもパースできる', () {
          final color = ColorParser.parse('#abc');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFFAABBCC)));
        });

        test('白色（#FFF）をパースできる', () {
          final color = ColorParser.parse('#FFF');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFFFFFFFF)));
        });

        test('黒色（#000）をパースできる', () {
          final color = ColorParser.parse('#000');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFF000000)));
        });
      });

      group('アルファ値', () {
        test('アルファ値は常に0xFF（完全不透明）になる', () {
          final color = ColorParser.parse('#123456');
          expect(color, isNotNull);
          // color.a は 0.0〜1.0 の範囲なので、1.0（完全不透明）であることを確認
          expect(color!.a, equals(1.0));
        });
      });

      group('無効な入力', () {
        test('空文字列はnullを返す', () {
          final color = ColorParser.parse('');
          expect(color, isNull);
        });

        test('#のみの場合はnullを返す', () {
          final color = ColorParser.parse('#');
          expect(color, isNull);
        });

        test('1桁の16進数はnullを返す', () {
          final color = ColorParser.parse('#F');
          expect(color, isNull);
        });

        test('2桁の16進数はnullを返す', () {
          final color = ColorParser.parse('#FF');
          expect(color, isNull);
        });

        test('4桁の16進数はnullを返す', () {
          final color = ColorParser.parse('#FFFF');
          expect(color, isNull);
        });

        test('5桁の16進数はnullを返す', () {
          final color = ColorParser.parse('#FFFFF');
          expect(color, isNull);
        });

        test('7桁の16進数はnullを返す', () {
          final color = ColorParser.parse('#FFFFFFF');
          expect(color, isNull);
        });

        test('8桁の16進数（ARGB形式）はnullを返す', () {
          final color = ColorParser.parse('#FFFFFFFF');
          expect(color, isNull);
        });

        test('16進数以外の文字が含まれる場合はnullを返す', () {
          final color = ColorParser.parse('#GGHHII');
          expect(color, isNull);
        });

        test('スペースが含まれる場合はnullを返す', () {
          final color = ColorParser.parse('# FF0000');
          expect(color, isNull);
        });

        test('特殊文字が含まれる場合はnullを返す', () {
          final color = ColorParser.parse('#FF@000');
          expect(color, isNull);
        });

        test('rgb()形式はサポートしない', () {
          final color = ColorParser.parse('rgb(255, 0, 0)');
          expect(color, isNull);
        });

        test('色名はサポートしない', () {
          final color = ColorParser.parse('red');
          expect(color, isNull);
        });
      });

      group('エッジケース', () {
        test('複数の#がある場合、最初の#のみ除去される', () {
          // ##FF0000 -> #FF0000（不正な文字として扱われる）
          final color = ColorParser.parse('##FF0000');
          expect(color, isNull);
        });

        test('末尾に#がある場合、replaceFirstで除去されパース可能', () {
          // FF0000# -> FF0000（最初の#が除去される）
          final color = ColorParser.parse('FF0000#');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFFFF0000)));
        });

        test('途中に#がある場合は無効な文字として扱われる', () {
          final color = ColorParser.parse('FF#000');
          expect(color, isNull);
        });
      });

      group('Misskey MFMでよく使用される色', () {
        test('Misskeyテーマカラー（緑系）', () {
          final color = ColorParser.parse('#86B300');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFF86B300)));
        });

        test('警告色（オレンジ）', () {
          final color = ColorParser.parse('#FFA500');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFFFFA500)));
        });

        test('エラー色（赤）', () {
          final color = ColorParser.parse('#E53935');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFFE53935)));
        });

        test('リンク色（青）', () {
          final color = ColorParser.parse('#0066CC');
          expect(color, isNotNull);
          expect(color, equals(const Color(0xFF0066CC)));
        });
      });
    });
  });
}
