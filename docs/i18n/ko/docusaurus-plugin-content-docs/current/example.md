---
id: example
slug: /example
title: 예제 앱
sidebar_label: 예제 앱
---

저장소에는 MFM 예제를 둘러보고 자신의 텍스트를 시험하는 네이티브 Flutter 앱이 포함되어 있습니다. 현재 인터페이스는 **일본어**입니다.

## 앱 실행

개발 브랜치를 새 디렉터리에 복제하거나 기존 체크아웃을 사용하세요.

```bash
git clone --branch develop https://github.com/LibraryLibrarian/misskey_mfm_renderer.git
cd misskey_mfm_renderer/example
```

저장소에 고정된 Flutter SDK를 사용합니다(`flutter` 대신 `fvm flutter` 사용 가능). 기기 목록에서 네이티브 대상을 선택하세요. 온라인 커스텀 이모지 서비스를 초기화하지 않고 카탈로그를 보려면 다음 실행 모드를 권장합니다.

```bash
flutter pub get
flutter devices
flutter run -d <device-id> --dart-define=MFM_EXAMPLE_OFFLINE=true
```

`<device-id>`를 선택한 기기의 ID로 바꾸세요. Web 데모가 아닙니다.

:::note 개발 소스

예제는 `path: ../`로 부모 패키지에 의존합니다. 미배포 기능을 포함한 체크아웃 소스를 보여 주므로 pub.dev의 최신 패키지와 반드시 일치하지는 않습니다. 차이는 [CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md)를 참고하세요.

:::

## 둘러보고 시험하기

1. **카탈로그(Catalog)**: 텍스트 서식이나 `fn` 함수 같은 분류를 선택합니다. 관련 예제는 같은 페이지에 모여 있습니다.
2. **이 설정으로 시험하기(この設定で試す)**: 예제의 텍스트와 설정을 Playground로 보냅니다. 이 동작은 접근성 레이블과 툴팁이 있는 아이콘입니다.
3. **Playground**: MFM 텍스트를 편집하고 결과를 봅니다. 지우기 동작으로 텍스트를 비울 수 있습니다.
4. **표시 설정(表示設定)**: 공유 표시 옵션을 변경합니다. 고양이 말투에는 각 모드와 모의 작성자의 고양이 설정을 설명하는 별도 상세 화면이 있습니다.

예제는 실제 계정의 고양이 설정을 수정하지 않습니다. 링크, 멘션, 해시태그, clickable, 검색은 브라우저를 열거나 검색 요청을 보내는 대신 SnackBar를 표시합니다.

## 오프라인과 온라인 동작

`MFM_EXAMPLE_OFFLINE=true`가 없으면 시작 시 misskey.io용 커스텀 이모지를 초기화합니다. 설정 화면은 온라인 초기화 성공, 의도한 오프라인 시작, 초기화 실패를 구분합니다.

오프라인 플래그를 사용하면 이모지 초기화를 건너뜁니다. 온라인 전용 원격 작성자와 `emojiUrls` 컨트롤은 비활성화됩니다. 일반 서버 이모지는 쇼트코드로 남지만 명시적으로 설정된 로컬 대체 이미지, 아바타, Twemoji 예제는 볼 수 있습니다.

이 플래그는 빌드 환경이 아닌 실행 시 시작을 제어합니다. 의존성 해결과 SQLite 빌드 훅은 여전히 네트워크가 필요할 수 있습니다. Web 지원을 추가하지도 않습니다.

## 개발 버전에만 있는 차이

가이드는 ‘시작하기’의 배포 의존성을 기준으로 합니다. 촬영한 개발 체크아웃에는 아래 변경도 포함됩니다. 이 표는 배포 패키지에 복사해서 사용할 수 있는 API 사용법이 **아닙니다**.

| 영역 | 개발 체크아웃(가이드의 배포 API가 아님) |
| --- | --- |
| 멘션 | 캡슐 표시와 `MfmMentionOptions`, 표시/아바타 provider 옵션. |
| 타임스탬프 | `MfmUnixtimeOptions`, 절대/상대 형식과 상대 레이블의 주기적 갱신. |
| 이모지 | `MfmTwemojiBuilder`, 이모지 컨텍스트의 `textStyle`, 커스텀 이모지의 `fallbackTextStyle`. |
| 검색과 링크 | 편집 가능한 검색과 레이블 있는 링크의 외부 아이콘(일반 URL 아이콘은 배포 패키지에도 존재). |
| 테두리 | 확장된 아홉 가지 스타일, RGBA, 클리핑 동작. |

## 예제의 실제 화면

다음은 **개발 체크아웃**의 수정하지 않은 Android 에뮬레이터 캡처이며 오프라인 가상 데이터와 일본어 UI를 사용합니다. 설명용 이미지일 뿐 배포 패키지의 픽셀이 같다는 뜻이 아니며 iOS 시각 검증을 나타내지도 않습니다.

<figure className="example-capture">

![Android 개발 예제: 텍스트 서식 카탈로그, 오프라인 가상 데이터, 일본어 UI.](/img/example-text-format-android-develop.png)

<figcaption>Android 개발 예제 — 텍스트 서식 카탈로그, 오프라인 가상 데이터, 일본어 UI. 밝은 테마와 기본 공유 설정.</figcaption>
</figure>

<figure className="example-capture">

![Android 개발 예제: Playground, 오프라인 가상 데이터, 일본어 UI.](/img/example-playground-android-develop.png)

<figcaption>Android 개발 예제 — Playground, 오프라인 가상 데이터, 일본어 UI. 선택한 카탈로그 예제를 설정과 함께 불러왔으며 편집하지 않은 상태.</figcaption>
</figure>

촬영 리비전, 원본 PNG 해시, 재현 설정은 저장소의 [스크린샷 출처 기록](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/docs/screenshots.md)에 있습니다.

## 추가 정보

[예제 README](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md)는 카탈로그, 설정, 로컬 테스트 데이터, 플랫폼 설정을 자세히 설명합니다. 자신의 앱에 라이브러리를 추가하려면 [시작하기](getting-started.md)를 참고하세요.
