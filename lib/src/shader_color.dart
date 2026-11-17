/// 着色器颜色：未预乘的 RGBA 分量，取值 0 到 1。
class ShaderColor {
  /// 由四个分量创建颜色。
  const ShaderColor(this.r, this.g, this.b, this.a);

  /// 红色分量。
  final double r;

  /// 绿色分量。
  final double g;

  /// 蓝色分量。
  final double b;

  /// 透明度。
  final double a;

  /// 解析失败时的回退色（与上游一致：中灰）
  static const fallback = ShaderColor(0.5, 0.5, 0.5, 1);

  /// 未预乘的 RGBA 分量，直接写进着色器 uniform
  ///
  /// 与上游一致：透明度由着色器自己乘（各 `.frag` 里的 `rgb * a`），这里不能再乘一次。
  List<double> get components => <double>[r, g, b, a];

  /// 解析 CSS 颜色字符串，规则与上游 `getShaderColorFromString` 一致
  ///
  /// 支持十六进制（`#rgb` / `#rgba` / `#rrggbb` / `#rrggbbaa`）、`rgb()` / `rgba()`、
  /// `hsl()` / `hsla()`；无法识别或格式非法时返回 [fallback]。
  static ShaderColor parse(String value) {
    final input = value.trim();
    if (input.startsWith('#')) {
      return _fromHex(input.substring(1));
    }
    if (input.startsWith('rgb')) {
      return _fromRgb(input);
    }
    if (input.startsWith('hsl')) {
      return _fromHsl(input);
    }
    return fallback;
  }

  static final _hex8 = RegExp(r'^[0-9a-fA-F]{8}$');
  static final _rgb = RegExp(
    r'^rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([0-9.]+))?\s*\)$',
    caseSensitive: false,
  );
  static final _hsl = RegExp(
    r'^hsla?\s*\(\s*(\d+)\s*,\s*(\d+)%\s*,\s*(\d+)%\s*(?:,\s*([0-9.]+))?\s*\)$',
    caseSensitive: false,
  );

  static ShaderColor _fromHex(String digits) {
    var hex = digits;
    // 简写（#rgb / #rgba）逐位翻倍，六位补不透明
    if (hex.length == 3 || hex.length == 4) {
      hex = hex.split('').map((char) => '$char$char').join();
    }
    if (hex.length == 6) {
      hex = '${hex}ff';
    }
    if (!_hex8.hasMatch(hex)) {
      return fallback;
    }
    double channel(int start) =>
        int.parse(hex.substring(start, start + 2), radix: 16) / 255;
    return ShaderColor(channel(0), channel(2), channel(4), channel(6));
  }

  static ShaderColor _fromRgb(String input) {
    final match = _rgb.firstMatch(input);
    if (match == null) {
      return fallback;
    }
    final alpha = _alpha(match.group(4));
    if (alpha == null) {
      return fallback;
    }
    // 用 double 解析：位数再多也不会溢出抛错
    return ShaderColor(
      _unit(double.parse(match.group(1)!) / 255),
      _unit(double.parse(match.group(2)!) / 255),
      _unit(double.parse(match.group(3)!) / 255),
      alpha,
    );
  }

  static ShaderColor _fromHsl(String input) {
    final match = _hsl.firstMatch(input);
    if (match == null) {
      return fallback;
    }
    final alpha = _alpha(match.group(4));
    if (alpha == null) {
      return fallback;
    }
    final h = double.parse(match.group(1)!) / 360;
    final s = double.parse(match.group(2)!) / 100;
    final l = double.parse(match.group(3)!) / 100;
    if (s == 0) {
      // 无彩色
      return ShaderColor(_unit(l), _unit(l), _unit(l), alpha);
    }
    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;
    return ShaderColor(
      _unit(_hueToRgb(p, q, h + 1 / 3)),
      _unit(_hueToRgb(p, q, h)),
      _unit(_hueToRgb(p, q, h - 1 / 3)),
      alpha,
    );
  }

  static double _hueToRgb(double p, double q, double hue) {
    var t = hue;
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  }

  /// 透明度分量：缺省为 1；写了但不是合法数字返回 null
  static double? _alpha(String? raw) {
    if (raw == null) {
      return 1;
    }
    final value = double.tryParse(raw);
    return value == null ? null : _unit(value);
  }

  static double _unit(double value) => value.clamp(0, 1).toDouble();
}
