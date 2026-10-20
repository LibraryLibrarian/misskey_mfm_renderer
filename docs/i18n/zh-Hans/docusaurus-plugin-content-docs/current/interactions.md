---
id: interactions
slug: /interactions
title: 交互
sidebar_label: 交互
---

渲染器报告交互，由应用决定其含义。它**不会**自动打开 URL、跳转个人资料或发送搜索请求。

## 本地反馈示例

将此 widget 放入 `MaterialApp` 下的 `Scaffold` 中（见[快速开始](getting-started.md)）。所有操作仅显示本地 SnackBar，不需要 launcher 依赖或真实账号。

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

## 回调约定

| 回调 | 值与行为 |
| --- | --- |
| `onLinkTap` | 源文本中的原始 URL，不是可信或已过滤的目标。没有回调时不会自动打开。 |
| `onMentionTap` | 规范化账号。主机依次使用提及中显式指定的 host、`author.host`、`localHost`；没有 host 时保留原始账号。 |
| `onHashtagTapDetails` | 标签、`isNote` 和编码后的导航路径。优先于 `onHashtagTap`。 |
| `onHashtagTap` | 没有详情回调时，仅传递标签的回退。 |
| `onSearchTap` | 搜索查询；已发布版的搜索显示不是开发示例中的可编辑输入框。 |
| `onClickableEvent` | `$[clickable.ev=demo ...]` 中的 `ev` 值；缺失 `ev` 时为空字符串。没有此回调时，内容作为普通文本。 |
| `onCodeCopied` | 写入剪贴板后的完整代码。替代默认成功 SnackBar，不替代剪贴板写入本身。 |

话题标签在 `isNote: true` 时生成 `/tags/<encoded-tag>`，为 `false` 时生成 `/user-tags/<encoded-tag>`。它们是相对路径，不会自动选择服务器或导航器。

## URL 与事件策略由应用负责

将回调值视为不可信的帖子内容。打开链接前，按应用策略验证 URI scheme 和目标；不要将任意 scheme 直接传给 launcher。个人资料／服务器选择、认证、外部导航确认和允许的 clickable 事件 ID 也由应用负责。不要将事件 ID 解释为可执行代码。

## 复制反馈与无障碍

复制按钮默认显示，`showCodeBlockCopyButton: false` 可隐藏。`codeCopyTooltip` 是按钮的 **Semantics 标签**，不是可见的悬停提示。没有 `onCodeCopied` 时，仅在存在 `ScaffoldMessenger` 的情况下显示默认成功 SnackBar；`codeCopiedMessage` 可修改该消息。默认值会根据日语／其他语言环境进行本地化。

使用内置 Material 图标字形时，请保留应用 Flutter 配置中的 `uses-material-design: true`。自行替换交互 widget 时，应提供等效的标签和焦点行为。

## 故障排查

点击无响应时，请确认相应回调存在且启用了完整解析（不是 `simple`／`plain`）。同时提供两种话题标签回调时，仅使用详情回调。提及跳转到错误主机时，请检查每帖的 `author` 和共享的 `localHost`，而不是根据显示文本猜测。

下一步：[配置](configuration.md) · [自定义表情](custom-emoji.md) · [动画与无障碍](animation-accessibility.md)
