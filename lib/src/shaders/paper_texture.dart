import 'package:flutter/widgets.dart';

import '../shader_catalog.dart';
import '../shader_mount.dart';
import '../shader_sampler.dart';
import '../shader_sizing.dart';
import '../shader_uniforms.dart';

/// 纸纹着色器参数（对应上游 0.0.81 的三色方案）
class PaperTextureParams {
  /// 创建纸纹参数。
  const PaperTextureParams({
    this.colorBack = '#d3d2ab',
    this.colorPaper = '#ffffff',
    this.colorShadow = '#cccccc',
    this.isImage = false,
    this.blending = 1,
    this.distortion = 0.75,
    this.clip = false,
    this.angle = 300,
    this.seed = 4,
    this.roughness = 0.4,
    this.roughnessSize = 0.5,
    this.roughnessRows = 0,
    this.fiber = 0.4,
    this.fiberSize = 0.5,
    this.folds = 0.5,
    this.foldSizeX = 1,
    this.foldSizeY = 1,
    this.foldOffsetX = 0,
    this.foldOffsetY = 0,
    this.wrinkles = 1,
    this.wrinkleSize = 0.65,
    this.crumples = 0,
    this.crumpleCount = 6,
    this.drops = 0.4,
    this.sizing = const ShaderSizing.object(fit: ShaderFit.contain, scale: 0.9),
    this.speed = 0,
    this.frame = 0,
  });

  /// 纸张后面的底色
  final String colorBack;

  /// 纸张颜色
  final String colorPaper;

  /// 纸面纹理（阴影）颜色
  final String colorShadow;

  /// 底图槽位是否挂了真实图片；为 false 时不采样底图，[clip] 也不生效
  final bool isImage;

  /// 图片与纸面的融合程度（0 到 1，需要图片）
  final double blending;

  /// 图片随纸面起伏的弯曲程度（-1 到 1，需要图片）
  final double distortion;

  /// 把纸张裁到图片边框内（需要图片）
  final bool clip;

  /// 光照方向，角度（0 到 360），也是粗糙纹成行的方向
  final double angle;

  /// 随机种子（0 到 1000）
  final double seed;

  /// 均匀覆盖的细颗粒（0 到 1）
  final double roughness;

  /// 颗粒尺度（0 到 1）
  final double roughnessSize;

  /// 颗粒成行程度：0 均匀散布，1 排成直纹（0 到 1）
  final double roughnessRows;

  /// 卷曲的纤维噪声（0 到 1）
  final double fiber;

  /// 纤维尺度（0 到 1）
  final double fiberSize;

  /// 横竖直线折痕（0 到 1）
  final double folds;

  /// 竖向折痕的间距（0 到 1）
  final double foldSizeX;

  /// 横向折痕的间距（0 到 1）
  final double foldSizeY;

  /// 竖向折痕的位置偏移（0 到 1）
  final double foldOffsetX;

  /// 横向折痕的位置偏移（0 到 1）
  final double foldOffsetY;

  /// 铺满纸面的细碎皱纹（0 到 1）
  final double wrinkles;

  /// 皱纹尺度（0 到 1）
  final double wrinkleSize;

  /// 不规则的大块揉皱（0 到 1）
  final double crumples;

  /// 揉皱的块数（2 到 15）
  final double crumpleCount;

  /// 斑点，压暗图片而不是给它上色（0 到 1）
  final double drops;

  /// 画布与图片的映射设置。
  final ShaderSizing sizing;

  /// 动画速度。
  final double speed;

  /// 初始时间，单位为毫秒。
  final double frame;

  /// 按着色器声明顺序打包的参数。
  List<ShaderUniform> get uniforms {
    return <ShaderUniform>[
      Float4Uniform.color(colorBack),
      Float4Uniform.color(colorPaper),
      Float4Uniform.color(colorShadow),
      FloatUniform(isImage ? 1 : 0),
      FloatUniform(blending),
      FloatUniform(distortion),
      FloatUniform(clip ? 1 : 0),
      FloatUniform(angle),
      FloatUniform(seed),
      FloatUniform(roughness),
      FloatUniform(roughnessSize),
      FloatUniform(roughnessRows),
      FloatUniform(fiber),
      FloatUniform(fiberSize),
      FloatUniform(folds),
      FloatUniform(foldSizeX),
      FloatUniform(foldSizeY),
      FloatUniform(foldOffsetX),
      FloatUniform(foldOffsetY),
      FloatUniform(wrinkles),
      FloatUniform(wrinkleSize),
      FloatUniform(crumples),
      FloatUniform(crumpleCount),
      FloatUniform(drops),
    ];
  }
}

/// 纸纹的命名预设。
class PaperTexturePreset {
  /// 创建纸纹预设。
  const PaperTexturePreset(this.name, this.params);

  /// 预设名称。
  final String name;

  /// 效果参数。
  final PaperTextureParams params;
}

/// 纸纹的目录元数据。
class PaperTextureShader {
  /// 仅提供静态成员。
  const PaperTextureShader._();

  /// 效果名称。
  static const name = 'paper-texture';

  /// 着色器程序的资产路径。
  static const assetKey = 'packages/paper_shaders/shaders/paper_texture.frag';
  static const isAnimated = false;

  /// 揉皱块数上限（着色器循环上界）
  static const maxCrumpleCount = 15;

  /// 底图槽位默认用内置透明贴图：不叠任何图片，只出纸张质感（要叠图时自行传 PaperShader）
  static const imageSamplers = <ShaderImageSampler>[
    ShaderImageSampler.transparent,
    ShaderImageSampler.noiseTexture,
  ];

  /// 内置预设。
  static const presets = <PaperTexturePreset>[
    PaperTexturePreset('Default', PaperTextureParams()),
    PaperTexturePreset(
      'Spread',
      PaperTextureParams(
        colorBack: '#ffffff00',
        colorPaper: '#ffffffb5',
        colorShadow: '#b3b3b3',
        distortion: -0.3,
        clip: true,
        angle: 236,
        seed: 613,
        roughness: 0.15,
        roughnessSize: 0.25,
        fiber: 0.5,
        folds: 1,
        foldSizeX: 0.4,
        foldSizeY: 0.89,
        wrinkles: 0,
        crumpleCount: 9,
        drops: 0,
      ),
    ),
    PaperTexturePreset(
      'Creased',
      PaperTextureParams(
        colorShadow: '#b3b3b3',
        distortion: -0.5,
        angle: 60,
        seed: 49,
        roughnessSize: 0.25,
        folds: 0,
        foldSizeX: 0.6,
        foldSizeY: 0.89,
        foldOffsetX: 0.59,
        foldOffsetY: 1,
        wrinkles: 0,
        crumples: 1,
        crumpleCount: 4,
        drops: 0,
      ),
    ),
    PaperTexturePreset(
      'Flat',
      PaperTextureParams(
        colorBack: '#d4cdab',
        colorPaper: '#ffffffa8',
        colorShadow: '#b3b3b3',
        distortion: 0,
        angle: 0,
        seed: 455,
        roughness: 1,
        roughnessRows: 0.6,
        fiber: 0.7,
        fiberSize: 1,
        folds: 0,
        foldSizeX: 0,
        foldSizeY: 0.44,
        wrinkles: 0,
        wrinkleSize: 0,
        drops: 0.2,
      ),
    ),
  ];

  /// 目录条目。
  static final catalogEntry = ShaderCatalogEntry(
    name: name,
    assetKey: assetKey,
    isAnimated: isAnimated,
    imageSamplers: imageSamplers,
    presets: presets
        .map((preset) {
          return ShaderPreset(
            name: preset.name,
            sizing: preset.params.sizing,
            uniforms: preset.params.uniforms,
            speed: preset.params.speed,
            frame: preset.params.frame,
          );
        })
        .toList(growable: false),
  );
}

/// 绘制纸纹效果的组件。
class PaperTextureView extends StatelessWidget {
  /// 创建纸纹组件。
  const PaperTextureView({this.params = const PaperTextureParams(), super.key});

  /// 效果参数。
  final PaperTextureParams params;

  @override
  /// 构建着色器组件。
  Widget build(BuildContext context) {
    return PaperShader(
      assetKey: PaperTextureShader.assetKey,
      isAnimated: PaperTextureShader.isAnimated,
      uniforms: params.uniforms,
      imageSamplers: PaperTextureShader.imageSamplers,
      sizing: params.sizing,
      speed: params.speed,
      frame: params.frame,
    );
  }
}
