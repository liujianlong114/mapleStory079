import 'dart:math' as math;

/// 079 地图 foothold 线段（从 Map.wz 导出）
class FootholdSegment {
  final double x1, y1, x2, y2;

  const FootholdSegment({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory FootholdSegment.fromJson(Map<String, dynamic> j) => FootholdSegment(
        x1: (j['x1'] as num).toDouble(),
        y1: (j['y1'] as num).toDouble(),
        x2: (j['x2'] as num).toDouble(),
        y2: (j['y2'] as num).toDouble(),
      );

  double get minX => x1 < x2 ? x1 : x2;
  double get maxX => x1 > x2 ? x1 : x2;

  /// 可站立的线段（排除竖墙）
  bool get isWalkable => (x2 - x1).abs() >= 1;
}

/// 079 foothold 碰撞：Y 轴向下为正，取当前脚下最近的可站立面
class MapFootholds {
  final List<FootholdSegment> segments;
  final double fallbackY;

  MapFootholds({required this.segments, required this.fallbackY});

  factory MapFootholds.fromJson(List<dynamic>? list, {required double fallbackY}) {
    final segs = list
            ?.map((e) => FootholdSegment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return MapFootholds(segments: segs, fallbackY: fallbackY);
  }

  /// 在 x 处所有可站立高度
  List<double> walkableYAt(double x, {double tolerance = 8}) {
    final out = <double>[];
    for (final s in segments) {
      if (!s.isWalkable) continue;
      if (x < s.minX - tolerance || x > s.maxX + tolerance) continue;
      final dx = s.x2 - s.x1;
      final t = ((x - s.x1) / dx).clamp(0.0, 1.0);
      out.add(s.y1 + (s.y2 - s.y1) * t);
    }
    return out;
  }

  /// 求站立 Y。feetY 为当前脚点；无 feetY 时取最低地面（最大 Y）
  double groundYAt(double x, {double? feetY, double tolerance = 12}) {
    final ys = walkableYAt(x);
    if (ys.isEmpty) return fallbackY;
    if (feetY == null) return ys.reduce(math.max);
    final below = ys.where((y) => y <= feetY + tolerance).toList();
    if (below.isEmpty) return ys.reduce(math.min);
    return below.reduce(math.max);
  }

  /// 空中落下时检测着陆面
  double? landingYAt(double x, double feetY, {double tolerance = 6}) {
    final ys = walkableYAt(x);
    if (ys.isEmpty) return null;
    final below = ys.where((y) => y >= feetY - tolerance).toList();
    if (below.isEmpty) return null;
    return below.reduce(math.min);
  }
}
