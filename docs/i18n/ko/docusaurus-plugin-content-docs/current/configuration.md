---
id: configuration
slug: /configuration
title: 설정
sidebar_label: 설정
---

`MfmRenderConfig`로 렌더링 옵션과 콜백을 지정합니다. `MfmConfig`는 하위 `MfmText` 위젯에 설정을 공유합니다. `MfmRenderOptions` 타입은 없습니다.

## 설정 공유

이 위젯을 [시작하기](getting-started.md)의 앱에 배치하세요. 단일 위젯에는 같은 설정을 `MfmText(config: ...)`로 직접 전달할 수도 있습니다.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class ConfigExample extends StatelessWidget {
  const ConfigExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MfmConfig(
      config: MfmRenderConfig(
        baseTextStyle: TextStyle(fontSize: 18, height: 1.5),
        enableAnimation: false,
        nyaizeMode: MfmNyaizeMode.disabled,
        codeCopyTooltip: 'Copy code',
        codeCopiedMessage: 'Code copied',
      ),
      child: MfmText(text: '**Shared style** and `inline code`'),
    );
  }
}
```

## 기본값과 상속

| 설정 | 기본값 / 결정 순서 |
| --- | --- |
| `enableAdvancedMfm`, `enableAnimation` | 모두 `true`이며 `useAnimation`은 두 값의 논리 AND입니다. |
| `enableNyaize` | `false`. 새 코드에는 명시적 `nyaizeMode`를 권장합니다. |
| `baseTextStyle` | 지정한 스타일, 없으면 `DefaultTextStyle`. 글꼴 크기가 없으면 14를 사용합니다. |
| `brightness` | 명시적 값, Material 테마, Cupertino 테마, 플랫폼 밝기 순이며 마지막으로 밝은 모드를 사용합니다. |
| `lightColorScheme`, `darkColorScheme` | 상속값 또는 `MfmColorScheme.light()` / `.dark()` 프리셋. 주변 테마의 모든 색상이 아닌 **밝기 모드**만 자동으로 적용합니다. |
| `codeTheme`, `codeDarkTheme` | 밝은 모드: github. 어두운 모드: 명시적 어두운 테마, `codeTheme`, atom-one-dark(`atomOneDarkTheme`) 순입니다. |
| `showCodeBlockCopyButton` | `null`이면 표시합니다. `false`로 숨깁니다. |
| `useLocaleSearchButtonLabel` | `false`. `searchButtonLabel`이 없으면 로케일에서 레이블을 정합니다. `true`는 명시적/상속된 레이블을 지우고 현재 로케일을 사용하며 `searchButtonLabel`보다 우선합니다. |

nullable 필드는 대체로 상속된 설정을 사용합니다. **기본값을 가진 bool은 무조건 덮어쓰지 않습니다**. 자식의 `enableAnimation: true`는 부모가 끈 애니메이션을 다시 켜지 않습니다. 게시물마다 되돌리려 하지 말고 공유 설정 경계에서 유효한 선택을 지정하세요. 설정 인스턴스가 바뀌면 `MfmConfig`가 의존 위젯에 알립니다. 가능하면 안정적인 인스턴스를 재사용하되 테마나 접근성 입력이 바뀌면 다시 구성하세요.

## 색상, 글꼴, 코드

`lightColorScheme` / `darkColorScheme`으로 MFM 링크, 멘션, 인용, 코드 등의 색상을 바꿀 수 있습니다. `copyWith`는 일부 역할의 색상만 변경할 때 유용합니다. 두 테마에서 대비를 확인하세요.

`fontFamilyResolver`는 `serif`, `monospace` 같은 MFM 글꼴 타입을 글꼴 패밀리 이름에 대응시킵니다. `null`을 반환하면 기본값을 사용합니다. 리졸버가 글꼴을 로드하지는 않으므로 커스텀 글꼴은 앱에 포함하고 선언해야 합니다. 라이브러리는 Google Fonts 의존성을 요구하지 않습니다.

`codeTheme`과 `codeDarkTheme`은 구문 강조 스타일 맵을 받습니다. `codeDarkTheme`이 없으면 커스텀 밝은 `codeTheme`이 어두운 모드의 대체값으로도 사용되므로 낮은 대비의 밝은 스타일이 잘못 적용되지 않게 하세요. 코드 복사 콜백과 레이블은 [상호작용](interactions.md)에서 설명합니다.

## 고양이 말투 변환

- `MfmNyaizeMode.disabled`: 변환하지 않습니다.
- `MfmNyaizeMode.enabled`: 작성자와 무관하게 변환 가능한 텍스트를 변환합니다.
- `MfmNyaizeMode.respectAuthor`: `author.isCat`이 true일 때 변환합니다.

명시적 모드가 기존 `enableNyaize` 플래그보다 우선합니다. 이는 렌더링 선택일 뿐 계정이나 저장된 MFM을 수정하지 않습니다.

## 컨텍스트 복사와 초기화

`copyWith(field: null)`은 기존 값을 유지하며 **지우지 않습니다**. 배포된 컨텍스트 초기화 플래그는 `clearAuthor`, `clearEmojiUrls`, `clearLocalHost`입니다. 예를 들어 `config.copyWith(clearAuthor: true, clearEmojiUrls: true)`는 재사용 전에 게시물별 컨텍스트를 제거합니다. 값과 해당 초기화 플래그를 동시에 전달하면 예외가 발생합니다. 로컬 설정을 지워도 외부 `MfmConfig`에서 상속한 값은 제거되지 않습니다.

이모지 핸들의 `copyWith`는 수명 주기 소유권을 공유하며 독립적으로 해제할 새 리소스를 만들지 않습니다. [커스텀 이모지](custom-emoji.md)를 참고하세요.

## 문제 해결

설정이 무시되는 것 같으면 가장 가까운 `MfmConfig`, 기본값 bool, `enableAdvancedMfm`을 확인하세요. 앱 테마와 색상이 다르면 자동 매핑을 기대하지 말고 MFM 색상 체계를 명시적으로 제공하세요.

다음: [커스텀 이모지](custom-emoji.md) · [애니메이션과 접근성](animation-accessibility.md) · [MfmRenderConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmRenderConfig-class.html)
