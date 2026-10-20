---
id: rendering
slug: /rendering
title: 渲染 MFM
sidebar_label: 渲染 MFM
---

`MfmText` 在原生 Flutter widget 中渲染 Misskey Flavored Markdown。请按[快速开始](getting-started.md)安装已发布包；本指南中可复制的示例以该公开 API 为准，而非开发版示例。

## 有边界的渲染区域

将此 widget 放入“快速开始”中 Material 应用的 body。对 `$[...]` 使用 Dart **原始字符串**，避免 Dart 将 `$` 解释为插值。

```dart
import 'package:flutter/material.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

class RenderExample extends StatelessWidget {
  const RenderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 320,
      child: MfmText(
        text: r'**Hello** $[fg.color=336699 blue] $[x2 large]',
        config: MfmRenderConfig(enableAnimation: false),
      ),
    );
  }
}
```

## 输入与显示模式

| 输入 | 行为 |
| --- | --- |
| `text` | MFM 源文本；空字符串不渲染任何内容。 |
| `parsedNodes` | 由 `misskey_mfm_parser` 预先解析的 `List<MfmNode>`。重复渲染相同解析结果时可复用，且优先于 `text`。若应用直接导入解析器，请将其声明为直接依赖。 |
| `simple: true` | 使用简单解析器：普通文本、提及、话题标签、URL 和大多数格式不会按完整 MFM 处理。仍支持 Unicode／自定义表情。 |
| `plain: true` | 同样使用简单解析；表情使用普通尺寸的渲染上下文。这不是通用的 HTML／Markdown 安全过滤器。 |
| `nowrap: true` | 单行显示，超出部分以省略号表示。请为 widget 提供有限的可用宽度。 |
| `rootScale` | 正且有限的根缩放值（默认 `1.0`）；影响 MFM 渲染，而不是应用的无障碍偏好。 |
| `isNote` | 默认为 `true`；改变话题标签的导航详情，不影响解析器。见[交互](interactions.md)。 |

必须提供 `text` 或 `parsedNodes`；构造函数会断言至少存在一个。解析器发生 `FormatException` 时，会将完整源文本作为纯文本显示。这不保证所有格式错误的输入都会抛出异常或得到安全过滤。每帖的主机／表情上下文请参阅[自定义表情](custom-emoji.md)。

## 支持的语法

| 类别 | 示例／行为 |
| --- | --- |
| 文本 | 粗体 `**text**`、斜体 `*text*`、删除线 `~~text~~`、小字 `<small>text</small>`、居中 `<center>text</center>`。 |
| 导航 | URL、`[label](https://example.com)`、`@name`、`#tag` 和搜索块。导航通过回调驱动。 |
| 代码与引用 | 反引号行内代码、支持高亮／复制的围栏代码块、`> quote`。引用需要有限的布局宽度。 |
| 表情 | Unicode 表情和 `:shortcode:`。服务器表情需要表情 builder／resolver。 |
| 数学公式 | 行内／块级公式显示为**等宽文本**，不渲染 LaTeX。 |
| 纯文本区域 | `<plain>...</plain>` 保留内容的字面形式。 |

### 函数块

| 函数类别 | 已发布版行为 |
| --- | --- |
| `x2`, `x3`, `x4`, `scale`, `position` | 尺寸与位置效果；高级 MFM 设置会影响其应用。 |
| `fg`, `bg`, `font`, `border` | 文本／背景颜色、字体选择和边框。不要假定已发布包包含开发示例中的扩展边框选项。 |
| `flip`, `rotate` | 静态变换。 |
| `blur` | 可揭示内容的视觉模糊；不是安全或信息遮蔽边界。 |
| `ruby`, `unixtime` | 注音和时间戳显示；参阅[示例页面](example.md)中的开发版差异。 |
| `clickable` | 通过回调派发事件 ID。 |
| `jelly`, `tada`, `jump`, `bounce`, `shake`, `twitch`, `spin`, `rainbow`, `sparkle` | 动画／效果函数。禁用动态效果的方法见[动画与无障碍](animation-accessibility.md)。 |

未知函数在渲染子内容的同时，保留字面的 `$[name ...]` 包裹文本，不应用未知效果。支持这些函数并不保证输出与 Misskey 浏览器渲染器逐像素一致。

## 限制与故障排查

- **不支持 Web**，也**不支持文本选择**。输出使用嵌入 widget 的 RichText，而非 SelectableText。
- 若引用或长内容溢出，请使用有边界的父级，例如 Row 中的 `Expanded`。
- 字体和字形缺失取决于平台。请设置[文本／字体配置](configuration.md)，不要假定各操作系统字体一致。
- 对渲染后 span 调用 `toPlainText()` 不是可靠的语义文本导出方式：嵌入 widget 和视觉变换可能与源文本不同。请保留原文或定义应用专用的文本转换。
- 自定义表情 resolver 失败或缺失时会保留短代码，这不表示 MFM 解析失败。

下一步：[配置](configuration.md) · [自定义表情](custom-emoji.md) · [API 参考](https://pub.dev/documentation/misskey_mfm_renderer/latest/)
