/// 079 完整 CharLook（Phase 1：全部可见装备槽）
class CharLook {
  final int gender;
  final int face;
  final int hair;
  final int skin;
  final int top;
  final int bottom;
  final int longcoat;
  final int shoes;
  final int cap;
  final int cape;
  final int glove;
  final int shield;
  final int weapon;
  final int faceAcc;
  final int eyeAcc;
  final int earring;

  const CharLook({
    this.gender = 0,
    required this.face,
    required this.hair,
    this.skin = 0,
    this.top = 0,
    this.bottom = 0,
    this.longcoat = 0,
    this.shoes = 0,
    this.cap = 0,
    this.cape = 0,
    this.glove = 0,
    this.shield = 0,
    this.weapon = 0,
    this.faceAcc = 0,
    this.eyeAcc = 0,
    this.earring = 0,
  });

  factory CharLook.fromCharacterFields({
    required int gender,
    required int face,
    required int hair,
    int skin = 0,
    int top = 0,
    int bottom = 0,
    int longcoat = 0,
    int shoes = 0,
    int cap = 0,
    int cape = 0,
    int glove = 0,
    int shield = 0,
    int weapon = 0,
    int faceAcc = 0,
    int eyeAcc = 0,
    int earring = 0,
  }) {
    return CharLook(
      gender: gender,
      face: face,
      hair: hair,
      skin: skin,
      top: top,
      bottom: bottom,
      longcoat: longcoat,
      shoes: shoes,
      cap: cap,
      cape: cape,
      glove: glove,
      shield: shield,
      weapon: weapon,
      faceAcc: faceAcc,
      eyeAcc: eyeAcc,
      earring: earring,
    );
  }

  /// 后端 /look/compose.png 查询参数
  Map<String, String> toQueryParams({String pose = 'stand1', int frame = 0}) {
    int q(int v) => v;
    return {
      'gender': '${q(gender)}',
      'face': '${q(face)}',
      'hair': '${q(hair)}',
      'skin': '${q(skin)}',
      'top': '${q(top)}',
      'bottom': '${q(bottom)}',
      'longcoat': '${q(longcoat)}',
      'shoes': '${q(shoes)}',
      'cap': '${q(cap)}',
      'cape': '${q(cape)}',
      'glove': '${q(glove)}',
      'shield': '${q(shield)}',
      'weapon': '${q(weapon)}',
      'face_acc': '${q(faceAcc)}',
      'eye_acc': '${q(eyeAcc)}',
      'earring': '${q(earring)}',
      'pose': pose,
      'frame': '$frame',
    };
  }
}
