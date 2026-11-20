---
id: rendering
slug: /rendering
title: MFM 렌더링
sidebar_label: MFM 렌더링
---

`MfmText`는 네이티브 Flutter 위젯에서 Misskey Flavored Markdown을 렌더링합니다. [시작하기](getting-started.md)에 따라 배포 패키지를 설치하세요. 복사 가능한 예제는 개발 예제가 아닌 해당 배포 API를 기준으로 합니다.

## 크기가 제한된 렌더링 영역

이 위젯을 ‘시작하기’의 Material 앱 body에 배치합니다. `$[...]`에는 Dart **원시 문자열**을 사용하여 `$`가 문자열 보간으로 해석되지 않게 하세요.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class RenderExample extends StatelessWidget {
  const RenderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 320,
      child: MfmText(
        text: r'**Hello** $[fg.color=336699 blue] $[x2 large]',
        config: MfmRenderConfig(enableAnimation: false),
      ),
    );
  }
}
```

## 입력과 표시 모드

| 입력 | 동작 |
| --- | --- |
| `text` | MFM 소스입니다. 빈 문자열은 아무것도 표시하지 않습니다. |
| `parsedNodes` | `misskey_mfm_parser`로 미리 파싱한 `List<MfmNode>`입니다. 동일한 파싱 결과를 렌더링할 때 재사용하며 `text`보다 우선합니다. 앱에서 파서를 직접 import하면 직접 의존성을 선언해야 합니다. |
| `simple: true` | 단순 파서를 사용합니다. 일반 텍스트, 멘션, 해시태그, URL, 대부분의 서식은 완전한 MFM으로 처리하지 않습니다. 유니코드/커스텀 이모지는 계속 지원합니다. |
| `plain: true` | 단순 파싱을 사용하며 이모지는 일반 크기 렌더링 컨텍스트를 사용합니다. 범용 HTML/Markdown 보안 필터가 아닙니다. |
| `nowrap: true` | 한 줄로 표시하고 넘치는 부분은 말줄임표로 처리합니다. 위젯에 유한한 가용 너비를 제공하세요. |
| `rootScale` | 양수이며 유한한 루트 배율입니다(기본 `1.0`). 앱의 접근성 환경설정이 아니라 MFM 렌더링에 영향을 줍니다. |
| `isNote` | 기본값은 `true`이며 파서가 아닌 해시태그 탐색 세부 정보를 바꿉니다. [상호작용](interactions.md)을 참고하세요. |

`text` 또는 `parsedNodes`를 제공해야 하며 생성자가 assertion으로 이를 확인합니다. 파서에서 `FormatException`이 발생하면 전체 소스를 일반 텍스트로 표시합니다. 모든 잘못된 입력이 예외를 발생시키거나 안전하게 필터링된다는 보장은 아닙니다. 게시물별 호스트/이모지 컨텍스트는 [커스텀 이모지](custom-emoji.md)를 참고하세요.

## 지원 문법

| 분류 | 예시 / 동작 |
| --- | --- |
| 텍스트 | 굵게 `**text**`, 기울임 `*text*`, 취소선 `~~text~~`, 작게 `<small>text</small>`, 가운데 `<center>text</center>`. |
| 탐색 | URL, `[label](https://example.com)`, `@name`, `#tag`, 검색 블록. 탐색은 콜백으로 처리합니다. |
| 코드와 인용 | 백틱 인라인 코드, 강조/복사를 지원하는 코드 블록, `> quote`. 인용에는 제한된 레이아웃 너비가 필요합니다. |
| 이모지 | 유니코드 이모지와 `:shortcode:`. 서버 이모지에는 이모지 빌더/리졸버가 필요합니다. |
| 수식 | 인라인/블록 수식은 LaTeX 렌더링이 아닌 **고정폭 텍스트**로 표시합니다. |
| 일반 텍스트 영역 | `<plain>...</plain>`은 내용을 리터럴 그대로 유지합니다. |

### 함수 블록

| 함수 그룹 | 배포 버전의 동작 |
| --- | --- |
| `x2`, `x3`, `x4`, `scale`, `position` | 크기와 위치 효과이며 고급 MFM 설정이 적용 여부에 영향을 줍니다. |
| `fg`, `bg`, `font`, `border` | 텍스트/배경색, 글꼴 선택, 테두리. 개발 예제의 확장된 테두리 옵션이 배포 패키지에도 있다고 가정하지 마세요. |
| `flip`, `rotate` | 정적 변환. |
| `blur` | 내용을 드러낼 수 있는 시각적 흐림 효과이며 보안이나 기밀 정보 가림의 경계가 아닙니다. |
| `ruby`, `unixtime` | 루비 주석과 타임스탬프 표시. 개발 버전과의 차이는 [예제 페이지](example.md)를 참고하세요. |
| `clickable` | 콜백을 통해 이벤트 ID를 전달합니다. |
| `jelly`, `tada`, `jump`, `bounce`, `shake`, `twitch`, `spin`, `rainbow`, `sparkle` | 애니메이션/효과 함수. 동작을 끄려면 [애니메이션과 접근성](animation-accessibility.md)을 참고하세요. |

알 수 없는 함수는 자식 내용을 렌더링하면서 `$[name ...]` 래퍼를 리터럴로 유지하고 알 수 없는 효과는 적용하지 않습니다. 함수 지원이 Misskey 브라우저 렌더러와 픽셀 단위로 동일한 출력을 보장하지는 않습니다.

## 제약과 문제 해결

- **Web 미지원**, **텍스트 선택 미지원**입니다. SelectableText가 아닌 위젯이 포함된 RichText를 사용합니다.
- 인용이나 긴 내용이 넘치면 Row 안의 `Expanded`처럼 크기가 제한된 부모를 사용하세요.
- 글꼴과 글리프 누락은 플랫폼에 따라 다릅니다. 모든 OS의 글꼴이 같다고 가정하지 말고 [텍스트/글꼴 설정](configuration.md)을 지정하세요.
- 렌더링된 span의 `toPlainText()`는 신뢰할 수 있는 의미적 텍스트 내보내기가 아닙니다. 포함된 위젯이나 시각적 변환은 소스와 다를 수 있습니다. 원본을 보관하거나 앱별 텍스트 변환을 정의하세요.
- 커스텀 이모지 리졸버가 없거나 실패하면 쇼트코드가 남습니다. 이는 MFM 파서 실패를 뜻하지 않습니다.

다음: [설정](configuration.md) · [커스텀 이모지](custom-emoji.md) · [API 참조](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
