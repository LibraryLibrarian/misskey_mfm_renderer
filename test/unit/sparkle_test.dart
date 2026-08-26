import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/src/fn/animated/mfm_sparkle_widget.dart';

void main() {
  group('sparkle particle metrics', () {
    test('1つのsizeFactorから本家と同じサイズと寿命を導く', () {
      final minimum = MfmSparkleWidget.debugParticleMetrics(0);
      final middle = MfmSparkleWidget.debugParticleMetrics(0.5);
      final maximum = MfmSparkleWidget.debugParticleMetrics(1);

      expect(minimum.size, 0.2);
      expect(minimum.duration, const Duration(milliseconds: 1000));
      expect(middle.size, closeTo(0.35, 0.0000001));
      expect(middle.duration, const Duration(milliseconds: 1500));
      expect(maximum.size, closeTo(0.5, 0.0000001));
      expect(maximum.duration, const Duration(milliseconds: 2000));
    });

    test('大きい粒子ほど寿命も長くなる', () {
      final metrics = [
        for (final factor in [0.0, 0.25, 0.5, 0.75, 1.0])
          MfmSparkleWidget.debugParticleMetrics(factor),
      ];

      for (var index = 1; index < metrics.length; index++) {
        expect(metrics[index].size, greaterThan(metrics[index - 1].size));
        expect(
          metrics[index].duration,
          greaterThan(metrics[index - 1].duration),
        );
      }
    });
  });

  group('sparkle star path', () {
    test('本家の64x64 SVGと同じ描画範囲を持つ閉じた輪郭になる', () {
      final path = MfmSparkleWidget.debugStarPath();
      final metrics = path.computeMetrics().toList();

      expect(path.getBounds(), const Rect.fromLTRB(-32, -32, 32, 32));
      expect(metrics, hasLength(1));
      expect(metrics.single.isClosed, isTrue);
    });

    test('三次ベジェの細い4方向スパークル形状になる', () {
      final path = MfmSparkleWidget.debugStarPath();

      expect(path.contains(const Offset(0, 30)), isTrue);
      expect(path.contains(const Offset(30, 0)), isTrue);
      expect(path.contains(const Offset(10, 10)), isFalse);
      expect(path.contains(const Offset(-10, 10)), isFalse);
      expect(path.contains(const Offset(-10, -10)), isFalse);
      expect(path.contains(const Offset(10, -10)), isFalse);
    });
  });
}
