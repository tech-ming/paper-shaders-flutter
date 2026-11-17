# Paper Shaders 示例

`paper_shaders` 的交互式示例应用，通过 `path: ..` 使用仓库根目录的包。

支持浏览 30 种效果与 124 个预设、调整映射与效果参数、选择颜色，并复制当前配置对应的 Dart 初始化代码。静态效果不启用动画与 FPS 计数。

## 运行

从仓库根目录进入示例并选择本机已配置的平台：

```sh
cd example
flutter pub get
flutter run
```

可通过 `-d` 选择设备，例如 `flutter run -d chrome` 或 `flutter run -d macos`。平台构建需要对应的开发环境。

## 图片效果与预览

示例使用目录里的默认采样器。纸纹、玻璃折射、半调、图片抖动、镜头畸变和水面的底图默认为透明；需要查看真实图片滤镜时，按[主 README 的图片示例](../README.md#图片滤镜)传入图片。

缩略图是此前参考图的静态资源，与实时画布使用的输入并不相同。0.0.4 尚未重新生成整套缩略图，`lens-distortion` 当前没有缩略图，会显示占位图标。

## 维护入口

`lib/showcase_uniforms.dart` 声明可编辑参数及其顺序。新增或调整效果时，应与包内参数和 GLSL 声明一起更新。

应用另有确定性参考图渲染入口，会遍历 `ShaderCatalog.all` 并在固定时间捕获预设。渲染脚本依赖 macOS；与上游比对还需要外部工作台、参考图和 Bun，具体条件见[参考图比对文档](../doc/FLUTTER-GOLDEN-PARITY.md)。
