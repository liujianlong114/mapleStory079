/// 079 角色立绘路径（与 extract_avatars.py 输出一致）
class AvatarAssets {
  static const int defaultBeginnerWeapon = 1302000;

  static int defaultTop(int gender) => gender == 1 ? 1041002 : 1040002;
  static int defaultBottom(int gender) => gender == 1 ? 1061002 : 1060002;
  static int defaultShoes() => 1072001;

  static String path({
    required int gender,
    required int face,
    required int hair,
    required int top,
    required int bottom,
    required int shoes,
    int weapon = 0,
  }) {
    return 'characters/avatars/${gender}_${face}_${hair}_${top}_${bottom}_${shoes}_$weapon.png';
  }

  static int defaultFace(int gender) => gender == 1 ? 21002 : 20100;
  static int defaultHair(int gender) => gender == 1 ? 31002 : 30000;

  static int resolveFace(int gender, int face) {
    if (face == 0) return defaultFace(gender);
    // DB 里女号常误存男脸 20100，渲染时回退女脸
    if (gender == 1 && face == 20100) return 21002;
    return face;
  }

  static int resolveHair(int gender, int hair) {
    if (hair == 0) return defaultHair(gender);
    if (gender == 1 && hair == 30000) return 31002;
    return hair;
  }

  /// 导出 PNG 常带新手短剑 1302000，DB 里 weapon=0 时需回退匹配。
  static List<String> candidatePaths({
    required int gender,
    required int face,
    required int hair,
    int top = 0,
    int bottom = 0,
    int shoes = 0,
    int weapon = 0,
  }) {
    final faceId = resolveFace(gender, face);
    final hairId = resolveHair(gender, hair);
    final topId = top != 0 ? top : defaultTop(gender);
    final bottomId = bottom != 0 ? bottom : defaultBottom(gender);
    final shoesId = shoes != 0 ? shoes : defaultShoes();
    final weapons = <int>{
      if (weapon != 0) weapon,
      defaultBeginnerWeapon,
      0,
    };
    final paths = <String>[];
    // 原始 DB 外观（若已导出）
    for (final w in weapons) {
      paths.add(path(
        gender: gender,
        face: face,
        hair: hair,
        top: topId,
        bottom: bottomId,
        shoes: shoesId,
        weapon: w,
      ));
    }
    // 性别修正后的立绘
    if (faceId != face || hairId != hair) {
      for (final w in weapons) {
        paths.add(path(
          gender: gender,
          face: faceId,
          hair: hairId,
          top: topId,
          bottom: bottomId,
          shoes: shoesId,
          weapon: w,
        ));
      }
    }
    return paths;
  }
}
