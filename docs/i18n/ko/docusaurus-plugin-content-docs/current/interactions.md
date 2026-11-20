---
id: interactions
slug: /interactions
title: 상호작용
sidebar_label: 상호작용
---

렌더러는 상호작용을 알리고 앱이 그 의미를 결정합니다. URL 열기, 프로필 이동, 검색 요청을 자동으로 수행하지 **않습니다**.

## 로컬 피드백 예제

[시작하기](getting-started.md)처럼 `MaterialApp` 아래 `Scaffold` 안에 이 위젯을 배치합니다. 모든 동작은 로컬 SnackBar를 표시하므로 launcher 의존성이나 실제 계정이 필요하지 않습니다.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class InteractionExample extends StatelessWidget {
  const InteractionExample({super.key});

  @override
  Widget build(BuildContext context) {
    void show(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return MfmText(
      text: '[Example](https://example.com) @alice #flutter\n'
          'Flutter Search\n'
          r'$[clickable.ev=demo Tap me]',
      config: MfmRenderConfig(
        localHost: 'example.com',
        onLinkTap: (url) => show('Link: $url'),
        onMentionTap: (acct) => show('Mention: $acct'),
        onHashtagTapDetails: (details) => show('Tag path: ${details.path}'),
        onSearchTap: (query) => show('Search: $query'),
        onClickableEvent: (eventId) => show('Event: $eventId'),
        onCodeCopied: (code) => show('Copied ${code.length} characters'),
        codeCopyTooltip: 'Copy code',
      ),
    );
  }
}
```

## 콜백 규약

| 콜백 | 값과 동작 |
| --- | --- |
| `onLinkTap` | 원본 소스 URL이며 신뢰하거나 필터링된 대상이 아닙니다. 콜백이 없으면 자동으로 열지 않습니다. |
| `onMentionTap` | 정규화된 계정. 멘션의 명시적 호스트, `author.host`, `localHost` 순으로 호스트를 결정하며 없으면 원래 계정을 유지합니다. |
| `onHashtagTapDetails` | 태그, `isNote`, 인코딩된 탐색 경로. `onHashtagTap`보다 우선합니다. |
| `onHashtagTap` | 상세 콜백이 없을 때 태그만 전달하는 대체 콜백. |
| `onSearchTap` | 검색어. 배포된 검색 표시는 개발 예제의 편집 가능한 입력란과 다릅니다. |
| `onClickableEvent` | `$[clickable.ev=demo ...]`의 `ev` 값. `ev`가 없으면 빈 문자열입니다. 콜백이 없으면 내용은 일반 텍스트가 됩니다. |
| `onCodeCopied` | 클립보드 복사 후 전체 코드. 기본 성공 SnackBar를 대체하며 클립보드 쓰기 자체를 대체하지는 않습니다. |

해시태그에서 `isNote: true`는 `/tags/<encoded-tag>`, `false`는 `/user-tags/<encoded-tag>`를 만듭니다. 상대 경로일 뿐 서버나 네비게이터를 자동 선택하지 않습니다.

## URL과 이벤트 정책은 앱의 책임

콜백 값은 신뢰할 수 없는 게시물 내용으로 취급하세요. 링크를 열기 전에 앱 정책에 따라 URI 스킴과 목적지를 검증하고 임의의 스킴을 launcher에 그대로 전달하지 마세요. 프로필/서버 선택, 인증, 외부 이동 확인, 허용할 clickable 이벤트 ID도 앱의 책임입니다. 이벤트 ID를 실행 가능한 코드로 해석하지 마세요.

## 복사 피드백과 접근성

복사 버튼은 기본적으로 표시되며 `showCodeBlockCopyButton: false`로 숨깁니다. `codeCopyTooltip`은 버튼의 **Semantics 레이블**이지 눈에 보이는 호버 툴팁이 아닙니다. `onCodeCopied`가 없으면 `ScaffoldMessenger`가 있을 때만 기본 성공 SnackBar를 표시합니다. `codeCopiedMessage`로 메시지를 바꿀 수 있습니다. 기본값은 일본어/그 밖의 로케일에 맞춰 현지화됩니다.

내장 Material 아이콘 글리프를 사용할 때는 앱 Flutter 설정의 `uses-material-design: true`를 유지하세요. 상호작용 위젯을 직접 교체한다면 동등한 레이블과 포커스 동작을 제공하세요.

## 문제 해결

탭해도 반응이 없으면 해당 콜백과 전체 파싱 활성화 여부(`simple`/`plain`이 아님)를 확인하세요. 두 해시태그 콜백을 모두 제공하면 상세 콜백만 사용됩니다. 멘션이 잘못된 호스트로 이동하면 표시 텍스트로 추측하지 말고 게시물별 `author`와 공유 `localHost`를 확인하세요.

다음: [설정](configuration.md) · [커스텀 이모지](custom-emoji.md) · [애니메이션과 접근성](animation-accessibility.md)
