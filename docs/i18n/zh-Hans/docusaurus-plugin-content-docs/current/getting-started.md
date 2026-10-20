---
id: getting-started
slug: /getting-started
title: 快速开始
sidebar_label: 快速开始
---

从已有 Flutter 应用开始，使用 Flutter **3.38.1 或更高版本**和 Dart **3.10.0 或更高版本**。请在受支持的原生平台运行示例，而不是 Chrome 或其他 Web 目标。

## 安装包

在应用的 `pubspec.yaml` 中，将以下条目添加到 Flutter SDK 依赖旁：

```yaml
dependencies:
  misskey_mfm_renderer: ^0.6.0-beta.4
```

然后在应用目录中解析依赖：

```bash
flutter pub get
```

这是已发布的包依赖，不使用仓库 `develop` 分支中的未发布源码。

## 显示 MFM 文本

在新建或临时应用中，将以下内容用作 `lib/main.dart`。集成到已有应用时，应将 `MfmText` widget 加入页面，而不是替换应用入口。

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

结果为“Hello from MFM!”，其中 **Hello** 为粗体，*MFM* 为斜体。`MfmText` 解析源字符串并应用相应格式。

从列表中选择一个原生设备，将下面的 `<device-id>` 替换为其 ID：

```bash
flutter devices
flutter run -d <device-id>
```

此示例不初始化自定义表情客户端或持久化存储，渲染文本也不会向服务器发送请求。但包下载和原生构建钩子仍可能需要网络，因此这不是完全离线的构建方案。

## 如何使用自定义表情？

添加 `:custom_emoji:` 这样的短代码不会自动配置服务器或解析图片。最小示例特意省略了这一配置，也不需要额外直接依赖 `misskey_client`。

有关已发布的配置 API、所有权、异步清理和远程帖子上下文，请参阅[自定义表情](custom-emoji.md)。

## 后续步骤

[运行示例应用](example.md)，浏览 MFM 功能并尝试不同的文本和显示设置。参数定义请参阅 [API 参考](https://pub.dev/documentation/misskey_mfm_renderer/latest/)。
