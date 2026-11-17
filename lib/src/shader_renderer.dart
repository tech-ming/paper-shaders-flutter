import 'dart:ui' as ui;

import 'shader_cache.dart';
import 'shader_paint.dart';
import 'shader_sampler.dart';
import 'shader_sizing.dart';
import 'shader_uniforms.dart';

/// 按逻辑尺寸与像素比离屏绘制，返回可供后续采样的 [ui.Image]。
class PaperShaderRenderer {
  /// 仅提供静态渲染入口。
  PaperShaderRenderer._();

  /// 输出单边最大像素；超限时拒绝渲染，避免静默裁切。
  static const int maxDimension = 8192;

  /// 返回由调用方释放的图片，采样图片所有权不变。
  /// 逻辑尺寸与像素比须为有限正数，输出单边超限时抛出 [ArgumentError]。
  static Future<ui.Image> render({
    required String assetKey,
    required ui.Size size,
    double pixelRatio = 1,
    List<ShaderUniform> uniforms = const <ShaderUniform>[],
    List<ShaderImageSampler> imageSamplers = const <ShaderImageSampler>[],
    ShaderSizing sizing = const ShaderSizing(),
    double frame = 0,
  }) async {
    _outputSize(size, pixelRatio);
    final program = await PaperShaderCache.program(assetKey);
    final images = await PaperShaderCache.images(imageSamplers);
    return renderProgram(
      program: program,
      size: size,
      pixelRatio: pixelRatio,
      uniforms: uniforms,
      imageSamplers: images,
      sizing: sizing,
      frame: frame,
    );
  }

  /// 使用已就绪的资源渲染；非法或超限尺寸抛出 [ArgumentError]。
  static Future<ui.Image> renderProgram({
    required ui.FragmentProgram program,
    required ui.Size size,
    double pixelRatio = 1,
    List<ShaderUniform> uniforms = const <ShaderUniform>[],
    List<ui.Image> imageSamplers = const <ui.Image>[],
    ShaderSizing sizing = const ShaderSizing(),
    double frame = 0,
  }) async {
    final outputSize = _outputSize(size, pixelRatio);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(pixelRatio);
    paintPaperShader(
      canvas,
      size,
      program: program,
      uniforms: uniforms,
      imageSamplers: imageSamplers,
      sizing: sizing,
      frame: frame,
    );
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(
        outputSize.width.toInt(),
        outputSize.height.toInt(),
      );
    } finally {
      picture.dispose();
    }
  }

  /// 在加载资源前校验输入，并将合法逻辑尺寸换算成像素尺寸。
  static ui.Size _outputSize(ui.Size size, double pixelRatio) {
    if (!size.width.isFinite || !size.height.isFinite || size.isEmpty) {
      throw ArgumentError.value(size, 'size', '逻辑尺寸必须为有限正数');
    }
    if (!pixelRatio.isFinite || pixelRatio <= 0) {
      throw ArgumentError.value(pixelRatio, 'pixelRatio', '像素比必须为有限正数');
    }
    final width = size.width * pixelRatio;
    final height = size.height * pixelRatio;
    if (!width.isFinite ||
        !height.isFinite ||
        width > maxDimension ||
        height > maxDimension) {
      throw ArgumentError.value(
        size,
        'size',
        '输出单边不能超过 $maxDimension 像素，请减小逻辑尺寸或像素比',
      );
    }
    return ui.Size(
      width.round().clamp(1, maxDimension).toDouble(),
      height.round().clamp(1, maxDimension).toDouble(),
    );
  }
}
