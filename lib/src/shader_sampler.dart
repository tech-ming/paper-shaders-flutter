import 'dart:ui' as ui;

/// 采样贴图引用：资产由缓存持有，动态图片由调用方持有与释放。
class ShaderImageSampler {
  /// 资产贴图
  const ShaderImageSampler(this.assetKey) : image = null;

  /// 动态贴图：调用方持有，引擎只用不释放
  const ShaderImageSampler.image(ui.Image source)
      : image = source,
        assetKey = dynamicKey;

  /// 内置 1×1 全透明贴图（非资源文件，由 PaperShaderCache 生成）
  ///
  /// 给「底图可选」的着色器占位，使其退化为纯纹理：例如纸纹不叠任何图片，只出纸张质感。
  static const transparent = ShaderImageSampler(_transparentKey);

  static const String _transparentKey = 'builtin:transparent';

  /// 动态贴图的标识资源键：只作标识，不进缓存
  static const String dynamicKey = 'builtin:image';

  /// 内置噪声贴图。
  static const noiseTexture = ShaderImageSampler(
    'packages/paper_shaders/assets/noise.png',
  );

  /// 烟雾效果的预处理贴图。
  static const gemSmokeImage = ShaderImageSampler(
    'packages/paper_shaders/assets/gem_smoke.png',
  );

  /// 热力图效果的预处理贴图。
  static const heatmapImage = ShaderImageSampler(
    'packages/paper_shaders/assets/heatmap.png',
  );

  /// 液态金属效果的预处理贴图。
  static const liquidMetalImage = ShaderImageSampler(
    'packages/paper_shaders/assets/liquid_metal.png',
  );

  /// 资产路径或内置来源标识。
  final String assetKey;

  /// 动态贴图；资产贴图为 null
  final ui.Image? image;

  /// 是否内置透明贴图（不走资源加载）
  bool get isTransparent => assetKey == _transparentKey;

  /// 是否动态贴图（调用方持有）
  bool get isDynamic => image != null;

  /// 两个采样器是否指向同一份贴图
  ///
  /// 动态贴图按引用比较：调用方换了图就应当重新取值。资产贴图按资源键比较。
  bool sameSource(ShaderImageSampler other) {
    if (isDynamic || other.isDynamic) {
      return identical(image, other.image);
    }
    return assetKey == other.assetKey;
  }
}
