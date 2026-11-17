## 0.0.4

选择性同步上游 paper-design/shaders 0.0.82，并增加可供宿主应用复用的渲染接口：

- 新增 `lens-distortion`：色差与桶形 / 枕形镜头形变，包含 4 个预设。
- 新增 `PaperShaderCache`：按资源键共享程序与资产贴图，合并并发加载，失败后允许重试。
- 新增 `ShaderImageSampler.transparent` 与 `ShaderImageSampler.image(ui.Image)`；动态图片由调用方持有与释放。
- 新增 `PaperShaderRenderer.render` / `renderProgram`：离屏返回 `ui.Image`，支持像素比与后续图片采样；逻辑尺寸与像素比须为有限正数，输出单边超过 8192 像素时抛出 `ArgumentError`。
- 屏上与离屏共用绘制逻辑；切换程序与图片时等待当前资源就绪，避免新参数配旧程序或旧图片。
- 图片解码器在成功与失败路径均会释放。
- 最低声明要求调整为 Dart 3.6.2 / Flutter 3.27.0，包与示例的开发依赖同步调整。
- 补充接入、图片所有权、离屏合成、升级与维护说明。

兼容性变化：

- `paper-texture` 按上游 0.0.81 重写：
  - 旧 `colorFront` 改为 `colorPaper`，新增 `colorShadow`，保留 `colorBack`。
  - 旧 `folds` / `foldCount` 改为 `crumples` / `crumpleCount`；旧 `crumples` / `crumpleSize` 改为 `wrinkles` / `wrinkleSize`。
  - 新增 `blending`、`distortion`、`clip`、`angle`、`roughnessSize`、`roughnessRows`，以及新的直线折痕 `folds`、`foldSizeX/Y`、`foldOffsetX/Y`。
  - 删除 `contrast` 与 `fade`；新增 `isImage`，使用真实底图时必须显式启用。
  - 预设改为 Default / Spread / Creased / Flat。
- 纸纹、玻璃折射、半调、图片抖动、镜头畸变和水面的默认底图改为透明；通过 `PaperShader.imageSamplers` 传入实际图片。
- 删除 `ShaderImageSampler.testImage` / `flowersImage`，演示图片从仓库移除。
- `ShaderColor.premultiplied` 改为 `components`；`Float4Uniform.color` 和 `Float4ArrayUniform.colors` 改传未预乘 RGBA，修正半透明颜色重复预乘导致偏暗的问题。
- 颜色解析新增 `#RGBA`、`rgb()` / `rgba()`、`hsl()` / `hsla()`，非法输入回退为中灰。
- `simplex-noise` 在取出颜色时预乘，并在预乘空间混合，输出时不再重复乘透明度。
- `water` 高光混合应用 `colorHighlight` 的透明度，图片合成恢复上游的预乘写法。
- 公共 GLSL 新增 `ps_imageUVAt()` 与 `ps_imagePixelStepX/Y()`。

当前视觉比对范围见 [Flutter 移植状态](doc/FLUTTER-PORT-STATUS.md)。

## 0.0.3

- 将没有时间依赖的效果标记为静态，绘制后停止动画，仅在视觉输入变化时重绘。
- 静态效果的示例停止 FPS 计数并隐藏运动控制。

## 0.0.2

- 优化 `perlin-noise` 的抗锯齿噪声采样，改善 Moss 等较重预设的性能。

## 0.0.1

- 首次移植 29 种 Paper Shaders 效果，提供参数类、组件、预设、目录与采样资产。
- 增加着色器编译测试和 120 个上游预设的确定性参考图工具。
