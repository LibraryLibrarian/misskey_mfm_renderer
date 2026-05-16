import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  group('nyaize / ja-JP', () {
    test('「な」を「にゃ」に置換する', () {
      expect(nyaize('なにぬねの'), 'にゃにぬねの');
    });

    test('全角カタカナ「ナ」を「ニャ」に置換する', () {
      expect(nyaize('ナニヌネノ'), 'ニャニヌネノ');
    });

    test('半角カタカナ「ﾅ」を「ﾆｬ」に置換する', () {
      expect(nyaize('ﾅﾆﾇﾈﾉ'), 'ﾆｬﾆﾇﾈﾉ');
    });

    test('複数箇所を一括で置換する', () {
      expect(nyaize('あなたとなかよく'), 'あにゃたとにゃかよく');
    });
  });

  group('nyaize / en-US', () {
    test('「n」の直後の「a」を「ya」に置換する', () {
      // b-a は対象外（直前がbのため）。n-a は2箇所とも対象。
      expect(nyaize('banana'), 'banyanya');
    });

    test('大文字「A」を「YA」、小文字「a」を「ya」に置換する', () {
      expect(nyaize('NAna'), 'NYAnya');
    });

    test('「morning」を「mornyan」に置換する', () {
      expect(nyaize('morning'), 'mornyan');
    });

    test('全大文字「MORNING」を「MORNYAN」に置換する', () {
      expect(nyaize('MORNING'), 'MORNYAN');
    });

    test('「everyone」を「everynyan」に置換する', () {
      expect(nyaize('everyone'), 'everynyan');
    });

    test('全大文字「EVERYONE」を「EVERYNYAN」に置換する', () {
      expect(nyaize('EVERYONE'), 'EVERYNYAN');
    });

    test('「n」を伴わない「a」は置換しない', () {
      expect(nyaize('apple'), 'apple');
    });
  });

  group('nyaize / ko-KR', () {
    test('「나」を「냐」に置換する', () {
      expect(nyaize('나'), '냐');
    });

    test('「낳」を「냫」に置換する（範囲端）', () {
      expect(nyaize('낳'), '냫');
    });

    test('文末の「다」を「다냥」に置換する', () {
      expect(nyaize('먹는다'), '먹는다냥');
    });

    test('ピリオド直前の「다」を「다냥」に置換する', () {
      expect(nyaize('먹는다.'), '먹는다냥.');
    });

    test('文末の「야」を「냥」に置換する', () {
      expect(nyaize('뭐야'), '뭐냥');
    });

    test('?直前の「야」を「냥」に置換する', () {
      expect(nyaize('뭐야?'), '뭐냥?');
    });
  });

  group('nyaize / 副作用がない', () {
    test('対象文字を含まない文字列は変化しない', () {
      expect(nyaize('hello world'), 'hello world');
    });

    test('空文字は空文字のまま', () {
      expect(nyaize(''), '');
    });
  });
}
