import 'dart:math' as math;

/// 079 地图 foothold 线段（HeavenClient Foothold + FootholdTree）
class FootholdSegment {
  final int id;
  final int layer;
  final int prev;
  final int next;
  final double x1, y1, x2, y2;

  const FootholdSegment({
    this.id = 0,
    this.layer = 0,
    this.prev = 0,
    this.next = 0,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory FootholdSegment.fromJson(Map<String, dynamic> j) => FootholdSegment(
        id: (j['id'] as num?)?.toInt() ?? 0,
        layer: (j['layer'] as num?)?.toInt() ?? 0,
        prev: (j['prev'] as num?)?.toInt() ?? 0,
        next: (j['next'] as num?)?.toInt() ?? 0,
        x1: (j['x1'] as num).toDouble(),
        y1: (j['y1'] as num).toDouble(),
        x2: (j['x2'] as num).toDouble(),
        y2: (j['y2'] as num).toDouble(),
      );

  double get minX => x1 < x2 ? x1 : x2;
  double get maxX => x1 > x2 ? x1 : x2;
  double get left => minX;
  double get right => maxX;

  bool get isWalkable => (x2 - x1).abs() >= 1;

  bool containsX(double x, {double tolerance = 2}) =>
      x >= minX - tolerance && x <= maxX + tolerance;

  /// 079 Foothold::ground_below
  double groundBelow(double x) {
    final dx = x2 - x1;
    if (dx.abs() < 0.001) return y1;
    final t = ((x - x1) / dx).clamp(0.0, 1.0);
    return y1 + (y2 - y1) * t;
  }
}

/// 079 foothold 碰撞树（对照 HeavenClient FootholdTree）
class MapFootholds {
  final List<FootholdSegment> segments;
  final Map<int, FootholdSegment> byId;
  final Map<int, List<int>> idsByX;
  final double fallbackY;
  final double borderBottom;

  MapFootholds({
    required this.segments,
    required this.byId,
    required this.idsByX,
    required this.fallbackY,
    required this.borderBottom,
  });

  factory MapFootholds.fromJson(List<dynamic>? list, {required double fallbackY}) {
    final segs = <FootholdSegment>[];
    final byId = <int, FootholdSegment>{};
    var autoId = 1000;
    for (final raw in list ?? const []) {
      var seg = FootholdSegment.fromJson(raw as Map<String, dynamic>);
      // JSON 可能缺 id/prev/next（仅导出 x1,y1,x2,y2）——自动补唯一 id，
      // 保证 segmentById 与 getFhidBelow 返回值可用于 groundYOnFh/advanceFhid。
      if (seg.id <= 0) {
        autoId += 1;
        seg = FootholdSegment(
          id: autoId,
          layer: seg.layer,
          prev: seg.prev,
          next: seg.next,
          x1: seg.x1,
          y1: seg.y1,
          x2: seg.x2,
          y2: seg.y2,
        );
      }
      segs.add(seg);
      byId[seg.id] = seg;
    }

    final idsByX = <int, List<int>>{};
    var borderBottom = fallbackY;
    for (final s in segs) {
      if (!s.isWalkable) continue;
      final segBottom = s.y1 > s.y2 ? s.y1 : s.y2;
      if (segBottom > borderBottom) borderBottom = segBottom;
      final start = s.minX.floor();
      final end = s.maxX.ceil();
      for (var xi = start; xi <= end; xi++) {
        idsByX.putIfAbsent(xi, () => []).add(s.id);
      }
    }

    return MapFootholds(
      segments: segs,
      byId: byId,
      idsByX: idsByX,
      fallbackY: fallbackY,
      borderBottom: borderBottom + 100,
    );
  }

  FootholdSegment? segmentById(int id) {
    if (id <= 0) return null;
    return byId[id];
  }

  Iterable<FootholdSegment> _walkableAtX(double x) sync* {
    final xi = x.round();
    final ids = idsByX[xi];
    if (ids != null && byId.isNotEmpty) {
      for (final id in ids) {
        final fh = byId[id];
        if (fh != null && fh.isWalkable && fh.containsX(x)) yield fh;
      }
      return;
    }
    for (final s in segments) {
      if (s.isWalkable && s.containsX(x)) yield s;
    }
  }

  /// 在 x 处，从 y 向上找第一个 Y ≥ y 且 layer 匹配的可站立面。
  ///
  /// preferredLayer 表示玩家所处"逻辑层"（从上次 fhid.layer 继承）。
  /// —— 存在同 layer 段时优先返回，避免多层地图中玩家"飘"到上层平台或嵌入下层。
  int? getFhidBelow(double x, double y, {int? preferredLayer}) {
    var bestId = 0;
    var bestY = borderBottom;
    var fallbackId = 0;
    var fallbackY = borderBottom;
    for (final fh in _walkableAtX(x)) {
      final gy = fh.groundBelow(x);
      if (gy < y) continue;
      if (gy < fallbackY) {
        fallbackY = gy;
        fallbackId = fh.id;
      }
      if (preferredLayer != null && fh.layer != preferredLayer) continue;
      if (gy < bestY) {
        bestY = gy;
        bestId = fh.id;
      }
    }
    if (bestId > 0) return bestId;
    return fallbackId > 0 ? fallbackId : null;
  }

  double? groundYOnFh(int fhid, double x) {
    final fh = segmentById(fhid);
    if (fh == null || !fh.isWalkable || !fh.containsX(x)) return null;
    return fh.groundBelow(x);
  }

  /// 在 x 处所有可站立高度
  List<double> walkableYAt(double x, {double tolerance = 8}) {
    final out = <double>[];
    for (final s in _walkableAtX(x)) {
      out.add(s.groundBelow(x));
    }
    return out;
  }

  double? groundYAt(double x, {double? feetY, double tolerance = 8, int? preferredLayer}) {
    final refY = feetY ?? fallbackY;
    final fhid = getFhidBelow(x, refY - tolerance, preferredLayer: preferredLayer);
    if (fhid != null) return groundYOnFh(fhid, x);
    return null;
  }

  double? landingYAt(double x, double feetY, {double tolerance = 6, int? preferredLayer}) {
    return groundYAt(x, feetY: feetY - tolerance, preferredLayer: preferredLayer);
  }

  double? lowestWalkableYAt(double x) {
    final ys = walkableYAt(x);
    if (ys.isEmpty) return null;
    return ys.reduce(math.max);
  }

  /// 出生/传送：优先 fhid 落点（含 layer 记忆）
  ({int? fhid, double y}) snapSpawn(double x, double hintY, {int? preferredLayer}) {
    var fhid = getFhidBelow(x, hintY, preferredLayer: preferredLayer);
    fhid ??= getFhidBelow(x, hintY - 120);
    if (fhid != null) {
      final gy = groundYOnFh(fhid, x);
      if (gy != null) return (fhid: fhid, y: gy);
    }
    return (fhid: null, y: lowestWalkableYAt(x) ?? hintY);
  }

  /// 给定 fhid，返回其 layer（若未知则 null）
  int? layerOf(int? fhid) {
    if (fhid == null || fhid <= 0) return null;
    return byId[fhid]?.layer;
  }

  /// maplife 的 fh 字段 → 脚点 Y
  double? lifeSpawnY(int fhid, double x, double hintY) {
    final gy = groundYOnFh(fhid, x);
    if (gy != null) return gy;
    return groundYAt(x, feetY: hintY) ?? hintY;
  }

  /// 079 下跳：脚下是否有更低平台（HeavenClient enablejd + groundbelow）
  ///
  /// 关键约束：仅"薄平台"(thin platform, foothold.prev==0 或 foothold.next==0)
  /// 才能向下穿过；完整墙体/地面段(prev!=0 && next!=0)禁止穿下去。
  static const double maxJumpDownGap = 600;

  /// 当前 fhid 对应段是否是薄平台(可向下穿越)
  bool isThinPlatform(int? fhid) {
    if (fhid == null || fhid <= 0) return false;
    final fh = byId[fhid];
    if (fh == null) return false;
    return fh.prev == 0 || fh.next == 0;
  }

  ({bool enabled, double dropY}) jumpDownInfo(int? fhid, double x) {
    if (fhid == null || fhid <= 0) return (enabled: false, dropY: 0);
    final fh = byId[fhid];
    if (fh == null) return (enabled: false, dropY: 0);
    // 薄平台才允许下跳
    if (fh.prev != 0 && fh.next != 0) return (enabled: false, dropY: 0);
    final ground = groundYOnFh(fhid, x);
    if (ground == null) return (enabled: false, dropY: 0);
    final belowId = getFhidBelow(x, ground + 1);
    if (belowId == null || belowId == fhid) {
      // 没有下一层，直接掉落(允许掉到 borderBottom 再重生)
      return (enabled: true, dropY: ground + 1);
    }
    final belowGround = groundYOnFh(belowId, x);
    if (belowGround == null) return (enabled: true, dropY: ground + 1);
    final enabled = (belowGround - ground) < maxJumpDownGap;
    return (enabled: enabled, dropY: ground + 1);
  }

  /// 行走时沿 prev/next 链更新 fhid（HeavenClient update_fh）
  int? advanceFhid({
    required int? current,
    required double x,
    required double y,
    required bool onGround,
  }) {
    if (!onGround) {
      return getFhidBelow(x, y);
    }
    if (current == null || current <= 0) {
      return getFhidBelow(x, y);
    }
    var fhid = current;
    final fh = segmentById(fhid);
    if (fh == null) return getFhidBelow(x, y);

    if (x.floor() > fh.right && fh.next > 0) {
      fhid = fh.next;
    } else if (x.ceil() < fh.left && fh.prev > 0) {
      fhid = fh.prev;
    } else if (!fh.containsX(x, tolerance: 4)) {
      return null;
    }
    return fhid;
  }
}
