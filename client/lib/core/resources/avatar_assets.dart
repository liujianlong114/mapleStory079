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

  /// 解析后的装备 ID（与 extract_player_anim.py 输出键名一致）
  static ({int gender, int face, int hair, int top, int bottom, int shoes, int weapon}) resolveLook({
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
    final weaponId = weapon != 0 ? weapon : defaultBeginnerWeapon;
    return (
      gender: gender,
      face: faceId,
      hair: hairId,
      top: topId,
      bottom: bottomId,
      shoes: shoesId,
      weapon: weaponId,
    );
  }

  /// WZ 动画条带文件名：`{gender}_{face}_{hair}_{top}_{bottom}_{shoes}_{weapon}_{pose}.png`
  static String animStripPath({
    required int gender,
    required int face,
    required int hair,
    int top = 0,
    int bottom = 0,
    int shoes = 0,
    int weapon = 0,
    required String pose, // stand1 | walk1
  }) {
    final look = resolveLook(
      gender: gender,
      face: face,
      hair: hair,
      top: top,
      bottom: bottom,
      shoes: shoes,
      weapon: weapon,
    );
    return 'sprites/player/${look.gender}_${look.face}_${look.hair}_'
        '${look.top}_${look.bottom}_${look.shoes}_${look.weapon}_$pose.png';
  }

  /// 站立/行走动画条带候选（优先 WZ 导出，回退旧占位图）
  static List<String> animStripCandidates({
    required int gender,
    required int face,
    required int hair,
    int top = 0,
    int bottom = 0,
    int shoes = 0,
    int weapon = 0,
    required String pose,
  }) {
    final look = resolveLook(
      gender: gender, face: face, hair: hair,
      top: top, bottom: bottom, shoes: shoes, weapon: weapon,
    );
    final weapons = <int>{look.weapon, defaultBeginnerWeapon, 0};
    final paths = <String>[];
    for (final w in weapons) {
      paths.add(animStripPath(
        gender: gender, face: face, hair: hair,
        top: top, bottom: bottom, shoes: shoes, weapon: w, pose: pose,
      ));
    }
    if (pose == 'stand1') paths.add('sprites/player/stand.png');
    if (pose == 'walk1') paths.add('sprites/player/walk.png');
    return paths;
  }

  /// 站立/行走条带 manifest 路径（不等宽帧切分）
  static List<String> animManifestCandidates({
    required int gender,
    required int face,
    required int hair,
    int top = 0,
    int bottom = 0,
    int shoes = 0,
    int weapon = 0,
    required String pose,
  }) {
    final paths = <String>[];
    for (final p in animStripCandidates(
      gender: gender, face: face, hair: hair,
      top: top, bottom: bottom, shoes: shoes, weapon: weapon, pose: pose,
    )) {
      paths.add(p.replaceAll('.png', '_manifest.json'));
    }
    return paths;
  }
}
