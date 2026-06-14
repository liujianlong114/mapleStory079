import 'assets.dart';

/// Login.img 资源路径（与 build_login_scene / extract_wz_login 输出一致）
class LoginUiAssets {
  static const _base = 'images/ui/login';

  /// WZ 提取优先（_normal），build_login_scene 占位在后
  static List<String> buttonStates(String name) => AssetPaths.bundleAll([
        '$_base/${name}_normal.png',
        '$_base/$name.png',
      ]);

  static List<String> buttonOverStates(String name) => AssetPaths.bundleAll([
        '$_base/${name}_over.png',
        '$_base/${name}_mouseOver.png',
      ]);

  static List<String> buttonPressedStates(String name) => AssetPaths.bundleAll([
        '$_base/${name}_pressed.png',
      ]);

  /// 单路径 → [wz_extract _normal, 无后缀占位] 候选
  static List<String> resolve(String path) {
    if (path.contains('_normal.') ||
        path.contains('_over.') ||
        path.contains('_pressed.') ||
        path.contains('_mouseOver.')) {
      return [path];
    }
    if (!path.endsWith('.png')) return [path];
    if (_skipNormalSuffix(path)) return [path];
    final base = path.substring(0, path.length - 4);
    return ['${base}_normal.png', '$base.png'];
  }

  /// Logo / 选角装饰等非 Bt* 按钮资源，WZ 文件名无 _normal 后缀
  static bool _skipNormalSuffix(String path) {
    final name = path.contains('/') ? path.split('/').last : path;
    if (name.startsWith('logo_')) return true;
    if (name.startsWith('newchar_') && !name.contains('btn')) return true;
    if (name.startsWith('worldselect_')) return true;
    if (name.startsWith('charselect_')) return true;
    if (name.startsWith('charinfo_')) return true;
    if (name.startsWith('panel_')) return true;
    if (name.startsWith('pedestal')) return true;
    if (name.startsWith('slot_')) return true;
    if (name.startsWith('title_')) return true;
    return false;
  }

  static const newCharSet = '$_base/newchar_charset.png';
  static const newCharName = '$_base/newchar_charname.png';
  static const scrollOpen = '$_base/newchar_scroll_open.png';
  static const scrollClosed = '$_base/newchar_scroll_closed.png';
  static const dice = '$_base/newchar_dice_0.png';
  static const tabNormal = '$_base/newchar_tab_normal.png';
  static const tabSel = '$_base/newchar_tab_sel.png';
  static const tabDisabled = '$_base/newchar_tab_disabled.png';
  static const statTb = '$_base/newchar_stat_tb.png';
}
