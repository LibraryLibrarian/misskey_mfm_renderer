---
id: getting-started
slug: /getting-started
title: 시작하기
sidebar_label: 시작하기
---

Flutter **3.38.1 이상**, Dart **3.10.0 이상**을 사용하는 기존 Flutter 앱에서 시작합니다. Chrome이나 다른 Web 대상이 아니라 지원되는 네이티브 플랫폼에서 예제를 실행하세요.

## 패키지 설치

앱의 `pubspec.yaml`에서 Flutter SDK 의존성과 함께 다음 항목을 추가합니다.

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.4
```

앱 디렉터리에서 의존성을 해결합니다.

```bash
flutter pub get
```

이는 배포된 패키지 의존성입니다. 저장소 `develop` 브랜치의 미배포 소스를 사용하지 않습니다.

## MFM 텍스트 표시

새 앱이나 임시 앱에서는 다음 내용을 `lib/main.dart`로 사용합니다. 기존 앱에 통합할 때는 앱 진입점을 교체하지 말고 화면에 `MfmText` 위젯을 추가하세요.

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

void main() {
  runApp(const MfmDemoApp());
}

class MfmDemoApp extends StatelessWidget {
  const MfmDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: MfmText(text: '**Hello** from *MFM*!'),
          ),
        ),
      ),
    );
  }
}
```

결과는 ‘Hello from MFM!’이며 **Hello**는 굵게, *MFM*은 기울임꼴로 표시됩니다. `MfmText`가 소스 문자열을 파싱하고 해당 서식을 적용합니다.

목록에서 네이티브 기기를 선택하고 아래 `<device-id>`를 해당 ID로 바꿉니다.

```bash
flutter devices
flutter run -d <device-id>
```

이 예제는 커스텀 이모지 클라이언트나 영구 저장소를 초기화하지 않으며, 텍스트를 렌더링하기 위해 서버 요청을 보내지 않습니다. 단, 패키지 다운로드와 네이티브 빌드 훅은 네트워크가 필요할 수 있으므로 완전한 오프라인 빌드 방법은 아닙니다.

## 커스텀 이모지는 어떻게 사용하나요?

`:custom_emoji:` 같은 쇼트코드를 추가해도 서버가 자동 설정되거나 이미지가 해석되지는 않습니다. 최소 예제는 의도적으로 이 설정을 제외하며 `misskey_client`에 대한 추가 직접 의존성도 필요하지 않습니다.

배포된 설정 API, 소유권, 비동기 정리, 원격 게시물 컨텍스트는 [커스텀 이모지](custom-emoji.md)를 참고하세요.

## 다음 단계

[예제 앱을 실행](example.md)하여 MFM 기능을 둘러보고 다양한 텍스트와 표시 설정을 시험해 보세요. 매개변수 정의는 [API 참조](https://pub.dev/documentation/misskey_mfm_renderer/latest/)에서 확인할 수 있습니다.
