---
id: animation-accessibility
slug: /animation-accessibility
title: 动画与无障碍
sidebar_label: 动画与无障碍
---

动画默认启用。渲染器**不会**自动将动画标志连接到操作系统的“减少动态效果”偏好，需要在应用边界完成连接。

## 尊重减少动态效果设置

在[快速开始](getting-started.md)的 `MaterialApp` 下使用此 widget。它监听 `MediaQuery.disableAnimations` 的变化；应用级“禁用效果”偏好可与同一布尔值结合。

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class MotionExample extends StatelessWidget {
  const MotionExample({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MfmText(
      text: r'$[tada Hello] $[rainbow Color]',
      config: MfmRenderConfig(enableAnimation: !reduceMotion),
    );
  }
}
```

## 两个开关，不同用途

| 设置 | 结果 |
| --- | --- |
| `enableAnimation: false` | 禁用 MFM 动画，并在已实现的情况下保留静态格式／效果。`tada` 保持放大，`rainbow` 变为静态渐变，`sparkle` 保留内容但不显示效果。 |
| `enableAdvancedMfm: false` | 还会禁用高级尺寸／位置行为，并非仅用于减少动态效果。 |
| 两者启用 | 允许 MFM 动画（`useAnimation == true`）。 |

两个标志都不会停止 **GIF／APNG／WebP 表情图片动画**。应通过图片／表情 builder 和应用策略控制，例如提供静态图片。父配置禁用动画后，不能仅通过对子级传入默认值 `true` 撤销，见[配置](configuration.md)。

MFM 动画参数 `speed`／`delay` 使用秒，例如 `$[spin.speed=2s text]`，而不是 `2000ms`。在 Dart 中请用原始字符串保存 `$[...]`。

## 朗读、焦点与隐藏内容

- `blur` 只是视觉效果，其内容不会从语义树中排除，辅助技术可能朗读这些内容。**绝不要用它隐藏机密数据。**
- 注音和嵌入的 WidgetSpan 可能导致与视觉文本不同的朗读顺序或发音。请在实际目标设备上使用 TalkBack／VoiceOver 检查，不要假定完全符合无障碍要求。
- 未实现文本选择。如果需要复制或替代阅读视图，请在应用层使用原始内容和明确的文本转换规则提供。
- 为自定义表情／交互 widget 提供有意义的标签，并确保两套 MFM 配色的对比度足够。代码复制标签见[交互](interactions.md)。
- 在外围页面中测试较大的系统字号、长链接、引用、键盘／焦点导航。截图不能证明屏幕阅读器支持。

## 性能与故障排查

对于密集时间线，避免不必要地重建 resolver／配置实例，复用未变内容的解析节点，并限制可见动画 widget 的数量。制定策略前请在目标硬件上分析性能。本库不保证特定帧率，也不会自动暂停所有屏幕外效果。

禁用 MFM 动画后仍有动态效果时，首先区分图片动画与 MFM 效果。若大型／静态效果也需禁用，可考虑 `enableAdvancedMfm: false` 并检查视觉结果。若减少动态效果似乎未生效，请检查 `MediaQuery` 集成与继承配置。

下一步：[渲染](rendering.md) · [自定义表情](custom-emoji.md) · [示例应用](example.md)
