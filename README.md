# paper_shaders

将 [Paper Shaders](https://github.com/paper-design/shaders) 移植到 Flutter 的运行时着色器库，提供 30 种效果与 124 个预设，可用于动态背景、纹理和图片滤镜。

每种效果包含 GLSL 源码、类型化参数和组件。另提供共享资源缓存、动态图片采样与离屏渲染，运行依赖仅为 Flutter SDK，无原生插件。

> 本仓库是 [AndreFrelicot/paper-shaders-flutter](https://github.com/AndreFrelicot/paper-shaders-flutter) 的 fork，在其 0.0.3 之上增加镜头畸变、新版纸纹、共享缓存、动态图片采样与离屏渲染，并修正了半透明颜色的重复预乘。不发布到 pub.dev，通过 git 依赖接入。

![效果预览](doc/showcase-grid.jpg)

预览图生成于 0.0.3，不含镜头畸变与新版纸纹。

## 效果

| 类别 | 效果 |
| --- | --- |
| 渐变与色块 | `mesh-gradient`、`static-mesh-gradient`、`static-radial-gradient`、`grain-gradient`、`color-panels` |
| 噪声与流体 | `simplex-noise`、`perlin-noise`、`neuro-noise`、`voronoi`、`warp`、`swirl`、`spiral`、`waves`、`metaballs` |
| 光效与图案 | `god-rays`、`smoke-ring`、`pulsing-border`、`dot-orbit`、`dot-grid`、`dithering` |
| 图片滤镜 | `paper-texture`、`fluted-glass`、`water`、`lens-distortion`、`halftone-cmyk`、`halftone-dots`、`image-dithering` |
| 预处理贴图 | `gem-smoke`、`heatmap`、`liquid-metal` |

## 接入

要求 Flutter 3.27.0 / Dart 3.6.2 及以上。

在应用的 `pubspec.yaml` 中通过 git 依赖接入：

```yaml
dependencies:
  flutter:
    sdk: flutter
  paper_shaders:
    git:
      url: https://github.com/tech-ming/paper-shaders-flutter.git
      ref: main
```

`ref` 可以是分支、标签或提交哈希；需要可复现构建时锁定到提交哈希。本地联调时改用 `path:` 指向检出的仓库根目录即可。包内着色器和内置贴图已在包的 `pubspec.yaml` 中声明，宿主应用无需重复声明。

## 快速开始

```dart
import 'package:flutter/widgets.dart';
import 'package:paper_shaders/paper_shaders.dart';

/// 在明确尺寸内绘制静态渐变。
Widget buildGradient() {
  return const SizedBox(
    width: 320,
    height: 240,
    child: MeshGradientView(
      params: MeshGradientParams(
        colors: ['#e0eaff', '#241d9a'],
        speed: 0,
      ),
    ),
  );
}
```

组件会填满父级提供的有限布局空间。用于列表或滚动容器时，需要由父级明确宽高约束。

每个效果的 `XxxShader.presets` 提供类型化预设，可以直接把预设的 `params` 传给对应的 `XxxView`。通用选择器可遍历 `ShaderCatalog.all`，读取每项的名称、预设、采样贴图和动画标记。

- `speed` 为零时停止动画；`isAnimated` 为假时始终不启动动画循环。
- `frame` 的单位为毫秒，表示初始时间；例如 `frame: 1000` 对应着色器时间一秒。
- 资源首次加载及切换期间输出透明；加载失败经 `FlutterError.reportError` 上报。底色和错误展示由宿主应用处理。

## 图片滤镜

纸纹、玻璃折射、CMYK 半调、圆点半调、图片抖动、镜头畸变和水面默认使用透明底图。需要真实图片时，通过底层 `PaperShader` 指定 `imageSamplers`；类型化 `XxxView` 使用效果内置的默认采样器。

下面为已解码的图片添加纸纹：

```dart
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:paper_shaders/paper_shaders.dart';

/// 为调用方持有的图片添加纸纹。
Widget buildTexturedImage(ui.Image image) {
  final params = PaperTextureParams(
    isImage: true,
    colorPaper: '#f6f1e7',
    sizing: ShaderSizing.object(
      fit: ShaderFit.contain,
      imageAspectRatio: image.width / image.height,
    ),
  );
  return SizedBox(
    width: 320,
    height: 240,
    child: PaperShader(
      assetKey: PaperTextureShader.assetKey,
      uniforms: params.uniforms,
      imageSamplers: [
        ShaderImageSampler.image(image),
        ShaderImageSampler.noiseTexture,
      ],
      sizing: params.sizing,
      speed: params.speed,
      frame: params.frame,
      isAnimated: PaperTextureShader.isAnimated,
    ),
  );
}
```

采样槽位必须与效果声明一致：纸纹为「底图、噪声」，镜头畸变仅有底图。替换其他效果的底图时，可参考对应 `XxxShader.imageSamplers` 保留其余槽位。`imageAspectRatio` 应为输入图片的宽高比；纸纹还必须设置 `isImage: true`。

`ShaderImageSampler('assets/photo.png')` 可引用宿主应用已声明的资产；用户照片、离屏结果和其他动态图片使用 `ShaderImageSampler.image(image)`。

## 离屏渲染与图片所有权

`PaperShaderRenderer.render` 返回一张 `ui.Image`，可导出或继续作为下一次绘制的采样贴图。下面先生成渐变，再叠加纸纹：

```dart
import 'dart:ui' as ui;

import 'package:paper_shaders/paper_shaders.dart';

/// 渲染带纸纹的渐变，返回的图片由调用方释放。
Future<ui.Image> renderTexturedGradient() async {
  const size = ui.Size(320, 240);
  const gradient = MeshGradientParams(
    colors: ['#e0eaff', '#241d9a'],
    speed: 0,
  );
  final source = await PaperShaderRenderer.render(
    assetKey: MeshGradientShader.assetKey,
    size: size,
    uniforms: gradient.uniforms,
    sizing: gradient.sizing,
  );
  try {
    const paper = PaperTextureParams(isImage: true);
    return await PaperShaderRenderer.render(
      assetKey: PaperTextureShader.assetKey,
      size: size,
      pixelRatio: 2,
      uniforms: paper.uniforms,
      imageSamplers: [
        ShaderImageSampler.image(source),
        ShaderImageSampler.noiseTexture,
      ],
      sizing: const ShaderSizing.object(
        fit: ShaderFit.cover,
        imageAspectRatio: 320 / 240,
      ),
    );
  } finally {
    source.dispose();
  }
}
```

`size` 是逻辑尺寸，`pixelRatio` 控制输出像素密度；示例结果为 640 × 480 像素。逻辑尺寸与像素比必须为有限正数，输出单边不得超过 `PaperShaderRenderer.maxDimension`（8192 像素）；非法或超限输入抛出 `ArgumentError`，加载和绘制错误原样抛出。

| 图片来源 | 所有权与释放时机 |
| --- | --- |
| 资产采样器、内置透明图 | `PaperShaderCache` 按资源键常驻共享；调用方不得释放缓存返回的图片 |
| `ShaderImageSampler.image(image)` | 调用方持有；组件仍在使用或离屏渲染尚未完成时不得释放 |
| 离屏渲染返回值 | 调用方持有；展示、导出及后续采样全部完成后调用 `dispose()` |

`PaperShaderCache.warm(assetKey, imageSamplers)` 可预热资源；并发加载同一资源会合并，失败的缓存项会移除，之后可以重试。缓存没有容量淘汰，频繁更换的大图应使用动态采样器。

## 颜色与兼容性

颜色支持 `#RGB`、`#RGBA`、`#RRGGBB`、`#RRGGBBAA`、`rgb()`、`rgba()`、`hsl()` 与 `hsla()`。不支持的颜色格式或非法输入回退为中灰；CSS 命名颜色与 CSS 变量不受支持。颜色 uniform 传入未预乘 RGBA，由各着色器完成透明度合成。

包声明 Android、iOS、Linux、macOS、Windows 与 Web 平台，实际绘制依赖目标 Flutter 渲染后端对运行时着色器的支持。

与上游 WebGL 的已知渲染差异、各效果的同步进度和当前验证范围集中记录在[移植状态](doc/FLUTTER-PORT-STATUS.md)，参考图工具见[参考图比对](doc/FLUTTER-GOLDEN-PARITY.md)。

## 从 0.0.3 升级

- `PaperTextureParams` 改为三色纸纹模型，旧颜色、折痕和皱纹参数需要迁移，详见 [CHANGELOG](CHANGELOG.md)。
- `ShaderColor.premultiplied` 改为 `ShaderColor.components`，颜色 uniform 统一使用未预乘分量。
- 删除 `ShaderImageSampler.testImage` 与 `flowersImage`；原演示图片已从仓库移除，请自行提供图片。
- 图片效果默认底图改为透明，原先依赖内置演示图片的调用需要显式传入采样器。

## 示例与贡献

[示例应用](example/README.md)提供效果浏览、预设切换、参数调整与 Dart 代码复制。源码分布如下：

| 目录 | 职责 |
| --- | --- |
| `lib/paper_shaders.dart` | 公开接口入口 |
| `lib/src/` | 资源缓存、组件、离屏渲染和参数打包 |
| `lib/src/shaders/` | 每个效果的参数、预设与组件 |
| `shaders/` | GLSL 效果及公共函数 |
| `assets/` | 噪声与预处理采样贴图 |
| `test/` | 参数、目录及着色器编译测试 |
| `tool/` | 维护者使用的渲染与参考图工具 |

修改效果时同步更新参数顺序、GLSL 声明、预设、目录和示例参数定义；具体顺序约定见[移植状态](doc/FLUTTER-PORT-STATUS.md#uniform-布局)。文档与本仓库新增的代码使用中文注释；未改动的上游文件保留英文注释，便于合并上游更新。反馈问题时请附效果与预设名称、Flutter 版本、平台、最小复现和实际截图。

## 来源与许可证

本仓库基于 [AndreFrelicot/paper-shaders-flutter](https://github.com/AndreFrelicot/paper-shaders-flutter) 0.0.3，着色器算法、预设、噪声及预处理贴图衍生自 [paper-design/shaders](https://github.com/paper-design/shaders)。0.0.4 选取其 0.0.82 中的部分改动进行同步。

采用 Apache-2.0 许可证，见 [LICENSE](LICENSE) 与 [NOTICE](NOTICE)。再分发时保留许可证、归属说明和已有修改声明。
