import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:paper_shaders/paper_shaders.dart';

/// 验证离屏输入在加载资源前被拒绝，避免静默裁切或触发无关加载。
void main() {
  test('离屏渲染在加载资源前拒绝非法逻辑尺寸', () async {
    for (final size in const <ui.Size>[
      ui.Size.zero,
      ui.Size(-1, 10),
      ui.Size(double.nan, 10),
      ui.Size(10, double.infinity),
    ]) {
      await expectLater(
        PaperShaderRenderer.render(assetKey: 'missing.frag', size: size),
        throwsArgumentError,
      );
    }
  });

  test('离屏渲染在加载资源前拒绝非法像素比', () async {
    for (final ratio in <double>[0, -1, double.nan, double.infinity]) {
      await expectLater(
        PaperShaderRenderer.render(
          assetKey: 'missing.frag',
          size: const ui.Size(100, 100),
          pixelRatio: ratio,
        ),
        throwsArgumentError,
      );
    }
  });

  test('离屏输出超限时抛错，包含像素比放大与数值溢出', () async {
    for (final ratio in <double>[1, 2, double.maxFinite]) {
      await expectLater(
        PaperShaderRenderer.render(
          assetKey: 'missing.frag',
          size: const ui.Size(8193, 100),
          pixelRatio: ratio,
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      PaperShaderRenderer.render(
        assetKey: 'missing.frag',
        size: const ui.Size(4096, 100),
        pixelRatio: 3,
      ),
      throwsArgumentError,
    );
  });
}
