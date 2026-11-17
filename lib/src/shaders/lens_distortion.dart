import 'package:flutter/widgets.dart';

import '../shader_catalog.dart';
import '../shader_mount.dart';
import '../shader_sampler.dart';
import '../shader_sizing.dart';
import '../shader_uniforms.dart';

/// 镜头畸变着色器参数：把图片拆成错位的色层（色差），并按桶形 / 枕形弯曲画面
class LensDistortionParams {
  /// 创建镜头畸变参数。
  const LensDistortionParams({
    this.spread = 0.6,
    this.bias = 1,
    this.angle = 0,
    this.perspective = 0.1,
    this.count = 35,
    this.dispersion = 1,
    this.dispersionShift = 0,
    this.dispersionColor = 0.6,
    this.focusCenter = 0.8,
    this.focusEdges = 1,
    this.swirl = 0.35,
    this.noise = 0,
    this.noiseFrequency = 0.25,
    this.noiseOffset = 0,
    this.lensBulge = 0,
    this.lensCircle = 0,
    this.grainMixer = 0,
    this.grainOverlay = 0,
    this.imageX = 0,
    this.imageY = 0,
    this.sizing = const ShaderSizing.object(
      fit: ShaderFit.contain,
      imageAspectRatio: 1,
    ),
    this.speed = 0,
    this.frame = 0,
  });

  /// 色层错开的强度，0 为关闭（0 到 1）
  final double spread;

  /// 色层向一端聚拢的程度，0 为均匀（-1 到 1）
  final double bias;

  /// 错开方向，角度（0 到 360）
  final double angle;

  /// 错开方向从直线（0）过渡到由中心放射（1）
  final double perspective;

  /// 采样的色层数，越多越平滑也越耗性能（2 到 50）
  final double count;

  /// 色散总量：1 每层取光谱上的一种颜色，0 保持原图颜色（0 到 1）
  final double dispersion;

  /// 色散在中心与边缘之间的分配：-1 只在中心，1 只在边缘（-1 到 1）
  final double dispersionShift;

  /// 色散颜色沿色相环旋转（0 到 1 为一整圈）
  final double dispersionColor;

  /// 削弱中心圆形区域的错开（0 到 1）
  final double focusCenter;

  /// 削弱边缘的错开，1 时边缘还原为原图（0 到 1）
  final double focusEdges;

  /// 色层绕中心旋转，角度沿错开方向递增（-1 到 1）
  final double swirl;

  /// 用噪声打散错开方向（0 到 1）
  final double noise;

  /// 噪声频率，越大越细（0 到 1）
  final double noiseFrequency;

  /// 噪声偏移，相当于换种子（0 到 1）
  final double noiseOffset;

  /// 径向镜头形变：正值鱼眼外凸，负值枕形内收（-1 到 1）
  final double lensBulge;

  /// 把内切圆之外的像素向内挤，使轮廓成为圆形（0 到 1）
  final double lensCircle;

  /// 用颗粒噪声打散色层边缘（0 到 1）
  final double grainMixer;

  /// 后期黑白颗粒叠加（0 到 1）
  final double grainOverlay;

  /// 图片在效果后面的横向平移（-1 到 1）
  final double imageX;

  /// 图片在效果后面的纵向平移（-1 到 1）
  final double imageY;

  /// 画布与图片的映射设置。
  final ShaderSizing sizing;

  /// 动画速度。
  final double speed;

  /// 初始时间，单位为毫秒。
  final double frame;

  /// 按着色器声明顺序打包的参数。
  List<ShaderUniform> get uniforms {
    return <ShaderUniform>[
      FloatUniform(spread),
      FloatUniform(bias),
      FloatUniform(angle),
      FloatUniform(perspective),
      FloatUniform(count),
      FloatUniform(dispersion),
      FloatUniform(dispersionShift),
      FloatUniform(dispersionColor),
      FloatUniform(focusCenter),
      FloatUniform(focusEdges),
      FloatUniform(swirl),
      FloatUniform(noise),
      FloatUniform(noiseFrequency),
      FloatUniform(noiseOffset),
      FloatUniform(lensBulge),
      FloatUniform(lensCircle),
      FloatUniform(grainMixer),
      FloatUniform(grainOverlay),
      FloatUniform(imageX),
      FloatUniform(imageY),
    ];
  }
}

/// 镜头畸变的命名预设。
class LensDistortionPreset {
  /// 创建镜头畸变预设。
  const LensDistortionPreset(this.name, this.params);

  /// 预设名称。
  final String name;

  /// 效果参数。
  final LensDistortionParams params;
}

/// 镜头畸变的目录元数据。
class LensDistortionShader {
  /// 仅提供静态成员。
  const LensDistortionShader._();

  /// 效果名称。
  static const name = 'lens-distortion';

  /// 着色器程序的资产路径。
  static const assetKey = 'packages/paper_shaders/shaders/lens_distortion.frag';
  static const isAnimated = false;

  /// 色层数上限（着色器循环上界）
  static const maxSamples = 50;

  /// 纯图片滤镜：默认透明占位，没有图片时输出透明
  static const imageSamplers = <ShaderImageSampler>[
    ShaderImageSampler.transparent,
  ];

  /// 内置预设。
  static const presets = <LensDistortionPreset>[
    LensDistortionPreset('Default', LensDistortionParams()),
    LensDistortionPreset(
      'Fisheye',
      LensDistortionParams(
        spread: 0.7,
        perspective: 0.75,
        count: 15,
        dispersionColor: 0.7,
        focusCenter: 0.9,
        swirl: 1,
        lensBulge: 0.95,
        lensCircle: 1,
        grainMixer: 0.5,
      ),
    ),
    LensDistortionPreset(
      'Duotone',
      LensDistortionParams(
        spread: 0.1,
        bias: 0,
        perspective: 0,
        count: 2,
        dispersionColor: 0.1,
        focusCenter: 0,
        focusEdges: 0,
        swirl: 0,
        grainMixer: 0.1,
        grainOverlay: 0.3,
      ),
    ),
    LensDistortionPreset(
      'Smoke',
      LensDistortionParams(
        spread: 0.65,
        bias: -1,
        perspective: 0.4,
        count: 50,
        dispersion: 0,
        dispersionColor: 0.31,
        focusCenter: 0,
        focusEdges: 0.6,
        swirl: 0,
        noise: 1,
        noiseFrequency: 0.35,
        noiseOffset: 0.3,
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

/// 绘制镜头畸变效果的组件。
class LensDistortionView extends StatelessWidget {
  /// 创建镜头畸变组件。
  const LensDistortionView({
    this.params = const LensDistortionParams(),
    super.key,
  });

  /// 效果参数。
  final LensDistortionParams params;

  @override
  /// 构建着色器组件。
  Widget build(BuildContext context) {
    return PaperShader(
      assetKey: LensDistortionShader.assetKey,
      isAnimated: LensDistortionShader.isAnimated,
      uniforms: params.uniforms,
      imageSamplers: LensDistortionShader.imageSamplers,
      sizing: params.sizing,
      speed: params.speed,
      frame: params.frame,
    );
  }
}
