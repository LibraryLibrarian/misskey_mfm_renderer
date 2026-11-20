---
id: overview
slug: /
title: 개요
sidebar_label: 개요
---

# misskey_mfm_renderer

`MfmText`로 Flutter에서 [Misskey Flavored Markdown(MFM)](https://misskey-hub.net/en/docs/for-users/features/mfm/)을 렌더링합니다. MFM은 익숙한 텍스트 서식에 커스텀 이모지, 변환, 애니메이션 등의 기능을 더합니다.

이 라이브러리는 MFM 텍스트나 파싱된 노드를 Flutter 위젯으로 변환합니다. 타임라인을 가져오거나 완전한 Misskey 앱을 제공하지는 않습니다. 텍스트 제공, 렌더링 설정 선택, 상호작용 처리는 앱의 역할입니다.

## 여기서 시작하기

- [시작하기](getting-started.md): 서버 연결을 설정하지 않고 첫 MFM 텍스트 표시하기.
- [예제 앱](example.md): 카탈로그를 둘러보고 Playground에서 텍스트와 설정 시험하기.
- [렌더링](rendering.md): 입력, 표시 모드, 지원 문법과 제약.
- [설정](configuration.md): 공유 스타일, 색상, 글꼴, 고양이 말투 변환.
- [커스텀 이모지](custom-emoji.md): 초기화, 소유권, 원격 게시물과 커스텀 빌더.
- [상호작용](interactions.md): 콜백과 앱의 탐색 정책.
- [애니메이션과 접근성](animation-accessibility.md): 동작 줄이기와 읽기 지원의 한계.
- [API 참조](https://pub.dev/documentation/misskey_mfm_renderer/latest/): 최신 배포 패키지의 자동 생성 API 문서.

복사해서 사용할 수 있는 예제는 ‘시작하기’의 배포 패키지를 기준으로 합니다. 개발 버전에만 있는 기능과 스크린샷은 예제 페이지에 별도로 표시합니다.

## 렌더링 가능한 내용

- 텍스트 서식, 인용, 코드, 링크, 멘션, 해시태그.
- 해석과 렌더링 방식을 설정할 수 있는 유니코드 및 커스텀 이모지.
- 크기, 변환, 스타일, 애니메이션을 위한 MFM `fn` 함수.

색상, 텍스트 스타일, 콜백, 애니메이션 설정으로 렌더링을 조정할 수 있습니다. [렌더링 가이드](rendering.md)는 지원 함수와 제약을 설명하며, 모든 Misskey 기능의 구현을 보장하지는 않습니다.

## 지원 환경

**Android, iOS, macOS, Linux, Windows**를 지원합니다. Flutter **3.38.1 이상**, Dart **3.10.0 이상**이 필요합니다.

**Web은 지원하지 않습니다.** Web 빌드가 컴파일될 수는 있지만, 기본 커스텀 이모지 설정에는 Web 저장소가 없고 Web 렌더링도 테스트하지 않았습니다. 이 사이트는 문서이며 Flutter 예제의 브라우저 버전이 아닙니다.

렌더링된 텍스트는 선택할 수 없습니다. 복사 기능이 필요한 앱은 원본 MFM 텍스트를 사용해야 합니다.

커스텀 이모지는 패키지에 포함된 `misskey_emoji`를 사용합니다. 기본 설정은 영구 SQLite 저장소를 소유하므로 초기화와 해제가 필요합니다. [최소 텍스트 예제](getting-started.md)에는 이 설정이 필요하지 않습니다. 네이티브 저장소와 이미지 로딩을 설정하기 전에 [커스텀 이모지 가이드](custom-emoji.md)를 확인하세요.

## 배포 패키지와 개발 예제

설치 가이드는 배포된 패키지 의존성을 사용합니다. 저장소의 `develop` 브랜치, README, 예제 앱에는 아직 배포되지 않은 변경이 포함될 수 있습니다. 미배포로 표시된 기능에 의존하기 전에 [CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md)를 확인하세요.
