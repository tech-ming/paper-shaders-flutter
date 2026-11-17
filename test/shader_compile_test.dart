import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_shaders/paper_shaders.dart';

/// 验证目录资产编译与组件切换时的程序一致性。
void main() {
  testWidgets('catalog shaders compile and declare loadable samplers', (
    tester,
  ) async {
    for (final entry in ShaderCatalog.all) {
      await ui.FragmentProgram.fromAsset(_localAssetKey(entry.assetKey));

      for (final sampler in entry.imageSamplers) {
        // 内置透明贴图与动态贴图不是资源文件
        if (sampler.isTransparent || sampler.isDynamic) continue;
        final bytes = await rootBundle.load(_localAssetKey(sampler.assetKey));
        expect(bytes.lengthInBytes, greaterThan(0));
      }
    }
  });

  testWidgets('切换效果不会用旧程序绘制新参数', (tester) async {
    final firstAsset = _localAssetKey(SimplexNoiseShader.assetKey);
    final nextAsset = _localAssetKey(MeshGradientShader.assetKey);
    await tester.runAsync(() async {
      await PaperShaderCache.program(firstAsset);
      await PaperShaderCache.program(nextAsset);
    });

    await tester.pumpWidget(
      _shaderFrame(firstAsset, const SimplexNoiseParams().uniforms),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 新效果需要更多参数，旧程序接收它们会越界。
    await tester.pumpWidget(
      _shaderFrame(nextAsset, const MeshGradientParams().uniforms),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

/// 用有限尺寸与静态时间挂载同一个组件，保留状态以验证效果切换。
Widget _shaderFrame(String assetKey, List<ShaderUniform> uniforms) {
  return SizedBox(
    width: 100,
    height: 100,
    child: PaperShader(
      assetKey: assetKey,
      uniforms: uniforms,
      speed: 0,
      isAnimated: false,
    ),
  );
}

/// 包内测试使用本地资产路径。
String _localAssetKey(String assetKey) {
  return assetKey.replaceFirst('packages/paper_shaders/', '');
}
