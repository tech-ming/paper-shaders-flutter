# Flutter 参考图比对

通过 macOS 示例应用生成固定时间的 PNG，与维护工作台中的上游 WebGL SwiftShader 参考图比较。

## 当前状态

下面的阈值来自旧实现，旧记录涉及 116 个参考图结果；它们不是当前版本的通过记录。0.0.4 改变了半透明颜色合成、纸纹、水面与默认底图，受影响效果的参考图与阈值需要重新确认。

新增 `lens-distortion` 的 4 个预设、重写后 `paper-texture` 的 4 个预设尚未完成比对。旧纸纹 Abstract / Cardboard / Details 的阈值已移除，新纸纹目前使用全局默认阈值。

示例与渲染入口使用效果的默认采样器；当前图片槽位默认透明，而旧 WebGL 参考图使用演示图片。直接运行旧比对不能证明这些图片效果的移植一致性，需要先对齐两端输入图片、参数、时间及背景。

## 工具条件

这些脚本用于维护者的参考图工作流，普通包接入无需准备：

- macOS、对应开发环境和 Flutter SDK；渲染脚本固定构建 macOS 示例。
- Bash 与 Python 3，用于运行脚本和解码 PNG 输出。
- 外部维护工作台，默认位于仓库同级的 `../paper-shaders-prd`；它不包含在本仓库中，需具有 `golden/` 与 `tools/compare-images.ts`。
- Bun 及比较器所需依赖，用于执行工作台中的 TypeScript 比较脚本。

在仓库根目录运行：

```sh
tool/render_flutter_goldens.sh
WORKBENCH=/path/to/paper-shaders-prd tool/check_flutter_parity.sh
```

比对脚本会自动重新渲染，单独生成 PNG 时才需要第一条命令。默认输出为 `build/flutter-goldens/`；每次渲染会替换该目录中的 PNG。`PARITY_OUT` 可指定另一输出目录，`FAIL_RATIO` 设置默认失败像素比例，默认值为 0.01。

缩略图工具另依赖 macOS 的 `sips`；拼图工具依赖 ImageMagick 的 `magick`。重新生成前应先准备与当前实现相符的完整参考图。

## 历史预设阈值

阈值表示比较器允许的失败像素比例，并非效果相似度评分。部分历史阈值很高，例如 95% 和 83%，只能说明该旧测试允许较大差异，不能作为视觉一致的证明。阈值以 `tool/check_flutter_parity.sh` 为准：

- `dot-orbit--bubbles.png`: 6%
- `dot-orbit--default.png`: 25%
- `dot-orbit--hallucinatory.png`: 3%
- `dot-grid--triangles.png`: 4%
- `dot-grid--wallpaper.png`: 8%
- `fluted-glass--default.png`: 4%
- `fluted-glass--waves.png`: 3%
- `god-rays--default.png`: 32%
- `god-rays--ether.png`: 15%
- `god-rays--linear.png`: 2%
- `god-rays--warp.png`: 32%
- `grain-gradient--blob.png`: 6%
- `grain-gradient--default.png`: 12%
- `grain-gradient--dots.png`: 29%
- `grain-gradient--ripple.png`: 23%
- `grain-gradient--truchet.png`: 27%
- `grain-gradient--wave.png`: 15%
- `gem-smoke--default.png`: 8%
- `gem-smoke--fire.png`: 15%
- `gem-smoke--fluorescent.png`: 8%
- `gem-smoke--infrared.png`: 35%
- `halftone-cmyk--default.png`: 32%
- `halftone-cmyk--drops.png`: 24%
- `halftone-cmyk--newspaper.png`: 19%
- `halftone-cmyk--vintage.png`: 28%
- `halftone-dots--default.png`: 11%
- `halftone-dots--mosaic.png`: 24%
- `halftone-dots--round-and-square.png`: 17%
- `heatmap--sepia.png`: 30%
- `liquid-metal--backdrop.png`: 2%
- `liquid-metal--default.png`: 3%
- `liquid-metal--stripes.png`: 4%
- `metaballs--background.png`: 95%
- `metaballs--default.png`: 36%
- `metaballs--ink-drops.png`: 5%
- `metaballs--solar.png`: 20%
- `perlin-noise--moss.png`: 11%
- `perlin-noise--nintendo-water.png`: 3%
- `perlin-noise--worms.png`: 2%
- `pulsing-border--default.png`: 7%
- `pulsing-border--northern-lights.png`: 13%
- `smoke-ring--default.png`: 7%
- `smoke-ring--line.png`: 4%
- `smoke-ring--solar.png`: 6%
- `swirl--007.png`: 2%
- `voronoi--bubbles.png`: 15%
- `voronoi--cells.png`: 15%
- `voronoi--default.png`: 21%
- `voronoi--lights.png`: 83%
- `warp--cauldron-pot.png`: 15%
- `warp--default.png`: 33%
- `warp--kelp.png`: 3%
- `warp--live-ink.png`: 31%
- `warp--nectar.png`: 45%
- `warp--passion.png`: 2%
- `waves--ride-the-wave.png`: 2%

## 差异来源与更新原则

噪声图片解码、随机场采样和抗锯齿会改变颗粒、细胞、光束或边缘。部分效果使用 `ps_pixelDerivative()` 替代测试环境不接受的 `fwidth(float)`；`spiral` 使用图案空间的有限差分。

烟雾、热力图、液态金属与玻璃效果还受预处理贴图、重复形变采样和缺少显式多级纹理采样的影响。旧水面记录没有单独阈值，但 0.0.4 已更改合成，不能沿用旧结果作为当前结论。

渲染入口在白色背景上合成后编码 PNG，以对应上游 HTML 的透明预设背景。更新基线时保持图片、尺寸、固定时间和背景一致，先查看差异图，再按预设调整阈值；不要调高全局阈值来吸收单个效果的问题。
