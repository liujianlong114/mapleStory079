import 'package:flutter/material.dart';

import '../../core/resources/avatar_assets.dart';
import '../../models/char_look.dart';
import 'look_compose_image.dart';
import 'wz_asset_image.dart';

/// 079 选角/创角立绘 — Phase 1 优先后端 CharLook 实时合成（全装备槽）
class MapleAvatarView extends StatelessWidget {
  final int gender;
  final int face;
  final int hair;
  final int top;
  final int bottom;
  final int shoes;
  final int weapon;
  final int cap;
  final int cape;
  final int glove;
  final int shield;
  final int faceAcc;
  final int eyeAcc;
  final int earring;
  final int longcoat;
  final double height;

  const MapleAvatarView({
    super.key,
    required this.gender,
    required this.face,
    required this.hair,
    this.top = 0,
    this.bottom = 0,
    this.shoes = 0,
    this.weapon = 0,
    this.cap = 0,
    this.cape = 0,
    this.glove = 0,
    this.shield = 0,
    this.faceAcc = 0,
    this.eyeAcc = 0,
    this.earring = 0,
    this.longcoat = 0,
    this.height = 130,
  });

  CharLook get _look {
    final faceId = AvatarAssets.resolveFace(gender, face);
    final hairId = AvatarAssets.resolveHair(gender, hair);
    return CharLook.fromCharacterFields(
      gender: gender,
      face: faceId,
      hair: hairId,
      top: top != 0 ? top : AvatarAssets.defaultTop(gender),
      bottom: bottom != 0 ? bottom : AvatarAssets.defaultBottom(gender),
      shoes: shoes != 0 ? shoes : AvatarAssets.defaultShoes(),
      weapon: weapon != 0 ? weapon : AvatarAssets.defaultBeginnerWeapon,
      cap: cap,
      cape: cape,
      glove: glove,
      shield: shield,
      faceAcc: faceAcc,
      eyeAcc: eyeAcc,
      earring: earring,
      longcoat: longcoat,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * 0.85,
      child: ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LookComposeImage(
            look: _look,
            height: height,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// API 不可用时的静态立绘回退（创角预览备用）
class MapleAvatarFallback extends StatelessWidget {
  final int gender;
  final int face;
  final int hair;
  final int top;
  final int bottom;
  final int shoes;
  final int weapon;
  final double height;

  const MapleAvatarFallback({
    super.key,
    required this.gender,
    required this.face,
    required this.hair,
    this.top = 0,
    this.bottom = 0,
    this.shoes = 0,
    this.weapon = 0,
    this.height = 130,
  });

  @override
  Widget build(BuildContext context) {
    final paths = AvatarAssets.candidatePaths(
      gender: gender,
      face: face,
      hair: hair,
      top: top,
      bottom: bottom,
      shoes: shoes,
      weapon: weapon,
    );
    return SizedBox(
      height: height,
      child: WzAssetImage(
        candidates: paths,
        fit: BoxFit.contain,
        fallback: (_) => const Icon(Icons.person_outline, color: Color(0x66FFFFFF)),
      ),
    );
  }
}
