---
id: custom-emoji
slug: /custom-emoji
title: 커스텀 이모지
sidebar_label: 커스텀 이모지
---

서버별 `:shortcodes:`에는 이모지 설정이 필요합니다. 빌더가 없으면 리터럴 텍스트로 남습니다. [시작하기](getting-started.md)에 따라 렌더러를 설치하세요.

## 기본 카탈로그와 저장소

`MfmEmojiConfig.createDefault`는 호출자가 소유한 `MisskeyClient`를 영구 카탈로그, 리졸버, 이미지 빌더에 연결합니다. 단순 설정이 아니라 **핸들**을 반환합니다. 기본 저장 위치는 앱의 문서 디렉터리이며 `storagePath`로 바꿀 수 있습니다. 기본 저장소는 SQLite/Drift를 사용합니다. 타임라인의 각 게시물마다 따로 만들지 말고 화면이나 앱 범위에서 핸들을 유지하세요.

아래 예제는 이미 생성된 클라이언트를 받습니다. `misskey_client`를 직접 import하므로 앱의 직접 의존성으로 선언해야 합니다(이전 beta.5가 아닌 `^1.0.0-beta.6` 호환 버전). 기본적으로 온라인 백그라운드 동기화를 사용합니다. 네트워크 접근을 의도한 경우에만 명확하게 선택한 실제 서버의 클라이언트를 제공하세요.

‘시작하기’의 앱 아래에 이 위젯을 배치하세요. 위젯 수명 동안 클라이언트를 고정하고 서버를 바꿀 때는 새 key로 위젯을 교체하세요. 핸들의 비동기 정리가 끝날 때까지 클라이언트가 유효해야 합니다. 앱 종료 시 이 순서를 기다려야 한다면 `State` 밖에서 핸들을 소유하고 해제가 끝난 뒤 클라이언트를 닫으세요.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:misskey_client/misskey_client.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class EmojiExample extends StatefulWidget {
  const EmojiExample({super.key, required this.client});

  final MisskeyClient client;

  @override
  State<EmojiExample> createState() => _EmojiExampleState();
}

class _EmojiExampleState extends State<EmojiExample> {
  late final Future<MfmEmojiConfigHandle> _pending;
  MfmEmojiConfigHandle? _handle;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _pending = MfmEmojiConfig.createDefault(client: widget.client);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final handle = await _pending;
      if (mounted) setState(() => _handle = handle);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _close() async {
    MfmEmojiConfigHandle handle;
    try {
      handle = await _pending;
    } catch (_) {
      return; // Initialization failed; no handle was returned.
    }
    try {
      await handle.dispose();
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('while disposing the emoji handle'),
      ));
    }
  }

  @override
  void dispose() {
    unawaited(_close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return const Text('Emoji initialization failed');
    final handle = _handle;
    if (handle == null) return const CircularProgressIndicator();
    return MfmText(text: ':smile:', config: handle);
  }
}
```

## 소유권과 비동기 정리

예제는 초기화가 끝나기 전에 위젯이 제거되어도 초기화를 기다린 후 반환된 핸들을 해제합니다. Flutter의 `State.dispose`는 비동기 메서드가 될 수 없으므로 정리는 별도로 실행하고 해제 오류를 보고합니다. 초기화 Future를 버려서 늦게 생성된 핸들을 잃지 마세요.

- `await handle.dispose()`는 멱등적이며 백그라운드 동기화를 기다린 뒤 카탈로그/저장소를 닫습니다.
- **호출자의 클라이언트는 해제하지 않습니다**.
- `handle.copyWith(...)`의 복사본은 수명 주기 상태를 공유합니다. 어느 복사본이든 해제하면 공유 리소스가 해제되므로 게시물마다 해제하지 마세요.
- `autoSync: false`는 초기 백그라운드 동기화를 끕니다. `onSyncError`로 동기화 실패를 관찰할 수 있습니다. 핸들 생성 성공만으로 서버 동기화 성공을 확인할 수는 없습니다.
- 카탈로그 데이터가 바뀌면 `emojiRefreshListenable`이 렌더링된 이모지에 알릴 수 있습니다. 기본 자동 동기화도 갱신 알림을 제공합니다.

## 원격 게시물 컨텍스트

`handle`에서 게시물별 설정을 파생하고 `author: MfmAuthorContext(host: 'remote.example')`와 게시물의 이모지 이름→이미지 URL 맵인 `emojiUrls`를 제공하세요. 로컬 작성자의 host는 null입니다. 헬퍼의 `localHost`는 클라이언트의 origin에서 가져옵니다.

맵은 불변으로 취급하고 데이터가 바뀌면 교체하세요. **맵이 존재하지만 요청한 쇼트코드가 없으면 리터럴로 대체합니다**. 이는 맵 자체가 없는 경우와 다릅니다. 설정을 재사용할 때 [배포된 초기화 플래그](configuration.md)로 오래된 게시물 컨텍스트를 지우세요.

## 기존 리졸버 또는 커스텀 빌더

앱이 이미 카탈로그/리졸버를 소유한다면 `MfmEmojiConfig.fromResolver(resolver: ..., serverBaseUrl: ...)`를 사용하세요. 소유권이 있는 핸들이 아닌 설정을 반환하므로 호출자가 자신의 카탈로그/저장소를 해제해야 합니다. 직접 URL이 없을 때 `serverBaseUrl`로 원격 대체 URL을 사용할 수 있습니다. 이를 생략하면 해석되지 않은 원격 이모지가 쇼트코드로 남습니다.

완전한 제어가 필요하면 `emojiBuilder`는 `(String name, MfmEmojiContext context)`를 받으며 `unicodeEmojiBuilder`는 유니코드 문자열과 같은 컨텍스트를 받습니다. Widget을 반환하고 로딩/오류/시맨틱 동작을 직접 제공하세요. 배포된 컨텍스트에는 `fontSize`, `scale`, `normal`, `host`, `url`, `useOriginalSize`가 있지만 개발 전용 `textStyle`은 **없습니다**. 커스텀 리졸버나 직접 URL이 네트워크 접근을 제어하므로 이 지점에서 앱의 미디어/호스트 정책을 적용하세요.

## 크기, 기준선, 캐시

- 헬퍼의 기본 높이는 **2em**, 일반/plain 컨텍스트에서는 **1.25em**입니다. `emojiSize`는 최소 높이가 아닌 고정 높이입니다. 독립적인 `MfmCustomEmoji.size`의 기본값은 24입니다.
- 헬퍼와 일치하는 빌더의 기준선 오프셋은 `size / 2 - context.fontSize * 0.25`이며 일반/plain 컨텍스트에서는 `context.fontSize * 0.25`입니다. 바깥쪽 그리기 변환이 배율을 적용하므로 이미지에 `context.scale`을 다시 곱하지 마세요.
- `emojiMaxWidth`는 너비를 제한합니다. `useOriginalSize`는 커스텀 빌더를 위한 힌트입니다. 리졸버가 원본과 썸네일 URL을 구분하지 않으면 헬퍼가 자동으로 선택할 수 없습니다.
- URL 및 가로세로 비율 캐시는 프로세스 전체에 걸친 LRU이며 각각 256개 항목을 저장합니다. `cacheScope`로 식별 범위를 분리합니다. 기본적으로 리졸버의 동일성 또는 직접 URL을 사용하므로 매 build마다 리졸버 클로저를 새로 만들면 재사용이 무효화될 수 있습니다.

## 플랫폼과 문제 해결

네이티브 Android/iOS/macOS/Linux/Windows를 지원하며 Web은 지원하지 않습니다. 네이티브 저장소/네트워크 설정은 [예제 README](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md)를 따르세요. 빌드 시 SQLite/의존성 다운로드와 실행 시 동기화는 별개입니다.

쇼트코드가 남으면 리졸버, 서버 origin, 게시물별 host/맵, 동기화 오류, 이미지 가용성, 네이티브 네트워크 권한을 확인하세요. 토큰을 로그에 남기거나 쇼트코드 대체를 인증 오류의 증거로 단정하지 마세요. 결정적인 로컬 테스트에는 자동 동기화를 끄고 가짜 저장소/리졸버를 주입하세요. 이 테스트는 실제 서버 동기화를 검증하지 않습니다.

다음: [설정](configuration.md) · [상호작용](interactions.md) · [MfmEmojiConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmEmojiConfig-class.html)
