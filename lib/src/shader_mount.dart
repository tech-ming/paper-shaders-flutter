import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'shader_cache.dart';
import 'shader_paint.dart';
import 'shader_sampler.dart';
import 'shader_sizing.dart';
import 'shader_uniforms.dart';

/// 加载共享程序与采样贴图，并按参数绘制着色器。
class PaperShader extends StatefulWidget {
  /// 创建着色器组件。
  const PaperShader({
    required this.assetKey,
    required this.uniforms,
    this.imageSamplers = const <ShaderImageSampler>[],
    this.sizing = const ShaderSizing.pattern(),
    this.speed = 1,
    this.frame = 0,
    this.isAnimated = true,
    super.key,
  });

  /// 着色器程序的资产路径。
  final String assetKey;

  /// 按 GLSL 声明顺序排列的参数。
  final List<ShaderUniform> uniforms;

  /// 按 GLSL 声明顺序排列的采样贴图。
  final List<ShaderImageSampler> imageSamplers;

  /// 画布与图片的映射设置。
  final ShaderSizing sizing;

  /// 动画速度；为零时固定在当前帧。
  final double speed;

  /// 初始时间，单位为毫秒。
  final double frame;

  /// 输出是否随时间变化；为假时关闭动画循环。
  final bool isAnimated;

  @override
  /// 创建绘制状态。
  State<PaperShader> createState() => _PaperShaderState();
}

/// 管理异步资源加载与动画时间。
class _PaperShaderState extends State<PaperShader>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  List<ui.Image>? _imageSamplers;
  late Ticker _ticker;
  Duration? _lastElapsed;
  late double _frame;
  var _programLoadId = 0;
  var _imageLoadId = 0;

  @override
  /// 初始化时间、资源与动画循环。
  void initState() {
    super.initState();
    _frame = widget.frame;
    _ticker = createTicker(_tick);
    _loadProgram();
    if (widget.imageSamplers.isEmpty) {
      _imageSamplers = const <ui.Image>[];
    } else {
      _loadImageSamplers();
    }
    if (_animationActive) {
      _ticker.start();
    }
  }

  @override
  /// 更新资源来源与动画设置。
  void didUpdateWidget(PaperShader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetKey != widget.assetKey) {
      _loadProgram();
    }
    if (_imageSamplerSourcesChanged(
      oldWidget.imageSamplers,
      widget.imageSamplers,
    )) {
      _loadImageSamplers();
    }
    if (widget.isAnimated &&
        (oldWidget.frame != widget.frame || !oldWidget.isAnimated)) {
      _frame = widget.frame;
      _lastElapsed = null;
    }
    if (oldWidget.speed != widget.speed ||
        oldWidget.isAnimated != widget.isAnimated) {
      if (!_animationActive) {
        _ticker.stop();
      } else if (!_ticker.isActive) {
        _lastElapsed = null;
        _ticker.start();
      }
    }
  }

  @override
  /// 停止动画，共享贴图仍由缓存或调用方持有。
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// 切换程序时清空旧引用，避免用旧程序绘制新参数。
  Future<void> _loadProgram() async {
    final loadId = ++_programLoadId;
    _program = null;
    try {
      final program = await PaperShaderCache.program(widget.assetKey);
      if (!mounted || loadId != _programLoadId) {
        return;
      }
      setState(() {
        _program = program;
      });
    } catch (error, stackTrace) {
      if (!mounted || loadId != _programLoadId) {
        return;
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'paper_shaders',
          context: ErrorDescription(
            '加载着色器程序「${widget.assetKey}」时',
          ),
        ),
      );
      setState(() {
        _program = null;
      });
    }
  }

  /// 等待当前来源的全部贴图就绪，并忽略过期请求。
  Future<void> _loadImageSamplers() async {
    final loadId = ++_imageLoadId;
    _imageSamplers = null;
    final samplers = widget.imageSamplers;
    if (samplers.isEmpty) {
      _replaceImages(const <ui.Image>[]);
      return;
    }

    try {
      final images = await PaperShaderCache.images(samplers);
      if (!mounted || loadId != _imageLoadId) {
        return;
      }
      _replaceImages(images);
    } catch (error, stackTrace) {
      if (!mounted || loadId != _imageLoadId) {
        return;
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'paper_shaders',
          context: ErrorDescription('加载着色器采样贴图时'),
        ),
      );
      _replaceImages(null);
    }
  }

  /// 更换贴图引用，所有权仍归缓存或调用方。
  void _replaceImages(List<ui.Image>? images) {
    setState(() {
      _imageSamplers = images;
    });
  }

  /// 采样器来源是否变了：资产贴图按资源键，动态贴图按引用（调用方换图后重新取值）
  bool _imageSamplerSourcesChanged(
    List<ShaderImageSampler> previous,
    List<ShaderImageSampler> next,
  ) {
    if (previous.length != next.length) {
      return true;
    }
    for (var i = 0; i < previous.length; i += 1) {
      if (!previous[i].sameSource(next[i])) {
        return true;
      }
    }
    return false;
  }

  /// 按实际间隔推进动画时间。
  void _tick(Duration elapsed) {
    final last = _lastElapsed ?? elapsed;
    _lastElapsed = elapsed;
    if (!_animationActive) {
      return;
    }
    final deltaMs = (elapsed - last).inMicroseconds / 1000;
    setState(() {
      _frame += deltaMs * widget.speed;
    });
  }

  /// 仅时间相关且速度非零时启用动画。
  bool get _animationActive => widget.isAnimated && widget.speed != 0;

  @override
  /// 资源齐备后绘制，加载期间输出透明。
  Widget build(BuildContext context) {
    final program = _program;
    final imageSamplers = _imageSamplers;
    if (program == null || imageSamplers == null) {
      return const SizedBox.expand();
    }
    return CustomPaint(
      painter: _PaperShaderPainter(
        program: program,
        uniforms: widget.uniforms,
        imageSamplers: imageSamplers,
        sizing: widget.sizing,
        frame: _frame,
      ),
      size: Size.infinite,
    );
  }
}

/// 将已加载的资源交给共用绘制函数。
class _PaperShaderPainter extends CustomPainter {
  /// 创建当前帧的绘制器。
  const _PaperShaderPainter({
    required this.program,
    required this.uniforms,
    required this.imageSamplers,
    required this.sizing,
    required this.frame,
  });

  final ui.FragmentProgram program;

  /// 当前效果参数。
  final List<ShaderUniform> uniforms;
  final List<ui.Image> imageSamplers;

  /// 画布与图片的映射设置。
  final ShaderSizing sizing;

  /// 当前时间，单位为毫秒。
  final double frame;

  @override
  /// 绘制当前帧。
  void paint(Canvas canvas, Size size) {
    paintPaperShader(
      canvas,
      size,
      program: program,
      uniforms: uniforms,
      imageSamplers: imageSamplers,
      sizing: sizing,
      frame: frame,
    );
  }

  @override
  /// 视觉输入变化时重新绘制。
  bool shouldRepaint(covariant _PaperShaderPainter oldDelegate) {
    return oldDelegate.program != program ||
        oldDelegate.frame != frame ||
        oldDelegate.uniforms != uniforms ||
        oldDelegate.imageSamplers != imageSamplers ||
        oldDelegate.sizing != sizing;
  }
}
