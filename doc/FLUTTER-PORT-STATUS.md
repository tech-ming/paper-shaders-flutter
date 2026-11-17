# Flutter 移植状态

## 当前范围

当前包版本为 0.0.4，提供 30 个效果、30 个公开组件与 124 个预设。`ShaderCatalog.all` 和 `pubspec.yaml` 的着色器资产声明均包含这 30 个效果。

本分支基于 Flutter 移植版 0.0.3，选取 paper-design/shaders 0.0.82 中的以下内容同步：

- 新增 `lens-distortion`，对应上游 0.0.79 / 0.0.80 的镜头畸变效果。
- `paper-texture` 更新为上游 0.0.81 的三色纸纹模型与新预设。
- 同步 `water` 高光透明度与颜色解析，并修正颜色 uniform 的预乘处理。
- 其余效果尚未逐项核对上游 0.0.82；30 个效果齐备不表示全部实现已与该版本一致。

本分支还加入共享资源缓存、动态图片采样、透明底图和离屏渲染，接入及升级方式见[主 README](../README.md)。

## 验证记录的范围

旧记录涉及 116 个参考图结果。它们产生于 0.0.4 的颜色 uniform 修复之前，不代表当前 124 个预设已经通过视觉比对。

新增镜头畸变的 4 个预设、重写纸纹的 4 个预设尚未重新比对。颜色合成、水面和默认底图也发生了变化，受影响预设需要用相同输入图片重新建立基线。仓库拼图和示例缩略图仍是历史资源。

现有 CI 配置包含格式、分析、测试、发布预检，以及 Android、Web、macOS 与 iOS 模拟器的示例构建。CI 使用 Flutter 3.41.9；最低声明版本 Flutter 3.27.0 / Dart 3.6.2 尚未单独验证，Linux 与 Windows 也没有构建任务。

## 效果目录

- `simplex-noise`
- `dot-orbit`
- `mesh-gradient`
- `waves`
- `pulsing-border`
- `halftone-cmyk`
- `paper-texture`
- `grain-gradient`
- `gem-smoke`
- `halftone-dots`
- `heatmap`
- `image-dithering`
- `liquid-metal`
- `color-panels`
- `dithering`
- `dot-grid`
- `god-rays`
- `metaballs`
- `neuro-noise`
- `perlin-noise`
- `smoke-ring`
- `spiral`
- `static-mesh-gradient`
- `static-radial-gradient`
- `swirl`
- `voronoi`
- `warp`
- `water`
- `fluted-glass`
- `lens-distortion`

## uniform 布局

屏上组件与离屏渲染共用 `lib/src/shader_paint.dart`。固定头部占 14 个 float：

| 索引 | 内容 |
| --- | --- |
| 0–1 | 逻辑分辨率宽、高 |
| 2 | 着色器像素比，固定为 1 |
| 3 | 时间，`frame` 毫秒转换为秒 |
| 4 | `fit.uniformValue` |
| 5 | `scale` |
| 6 | `rotation` |
| 7–8 | `originX`、`originY` |
| 9–10 | `offsetX`、`offsetY` |
| 11–12 | `worldWidth`、`worldHeight` |
| 13 | `imageAspectRatio` |

效果参数从 float 索引 14 开始，必须与 GLSL 声明顺序一致。采样器使用独立的索引，从 0 开始按声明顺序绑定。`pixelRatio` 通过缩放离屏画布控制输出密度，不改变头部的逻辑尺寸约定。

## 已知渲染差异

- 图片效果通过 `ps_imagePixelStepX/Y()` 获取图片 UV 的像素步长；仿射映射下为精确值，形变后的导数使用近似或有限差分。
- `paper-texture` 的低频噪声在上游依赖硬件线性过滤，移植版手动进行双线性插值。
- 为兼容 `flutter_tester` 的 SkSL 编译，部分效果以 `ps_pixelDerivative()` 替代 `fwidth(float)`；`spiral` 在图案空间使用局部有限差分。
- Flutter 运行时着色器不暴露显式多级纹理采样，图像和噪声效果无法保证与上游 WebGL 逐像素一致。
- 颜色数组 `vec4[10]` 通过常量索引辅助函数访问，避免动态数组索引的兼容性问题。

## 维护约定

新增或修改效果时，同步维护参数类、GLSL、目录、预设、示例参数定义和资产声明。参数或采样器顺序变化必须同步屏上与离屏调用。

包内资产由共享缓存持有，动态图片及离屏结果由调用方持有；不要在组件销毁时释放缓存图片，也不要在渲染仍使用图片时释放动态图片。

参考图更新需记录输入图片、固定时间和生成环境；旧阈值仅作为历史参考。工具依赖与阈值见[参考图比对](FLUTTER-GOLDEN-PARITY.md)。
