---
id: overview
slug: /
title: 概览
sidebar_label: 概览
---

# misskey_mfm_renderer

使用 `MfmText` 在 Flutter 中渲染 [Misskey Flavored Markdown（MFM）](https://misskey-hub.net/en/docs/for-users/features/mfm/)。MFM 在常见文本格式的基础上增加了自定义表情、变换和动画等功能。

本库将 MFM 文本或已解析的节点转换为 Flutter widget，不负责获取时间线，也不是完整的 Misskey 应用。文本、渲染设置和交互处理均由应用提供。

## 从这里开始

- [快速开始](getting-started.md)：无需配置服务器连接即可显示第一段 MFM 文本。
- [示例应用](example.md)：浏览目录，在 Playground 中尝试文本和设置。
- [渲染](rendering.md)：输入、显示模式、支持的语法与限制。
- [配置](configuration.md)：共享样式、颜色、字体和猫语转换。
- [自定义表情](custom-emoji.md)：初始化、所有权、远程帖子和自定义 builder。
- [交互](interactions.md)：回调和应用的导航策略。
- [动画与无障碍](animation-accessibility.md)：减少动态效果和朗读限制。
- [API 参考](https://pub.dev/documentation/misskey_mfm_renderer/latest/)：最新已发布包的自动生成 API 文档。

指南中可复制的示例以“快速开始”使用的已发布包为准。仅开发版提供的功能和截图在示例页面中另行标明。

## 可以渲染的内容

- 文本格式、引用、代码、链接、提及和话题标签。
- Unicode 表情和自定义表情，可配置解析与渲染方式。
- 用于尺寸、变换、样式和动画的 MFM `fn` 函数。

可通过颜色、文本样式、回调和动画设置定制渲染。[渲染指南](rendering.md)说明了支持的函数与限制；这并不意味着所有 Misskey 功能都已实现。

## 支持的环境

本包支持 **Android、iOS、macOS、Linux 和 Windows**，要求 Flutter **3.38.1 或更高版本**、Dart **3.10.0 或更高版本**。

**不支持 Web。** 虽然 Web 构建可能编译成功，但默认自定义表情配置没有 Web 存储实现，Web 渲染也未经测试。本网站是文档，而非 Flutter 示例的浏览器版本。

渲染后的文本不支持选择。需要复制操作的应用应使用原始 MFM 文本。

自定义表情功能使用本包随附的 `misskey_emoji`。默认配置拥有持久化 SQLite 存储，需要初始化和释放。[最小文本示例](getting-started.md)不需要此配置。在配置原生存储和图片加载前，请阅读[自定义表情指南](custom-emoji.md)。

## 已发布包与开发示例

安装指南使用已发布的包依赖。仓库的 `develop` 分支、README 和随附示例可能包含尚未发布的变更。使用标为未发布的功能前，请查阅 [CHANGELOG](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/CHANGELOG.md)。
