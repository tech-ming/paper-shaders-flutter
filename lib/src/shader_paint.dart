import 'dart:ui' as ui;

import 'shader_sizing.dart';
import 'shader_uniforms.dart';

/// 把一次着色器绘制写进 [canvas]
///
/// 屏上组件与离屏渲染（PaperShaderRenderer）共用这一份，两边的 uniform 布局必须一致：
/// 先写 14 个固定头部 float，再写参数类的 uniforms，最后按顺序挂采样贴图。
void paintPaperShader(
  ui.Canvas canvas,
  ui.Size size, {
  required ui.FragmentProgram program,
  required List<ShaderUniform> uniforms,
  required List<ui.Image> imageSamplers,
  required ShaderSizing sizing,
  required double frame,
}) {
  if (size.isEmpty) {
    return;
  }

  final shader = program.fragmentShader();
  var index = 0;
  shader.setFloat(index++, size.width);
  shader.setFloat(index++, size.height);
  shader.setFloat(index++, 1);
  shader.setFloat(index++, frame * 0.001);
  shader.setFloat(index++, sizing.fit.uniformValue);
  shader.setFloat(index++, sizing.scale);
  shader.setFloat(index++, sizing.rotation);
  shader.setFloat(index++, sizing.originX);
  shader.setFloat(index++, sizing.originY);
  shader.setFloat(index++, sizing.offsetX);
  shader.setFloat(index++, sizing.offsetY);
  shader.setFloat(index++, sizing.worldWidth);
  shader.setFloat(index++, sizing.worldHeight);
  shader.setFloat(index++, sizing.imageAspectRatio);

  for (final uniform in uniforms) {
    index = uniform.write(shader, index);
  }
  for (
    var samplerIndex = 0;
    samplerIndex < imageSamplers.length;
    samplerIndex += 1
  ) {
    shader.setImageSampler(samplerIndex, imageSamplers[samplerIndex]);
  }

  // 不显式 dispose：着色器被记录进绘制列表，由 GC 回收（与屏上绘制同一策略）
  canvas.drawRect(ui.Offset.zero & size, ui.Paint()..shader = shader);
}
