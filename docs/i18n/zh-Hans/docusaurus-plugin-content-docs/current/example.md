---
id: example
slug: /example
title: 示例应用
sidebar_label: 示例应用
---

仓库包含一个原生 Flutter 应用，可浏览 MFM 示例并尝试自己的文本。界面目前为**日语**。

## 运行应用

将开发分支克隆到新目录，或使用已有 checkout：

```bash
git clone --branch develop https://github.com/LibraryLibrarian/misskey_mfm_renderer.git
cd misskey_mfm_renderer/example
```

使用仓库固定的 Flutter SDK（可用 `fvm flutter` 替代 `flutter`）。列出可用设备并选择原生目标。建议使用以下启动模式浏览目录，避免初始化在线自定义表情服务：

```bash
flutter pub get
flutter devices
flutter run -d <device-id> --dart-define=MFM_EXAMPLE_OFFLINE=true
```

将 `<device-id>` 替换为所选设备 ID。这不是 Web 演示。

:::note 开发源码

示例通过 `path: ../` 依赖父级包，展示当前 checkout 的源码（包括未发布功能），不一定与 pub.dev 上的最新包一致。差异请见 [CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md)。

:::

## 浏览与尝试

1. **目录（Catalog）**：选择文本格式或 `fn` 函数等类别。相关示例归在同一页面。
2. **使用这些设置尝试（この設定で試す）**：通过示例操作将文本和设置发送到 Playground。该操作是带无障碍标签和提示的图标。
3. **Playground**：编辑 MFM 文本并查看结果，使用清除操作清空文本。
4. **显示设置（表示設定）**：打开设置页修改共享显示选项。猫语转换有独立的说明页面，介绍各模式和模拟作者的猫属性。

示例不会修改真实账号的猫属性。链接、提及、话题标签、clickable 和搜索操作仅显示 SnackBar，不会打开浏览器或发出搜索请求。

## 离线与在线行为

未指定 `MFM_EXAMPLE_OFFLINE=true` 时，启动会为 misskey.io 初始化自定义表情支持。设置页区分在线初始化成功、主动离线启动和初始化失败。

启用离线标志后，应用跳过自定义表情初始化。仅在线可用的远程作者和 `emojiUrls` 控件会被禁用。普通服务器表情保持为短代码；仍可查看显式配置的本地回退、头像和 Twemoji 示例。

该标志控制运行时启动，不控制构建环境。依赖解析和 SQLite 构建钩子仍可能需要网络，也不会因此支持 Web。

## 仅开发版提供的差异

指南以“快速开始”中的已发布依赖为准。截图所用的开发 checkout 还包含以下变更；此表**不是**已发布包可直接复制的 API 用法。

| 领域 | 开发 checkout（不属于指南使用的已发布 API） |
| --- | --- |
| 提及 | 胶囊样式、`MfmMentionOptions`、显示／头像 provider 选项。 |
| 时间戳 | `MfmUnixtimeOptions`、绝对／相对格式及相对标签的定时刷新。 |
| 表情 | `MfmTwemojiBuilder`、表情上下文的 `textStyle`、自定义表情的 `fallbackTextStyle`。 |
| 搜索与链接 | 可编辑搜索和带标签链接的外部链接图标（已发布包已有裸 URL 图标）。 |
| 边框 | 扩展的九种边框样式、RGBA 和裁剪行为。 |

## 示例实际画面

以下是**开发 checkout** 的未修改 Android 模拟器截图，使用离线架空数据和日语界面。它们仅用于说明，不意味着已发布包生成相同像素，也不表示已完成 iOS 视觉验证。

<figure className="example-capture">

![Android 开发版示例：文本格式目录，离线架空数据，日语界面。](/img/example-text-format-android-develop.png)

<figcaption>Android 开发版示例——文本格式目录，离线架空数据，日语界面。亮色主题与默认共享设置。</figcaption>
</figure>

<figure className="example-capture">

![Android 开发版示例：Playground，离线架空数据，日语界面。](/img/example-playground-android-develop.png)

<figcaption>Android 开发版示例——Playground，离线架空数据，日语界面。加载所选目录示例及其设置，未作编辑。</figcaption>
</figure>

拍摄版本、原始 PNG 哈希和复现设置见仓库中的[截图来源记录](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/docs/screenshots.md)。

## 更多信息

[示例 README](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md) 进一步介绍目录、设置、本地测试数据和平台配置。若要将库加入自己的应用，请从[快速开始](getting-started.md)开始。
