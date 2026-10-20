---
id: animation-accessibility
slug: /animation-accessibility
title: 애니메이션과 접근성
sidebar_label: 애니메이션과 접근성
---

애니메이션은 기본적으로 켜져 있습니다. 렌더러는 애니메이션 플래그를 운영체제의 동작 줄이기 설정에 자동으로 연결하지 **않습니다**. 앱 경계에서 직접 연결해야 합니다.

## 동작 줄이기 반영

[시작하기](getting-started.md)의 `MaterialApp` 아래에서 이 위젯을 사용합니다. `MediaQuery.disableAnimations`의 변경을 관찰하며 앱 차원의 ‘효과 끄기’ 설정을 같은 bool 값과 결합할 수 있습니다.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class MotionExample extends StatelessWidget {
  const MotionExample({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MfmText(
      text: r'$[tada Hello] $[rainbow Color]',
      config: MfmRenderConfig(enableAnimation: !reduceMotion),
    );
  }
}
```

## 목적이 다른 두 스위치

| 설정 | 결과 |
| --- | --- |
| `enableAnimation: false` | MFM 애니메이션을 끄되 구현된 정적 서식/효과는 유지합니다. `tada`는 확대 상태, `rainbow`는 정적 그라데이션, `sparkle`은 효과 없이 내용을 유지합니다. |
| `enableAdvancedMfm: false` | 고급 크기/위치 동작도 끕니다. 단순한 동작 줄이기 스위치가 아닙니다. |
| 둘 다 켬 | MFM 애니메이션을 허용합니다(`useAnimation == true`). |

두 플래그 모두 움직이는 **GIF/APNG/WebP 이모지 이미지**를 멈추지 않습니다. 정지 이미지를 제공하는 등 이미지/이모지 빌더와 앱 정책으로 제어하세요. 부모 설정에서 애니메이션을 끈 경우 자식에게 기본값 `true`를 전달하는 것만으로 되돌릴 수 없습니다. [설정](configuration.md)을 참고하세요.

MFM 애니메이션 `speed`/`delay` 인수는 초 단위입니다. 예를 들어 `$[spin.speed=2s text]`이며 `2000ms`가 아닙니다. Dart에서는 `$[...]`를 원시 문자열에 넣으세요.

## 읽기, 포커스, 숨긴 내용

- `blur`는 시각적 효과일 뿐입니다. 내용은 시맨틱에서 제외되지 않아 보조 기술이 읽을 수 있습니다. **기밀 데이터를 숨기는 용도로 절대 사용하지 마세요.**
- 루비 주석과 포함된 WidgetSpan은 보이는 텍스트와 다른 읽기 순서나 발음을 만들 수 있습니다. 완전한 접근성 준수를 가정하지 말고 실제 대상에서 TalkBack/VoiceOver로 확인하세요.
- 텍스트 선택은 구현되어 있지 않습니다. 복사나 대체 읽기 화면이 필요하면 원본 내용과 명시적 변환 규칙으로 앱 수준에서 제공하세요.
- 커스텀 이모지/상호작용 위젯에 의미 있는 레이블을 제공하고 두 MFM 색상 체계의 대비를 확보하세요. 코드 복사 레이블은 [상호작용](interactions.md)에서 설명합니다.
- 바깥 화면에서 큰 시스템 글자 크기, 긴 링크, 인용, 키보드/포커스 탐색을 시험하세요. 스크린샷은 스크린 리더 지원의 증거가 아닙니다.

## 성능과 문제 해결

밀집된 타임라인에서는 리졸버/설정 인스턴스의 불필요한 재생성을 피하고 바뀌지 않은 내용의 파싱 노드를 재사용하며 보이는 애니메이션 위젯 수를 제한하세요. 정책을 정하기 전에 대상 하드웨어에서 성능을 측정하세요. 라이브러리는 특정 프레임률을 보장하거나 화면 밖의 모든 효과를 자동 일시 정지하지 않습니다.

MFM 애니메이션을 꺼도 움직임이 남으면 이미지 애니메이션과 MFM 효과를 먼저 구분하세요. 큰/정적 효과도 꺼야 한다면 `enableAdvancedMfm: false`를 고려하고 결과를 확인하세요. 동작 줄이기가 무시되는 것 같으면 `MediaQuery` 연결과 상속 설정을 확인하세요.

다음: [렌더링](rendering.md) · [커스텀 이모지](custom-emoji.md) · [예제 앱](example.md)
