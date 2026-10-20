---
id: configuration
slug: /configuration
title: 配置
sidebar_label: 配置
---

使用 `MfmRenderConfig` 设置渲染偏好和回调。`MfmConfig` 可向后代 `MfmText` widget 共享配置。不存在 `MfmRenderOptions` 类型。

## 共享配置

将此 widget 放入[快速开始](getting-started.md)中的应用。对于单个 widget，也可通过 `MfmText(config: ...)` 直接传入相同配置。

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class ConfigExample extends StatelessWidget {
  const ConfigExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MfmConfig(
      config: MfmRenderConfig(
        baseTextStyle: TextStyle(fontSize: 18, height: 1.5),
        enableAnimation: false,
        nyaizeMode: MfmNyaizeMode.disabled,
        codeCopyTooltip: 'Copy code',
        codeCopiedMessage: 'Code copied',
      ),
      child: MfmText(text: '**Shared style** and `inline code`'),
    );
  }
}
```

## 默认值与继承

| 设置 | 默认值／解析顺序 |
| --- | --- |
| `enableAdvancedMfm`, `enableAnimation` | 均为 `true`；`useAnimation` 是两者的逻辑与。 |
| `enableNyaize` | `false`；新代码优先使用显式 `nyaizeMode`。 |
| `baseTextStyle` | 已配置样式，否则使用 `DefaultTextStyle`；字号缺失时回退为 14。 |
| `brightness` | 显式值、Material 主题、Cupertino 主题、平台亮度依次回退，最后使用亮色。 |
| `lightColorScheme`, `darkColorScheme` | 继承值或 `MfmColorScheme.light()`／`.dark()` 预设。自动采用的是环境的**亮度模式**，而不是主题的全部颜色。 |
| `codeTheme`, `codeDarkTheme` | 亮色：github。暗色：显式暗色主题，然后 `codeTheme`，最后 atom-one-dark（`atomOneDarkTheme`）。 |
| `showCodeBlockCopyButton` | `null` 表示显示；设为 `false` 可隐藏。 |
| `useLocaleSearchButtonLabel` | `false`。没有 `searchButtonLabel` 时，标签由当前语言决定。设为 `true` 可清除显式／继承的标签并使用当前语言；它优先于 `searchButtonLabel`。 |

可空字段通常回退到继承设置。**取默认值的布尔字段并不无条件覆盖父配置**：子级的 `enableAnimation: true` 不会重新启用父级禁用的动画。应在共享配置边界设置有效选项，而不是逐帖尝试撤销。配置实例变化时，`MfmConfig` 会通知依赖项；可行时复用稳定实例，但主题或无障碍输入改变时仍需重建。

## 颜色、字体与代码

通过 `lightColorScheme`／`darkColorScheme` 定制 MFM 链接、提及、引用、代码等颜色。其 `copyWith` 适合仅修改部分颜色角色。请验证两种主题的对比度。

`fontFamilyResolver` 将 MFM 字体类型（如 `serif`、`monospace`）映射为字体族名称。返回 `null` 使用默认值。resolver 不会加载字体：自定义字体必须在应用中打包并声明。本库不要求 Google Fonts 依赖。

`codeTheme` 和 `codeDarkTheme` 接收高亮样式映射。未提供 `codeDarkTheme` 时，自定义的亮色 `codeTheme` 也会成为暗色模式的回退；避免在暗色模式意外采用低对比度的亮色样式。代码复制的回调和标签见[交互](interactions.md)。

## 猫语转换

- `MfmNyaizeMode.disabled`：不转换。
- `MfmNyaizeMode.enabled`：不考虑作者，对符合条件的文本进行转换。
- `MfmNyaizeMode.respectAuthor`：在 `author.isCat` 为 true 时转换。

显式模式优先于旧的 `enableNyaize` 标志。这只影响渲染，不会更新账号或改写已存储的 MFM。

## 复制与清除上下文

`copyWith(field: null)` 保留原字段，**不会**清除它。已发布的上下文重置标志是 `clearAuthor`、`clearEmojiUrls` 和 `clearLocalHost`。例如，`config.copyWith(clearAuthor: true, clearEmojiUrls: true)` 可在复用前移除帖子专属上下文。不要同时传入字段值和对应的清除标志，否则会抛出异常。清除本地配置不会移除从外层 `MfmConfig` 继承的值。

表情 handle 的 `copyWith` 共享生命周期所有权，不会产生可独立释放的新资源。见[自定义表情](custom-emoji.md)。

## 故障排查

若设置看似未生效，请检查最近的 `MfmConfig`、取默认值的布尔字段和 `enableAdvancedMfm`。若颜色与应用主题不同，请显式提供 MFM 配色，而不是期待自动颜色映射。

下一步：[自定义表情](custom-emoji.md) · [动画与无障碍](animation-accessibility.md) · [MfmRenderConfig API](https://pub.dev/documentation/misskey_mfm_renderer/latest/misskey_mfm_renderer/MfmRenderConfig-class.html)
