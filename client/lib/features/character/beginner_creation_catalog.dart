/// ms079 CharLoginHandler.CreateChar + Login.img/NewChar/avatarSel 0~5
class BeginnerCreationCatalog {
  static const maleFaces = [20100, 20401, 20402];
  static const maleHairs = [30030, 30027, 30000];
  static const maleTops = [1040002, 1040006, 1040010, 1042167];
  static const maleBottoms = [1060002, 1060006, 1062115];

  static const femaleFaces = [21002, 21700, 21201];
  static const femaleHairs = [31002, 31047, 31057];
  static const femaleTops = [1041002, 1041006, 1041010, 1041011, 1042167];
  static const femaleBottoms = [1061002, 1061008, 1062115];

  static const shoes = [1072001, 1072005, 1072037, 1072038, 1072383];
  static const weapons = [1302000, 1322005, 1312004, 1442079];

  static const tabLabels = ['脸型', '发型', '上衣', '裤子', '鞋子', '武器'];

  /// ms079 JobType: 0=骑士团 1=冒险家 2=战神
  static const jobTypeAdventurer = 1;
  static const jobTypeKnight = 0;
  static const jobTypeAran = 2;

  static List<int> faces(int gender) => gender == 0 ? maleFaces : femaleFaces;
  static List<int> hairs(int gender) => gender == 0 ? maleHairs : femaleHairs;
  static List<int> tops(int gender) => gender == 0 ? maleTops : femaleTops;
  static List<int> bottoms(int gender) =>
      gender == 0 ? maleBottoms : femaleBottoms;

  static BeginnerLook defaults(int gender) {
    if (gender == 1) {
      return BeginnerLook(
        gender: 1,
        face: femaleFaces.first,
        hair: femaleHairs.first,
        top: femaleTops.first,
        bottom: femaleBottoms.first,
        shoes: shoes.first,
        weapon: weapons.first,
      );
    }
    return BeginnerLook(
      gender: 0,
      face: maleFaces.first,
      hair: maleHairs.first,
      top: maleTops.first,
      bottom: maleBottoms.first,
      shoes: shoes.first,
      weapon: weapons.first,
    );
  }

  static BeginnerLook random(int gender) {
    final g = gender == 1 ? 1 : 0;
    final now = DateTime.now().microsecondsSinceEpoch;
    final f = faces(g);
    final h = hairs(g);
    final t = tops(g);
    final b = bottoms(g);
    return BeginnerLook(
      gender: g,
      face: f[now % f.length],
      hair: h[(now ~/ 3) % h.length],
      top: t[(now ~/ 5) % t.length],
      bottom: b[(now ~/ 7) % b.length],
      shoes: shoes[(now ~/ 11) % shoes.length],
      weapon: weapons[(now ~/ 13) % weapons.length],
    );
  }

  static List<int> optionsForTab(int gender, int tab) {
    switch (tab) {
      case 0:
        return faces(gender);
      case 1:
        return hairs(gender);
      case 2:
        return tops(gender);
      case 3:
        return bottoms(gender);
      case 4:
        return shoes;
      case 5:
        return weapons;
      default:
        return [];
    }
  }

  static int valueForTab(BeginnerLook look, int tab) {
    switch (tab) {
      case 0:
        return look.face;
      case 1:
        return look.hair;
      case 2:
        return look.top;
      case 3:
        return look.bottom;
      case 4:
        return look.shoes;
      case 5:
        return look.weapon;
      default:
        return 0;
    }
  }

  static BeginnerLook withTabValue(BeginnerLook look, int tab, int value) {
    switch (tab) {
      case 0:
        return look.copyWith(face: value);
      case 1:
        return look.copyWith(hair: value);
      case 2:
        return look.copyWith(top: value);
      case 3:
        return look.copyWith(bottom: value);
      case 4:
        return look.copyWith(shoes: value);
      case 5:
        return look.copyWith(weapon: value);
      default:
        return look;
    }
  }

  static String labelForTabValue(int tab, int value) => '#$value';
}

class BeginnerLook {
  final int gender;
  final int face;
  final int hair;
  final int top;
  final int bottom;
  final int shoes;
  final int weapon;
  final int jobType;
  final String name;

  const BeginnerLook({
    this.gender = 0,
    required this.face,
    required this.hair,
    required this.top,
    required this.bottom,
    required this.shoes,
    required this.weapon,
    this.jobType = BeginnerCreationCatalog.jobTypeAdventurer,
    this.name = '',
  });

  int get hairColor => 0;
  int get skin => 0;

  BeginnerLook copyWith({
    int? gender,
    int? face,
    int? hair,
    int? top,
    int? bottom,
    int? shoes,
    int? weapon,
    int? jobType,
    String? name,
  }) {
    return BeginnerLook(
      gender: gender ?? this.gender,
      face: face ?? this.face,
      hair: hair ?? this.hair,
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      shoes: shoes ?? this.shoes,
      weapon: weapon ?? this.weapon,
      jobType: jobType ?? this.jobType,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {
        'jobType': jobType,
        'face': face,
        'hair': hair,
        'hairColor': 0,
        'skin': 0,
        'top': top,
        'bottom': bottom,
        'shoes': shoes,
        'weapon': weapon,
      };
}
