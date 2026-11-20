---
id: custom-emoji
slug: /custom-emoji
title: 自定义表情
sidebar_label: 自定义表情
---

服务器专属的 `:shortcodes:` 需要表情配置。没有 builder 时，它们会保持为字面文本。请按[快速开始](getting-started.md)安装渲染器。

## 默认目录与存储

`MfmEmojiConfig.createDefault` 将调用方拥有的 `MisskeyClient` 连接到持久化目录、resolver 和图片 builder。它返回的是 **handle**，而不只是配置。默认存储位置为应用文档目录，可用 `storagePath` 覆盖。默认存储使用 SQLite／Drift。应在页面或应用范围保持 handle 存活，而不是为时间线每条帖子单独创建。

下面的示例接收已创建的客户端。由于直接导入 `misskey_client`，请在应用中将其声明为直接依赖（兼容 `^1.0.0-beta.6`，而非较旧的 beta.5）。默认会进行在线后台同步。只有确实需要网络访问时，才传入明确选择的真实服务器客户端。

将此 widget 挂载在“快速开始”的应用下。客户端在 widget 整个生命周期中应保持不变；切换服务器时，用新的 key 替换 widget。客户端必须在 handle 的异步清理完成前保持有效。若应用整体关闭时必须等待这一顺序，请在 `State` 外拥有 handle，并在关闭客户端之前等待其释放。

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

## 所有权与异步清理

即使 widget 在初始化完成前被移除，示例也会等待初始化，然后释放返回的 handle。Flutter 的 `State.dispose` 不能是异步方法，因此清理单独执行并报告释放错误。不要丢弃初始化 Future，以免遗失稍后创建的 handle。

- `await handle.dispose()` 是幂等的，会先等待后台同步，再关闭目录／存储。
- 它**不会释放调用方的客户端**。
- `handle.copyWith(...)` 生成的副本共享生命周期状态。释放任意副本都会释放共享资源；不要逐帖释放。
- `autoSync: false` 禁用初始后台同步。`onSyncError` 允许应用观察同步失败；仅成功创建 handle 不能证明服务器同步成功。
- 目录数据变化时，`emojiRefreshListenable` 可通知已渲染表情。默认自动同步也会提供刷新通知。

## 远程帖子上下文

从 `handle` 派生每帖配置，传入 `author: MfmAuthorContext(host: 'remote.example')`，以及帖子中的表情名到图片 URL 映射 `emojiUrls`。本地作者的 host 为 null。辅助工具的 `localHost` 来自客户端的 origin。

将映射视为不可变数据，更新时替换它。**存在映射但缺少所请求短代码时，会回退为字面文本**；这与未提供映射不同。复用配置时，使用[已发布的清除标志](configuration.md)移除过期的帖子上下文。

## 已有 resolver 或自定义 builder

若应用已拥有目录／resolver，请使用 `MfmEmojiConfig.fromResolver(resolver: ..., serverBaseUrl: ...)`。它返回配置，而非拥有资源的 handle：调用方必须自行释放目录／存储。没有直接 URL 时，`serverBaseUrl` 可启用远程回退 URL；未提供时，无法解析的远程表情保持为短代码。

若需完全控制，`emojiBuilder` 接收 `(String name, MfmEmojiContext context)`，`unicodeEmojiBuilder` 接收 Unicode 字符串和同样的上下文。返回 Widget，并自行实现加载、错误和语义行为。已发布的上下文包含 `fontSize`、`scale`、`normal`、`host`、`url`、`useOriginalSize`，**不包含**开发版专属的 `textStyle`。自定义 resolver 或直接 URL 控制网络访问，应在此应用媒体／主机策略。

## 尺寸、基线与缓存

- 辅助工具默认高度为 **2em**，普通／plain 上下文中为 **1.25em**。`emojiSize` 指定固定高度，而非最小高度。独立使用的 `MfmCustomEmoji.size` 默认为 24。
- 与辅助工具一致的 builder 使用基线偏移 `size / 2 - context.fontSize * 0.25`；普通／plain 上下文中则使用 `context.fontSize * 0.25`。不要再次将图片乘以 `context.scale`，外层绘制变换已应用缩放。
- `emojiMaxWidth` 限制宽度。`useOriginalSize` 是给自定义 builder 的提示；若 resolver 不区分原图与缩略图 URL，辅助工具无法自动选择。
- URL 和宽高比缓存是进程级 LRU，各有 256 个条目。`cacheScope` 隔离身份。默认使用 resolver 身份或直接 URL；每次 build 都重新创建 resolver 闭包可能使复用失效。

## 平台与故障排查

支持原生 Android／iOS／macOS／Linux／Windows，不支持 Web。原生存储／网络配置见[示例 README](https://github.com/LibraryLibrarian/misskey_mfm_renderer/blob/develop/example/README.md)。构建时 SQLite／依赖下载与运行时同步是不同的事情。

若仍显示短代码，请检查 resolver、服务器 origin、每帖 host／映射、同步错误、图片可用性和原生网络权限。不要记录令牌，也不要将短代码回退直接视为认证错误。确定性的本地测试应禁用自动同步并注入假的存储／resolver；此类测试不能验证真实服务器同步。

下一步：[配置](configuration.md) · [交互](interactions.md) · [MfmEmojiConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmEmojiConfig-class.html)
