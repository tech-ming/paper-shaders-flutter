import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'shader_sampler.dart';

/// 按资源键常驻共享程序与资产贴图，并合并并发加载；失败后允许重试。
class PaperShaderCache {
  /// 仅提供共享缓存入口。
  PaperShaderCache._();

  static final Map<String, Future<ui.FragmentProgram>> _programs = {};
  static final Map<String, Future<ui.Image>> _images = {};

  /// 着色器程序（首次加载后常驻）
  static Future<ui.FragmentProgram> program(String assetKey) =>
      _programs[assetKey] ??= _loadProgram(assetKey);

  /// 采样贴图（解码后常驻；[ShaderImageSampler.transparent] 为内置生成的全透明图）
  ///
  /// 动态贴图（[ShaderImageSampler.image]）不进缓存、不释放：图由调用方持有，这里只按引用透传。
  static Future<ui.Image> image(ShaderImageSampler sampler) {
    final dynamicImage = sampler.image;
    if (dynamicImage != null) {
      return Future<ui.Image>.value(dynamicImage);
    }
    return _images[sampler.assetKey] ??= _loadImage(sampler);
  }

  /// 按声明顺序解析一组采样贴图（顺序即采样槽位）
  static Future<List<ui.Image>> images(List<ShaderImageSampler> samplers) =>
      Future.wait(samplers.map(image));

  /// 预热程序与贴图；失败原样抛出，由调用方决定是否忽略
  static Future<void> warm(
    String assetKey,
    List<ShaderImageSampler> samplers,
  ) async {
    await Future.wait<Object>([program(assetKey), images(samplers)]);
  }

  /// 加载程序并移除失败的缓存项。
  static Future<ui.FragmentProgram> _loadProgram(String assetKey) async {
    try {
      return await ui.FragmentProgram.fromAsset(assetKey);
    } catch (_) {
      _programs.remove(assetKey);
      rethrow;
    }
  }

  /// 解码资产贴图并释放解码器，失败时移除缓存项。
  static Future<ui.Image> _loadImage(ShaderImageSampler sampler) async {
    try {
      if (sampler.isTransparent) return await _makeTransparent();
      final bytes = await rootBundle.load(sampler.assetKey);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      try {
        final frame = await codec.getNextFrame();
        return frame.image;
      } finally {
        codec.dispose();
      }
    } catch (_) {
      _images.remove(sampler.assetKey);
      rethrow;
    }
  }

  /// 1×1 全透明贴图：挂一个 Canvas 开始录制但不画任何东西
  static Future<ui.Image> _makeTransparent() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(1, 1);
    } finally {
      picture.dispose();
    }
  }
}
