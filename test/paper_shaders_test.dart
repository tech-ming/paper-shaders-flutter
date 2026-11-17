import 'package:flutter_test/flutter_test.dart';
import 'package:paper_shaders/paper_shaders.dart';

void main() {
  test('parses hex colors', () {
    final color = ShaderColor.parse('#336699cc');
    expect(color.r, closeTo(0.2, 0.001));
    expect(color.g, closeTo(0.4, 0.001));
    expect(color.b, closeTo(0.6, 0.001));
    expect(color.a, closeTo(0.8, 0.001));
  });

  test('parses shorthand hex, rgb and hsl colors', () {
    final shorthand = ShaderColor.parse('#369');
    expect(shorthand.r, closeTo(0.2, 0.001));
    expect(shorthand.a, closeTo(1, 0.001));

    final rgb = ShaderColor.parse('rgb(51, 102, 153)');
    expect(rgb.b, closeTo(0.6, 0.001));
    expect(rgb.a, closeTo(1, 0.001));

    final rgba = ShaderColor.parse('rgba(255, 0, 0, 0.25)');
    expect(rgba.r, closeTo(1, 0.001));
    expect(rgba.a, closeTo(0.25, 0.001));

    final hsl = ShaderColor.parse('hsl(210, 50%, 40%)');
    expect(hsl.r, closeTo(0.2, 0.01));
    expect(hsl.g, closeTo(0.4, 0.01));
    expect(hsl.b, closeTo(0.6, 0.01));
  });

  test('falls back to gray on unsupported or malformed colors', () {
    for (final value in <String>['', 'red', '#12', '#gggggg', 'rgb(1,2)']) {
      expect(ShaderColor.parse(value).r, closeTo(0.5, 0.001), reason: value);
      expect(ShaderColor.parse(value).a, closeTo(1, 0.001), reason: value);
    }
  });

  test('color uniforms carry straight (non-premultiplied) components', () {
    // 透明度由着色器自己乘，这里预乘会乘两次
    final single = Float4Uniform.color('#ff000080');
    expect(single.values[0], closeTo(1, 0.001));
    expect(single.values[3], closeTo(128 / 255, 0.001));

    final array = Float4ArrayUniform.colors(const <String>[
      '#00ff0040',
    ], capacity: 2);
    expect(array.values.single[1], closeTo(1, 0.001));
    expect(array.values.single[3], closeTo(64 / 255, 0.001));
  });

  test('simplex-noise exposes upstream presets', () {
    expect(SimplexNoiseShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Spots',
      'First contact',
      'Bubblegum',
    ]);
  });

  test('dot-orbit exposes upstream presets and noise sampler', () {
    expect(DotOrbitShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Bubbles',
      'Shine',
      'Hallucinatory',
    ]);
    expect(
      DotOrbitShader.imageSamplers.single,
      ShaderImageSampler.noiseTexture,
    );
  });

  test('mesh-gradient exposes upstream presets', () {
    expect(MeshGradientShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Ink',
      'Purple',
      'Beach',
    ]);
  });

  test('waves exposes upstream presets', () {
    expect(WavesShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Groovy',
      'Tangled up',
      'Ride the wave',
    ]);
  });

  test('pulsing-border exposes upstream presets and noise sampler', () {
    expect(PulsingBorderShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Circle',
      'Northern lights',
      'Solid line',
    ]);
    expect(PulsingBorderShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.noiseTexture,
    ]);
  });

  test('halftone-cmyk exposes upstream presets and image samplers', () {
    expect(HalftoneCmykShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Drops',
      'Newspaper',
      'Vintage',
    ]);
    expect(HalftoneCmykShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.transparent,
      ShaderImageSampler.noiseTexture,
    ]);
  });

  test('paper-texture exposes upstream presets and image samplers', () {
    expect(PaperTextureShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Spread',
      'Creased',
      'Flat',
    ]);
    expect(PaperTextureShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.transparent,
      ShaderImageSampler.noiseTexture,
    ]);
  });

  test('lens-distortion exposes upstream presets and image sampler', () {
    expect(LensDistortionShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Fisheye',
      'Duotone',
      'Smoke',
    ]);
    expect(LensDistortionShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.transparent,
    ]);
  });

  test('grain-gradient exposes upstream presets and noise sampler', () {
    expect(GrainGradientShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Wave',
      'Dots',
      'Truchet',
      'Ripple',
      'Blob',
    ]);
    expect(GrainGradientShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.noiseTexture,
    ]);
  });

  test('gem-smoke exposes upstream presets and image sampler', () {
    expect(GemSmokeShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Fire',
      'Fluorescent',
      'Infrared',
    ]);
    expect(GemSmokeShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.gemSmokeImage,
    ]);
  });

  test('halftone-dots exposes upstream presets and image sampler', () {
    expect(HalftoneDotsShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'LED screen',
      'Mosaic',
      'Round and square',
    ]);
    expect(HalftoneDotsShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.transparent,
    ]);
  });

  test('heatmap exposes upstream presets and image sampler', () {
    expect(HeatmapShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Sepia',
    ]);
    expect(HeatmapShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.heatmapImage,
    ]);
  });

  test('image-dithering exposes upstream presets and image sampler', () {
    expect(ImageDitheringShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Noise',
      'Retro',
      'Natural',
    ]);
    expect(ImageDitheringShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.transparent,
    ]);
  });

  test('liquid-metal exposes upstream presets and image sampler', () {
    expect(LiquidMetalShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Noir',
      'Backdrop',
      'Stripes',
    ]);
    expect(LiquidMetalShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.liquidMetalImage,
    ]);
  });

  test('color-panels exposes upstream presets', () {
    expect(ColorPanelsShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Glass',
      'Gradient',
      'Opening',
    ]);
  });

  test('dithering exposes upstream presets', () {
    expect(DitheringShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Warp',
      'Sine Wave',
      'Ripple',
      'Bugs',
      'Swirl',
    ]);
  });

  test('dot-grid exposes upstream presets', () {
    expect(DotGridShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Triangles',
      'Tree line',
      'Wallpaper',
    ]);
  });

  test('god-rays exposes upstream presets and noise sampler', () {
    expect(GodRaysShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Warp',
      'Linear',
      'Ether',
    ]);
    expect(GodRaysShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.noiseTexture,
    ]);
  });

  test('metaballs exposes upstream presets and noise sampler', () {
    expect(MetaballsShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Ink Drops',
      'Solar',
      'Background',
    ]);
    expect(MetaballsShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.noiseTexture,
    ]);
  });

  test('neuro-noise exposes upstream presets', () {
    expect(NeuroNoiseShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Sensation',
      'Bloodstream',
      'Ghost',
    ]);
  });

  test('perlin-noise exposes upstream presets', () {
    expect(PerlinNoiseShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Nintendo Water',
      'Moss',
      'Worms',
    ]);
  });

  test('smoke-ring exposes upstream presets and noise sampler', () {
    expect(SmokeRingShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Line',
      'Solar',
      'Cloud',
    ]);
    expect(SmokeRingShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.noiseTexture,
    ]);
  });

  test('spiral exposes upstream presets', () {
    expect(SpiralShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Jungle',
      'Droplet',
      'Swirl',
    ]);
  });

  test('static-mesh-gradient exposes upstream presets', () {
    expect(
      StaticMeshGradientShader.presets.map((preset) => preset.name),
      <String>['Default', '1960s', 'Sunset', 'Sea'],
    );
  });

  test('static-radial-gradient exposes upstream presets', () {
    expect(
      StaticRadialGradientShader.presets.map((preset) => preset.name),
      <String>['Default', 'Lo-Fi', 'Cross Section', 'Radial'],
    );
  });

  test('swirl exposes upstream presets', () {
    expect(SwirlShader.presets.map((preset) => preset.name), <String>[
      'Default',
      '007',
      'Opening',
      'Candy',
    ]);
  });

  test('voronoi exposes upstream presets and noise sampler', () {
    expect(VoronoiShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Lights',
      'Cells',
      'Bubbles',
    ]);
    expect(VoronoiShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.noiseTexture,
    ]);
  });

  test('warp exposes upstream presets and noise sampler', () {
    expect(WarpShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Cauldron Pot',
      'Live Ink',
      'Kelp',
      'Nectar',
      'Passion',
    ]);
    expect(WarpShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.noiseTexture,
    ]);
  });

  test('water exposes upstream presets and image sampler', () {
    expect(WaterShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Slow-mo',
      'Abstract',
      'Streaming',
    ]);
    expect(WaterShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.transparent,
    ]);
  });

  test('fluted-glass exposes upstream presets and image sampler', () {
    expect(FlutedGlassShader.presets.map((preset) => preset.name), <String>[
      'Default',
      'Abstract',
      'Waves',
      'Folds',
    ]);
    expect(FlutedGlassShader.imageSamplers, <ShaderImageSampler>[
      ShaderImageSampler.transparent,
    ]);
  });

  test('catalog contains ported shaders', () {
    expect(ShaderCatalog.all.map((entry) => entry.name), <String>[
      'simplex-noise',
      'dot-orbit',
      'mesh-gradient',
      'waves',
      'pulsing-border',
      'halftone-cmyk',
      'paper-texture',
      'grain-gradient',
      'gem-smoke',
      'halftone-dots',
      'heatmap',
      'image-dithering',
      'liquid-metal',
      'color-panels',
      'dithering',
      'dot-grid',
      'god-rays',
      'metaballs',
      'neuro-noise',
      'perlin-noise',
      'smoke-ring',
      'spiral',
      'static-mesh-gradient',
      'static-radial-gradient',
      'swirl',
      'voronoi',
      'warp',
      'water',
      'fluted-glass',
      'lens-distortion',
    ]);
    expect(
      ShaderCatalog.all[1].imageSamplers.single.assetKey,
      contains('noise.png'),
    );
  });

  test('catalog classifies shaders without time dependencies as static', () {
    expect(
      ShaderCatalog.all
          .where((entry) => !entry.isAnimated)
          .map((entry) => entry.name)
          .toSet(),
      <String>{
        'dot-grid',
        'fluted-glass',
        'halftone-cmyk',
        'halftone-dots',
        'image-dithering',
        'lens-distortion',
        'paper-texture',
        'static-mesh-gradient',
        'static-radial-gradient',
        'waves',
      },
    );
  });
}
