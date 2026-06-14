/// Login.img 资源路径（与 build_login_scene / extract_wz_login 输出一致）
class LoginUiAssets {
  static const _base = 'images/ui/login';

  /// procedural: btn_yes.png；WZ 提取: btn_yes_normal.png
  static List<String> buttonStates(String name) => [
        '$_base/$name.png',
        '$_base/${name}_normal.png',
      ];

  static List<String> buttonOverStates(String name) => [
        '$_base/${name}_over.png',
        '$_base/${name}_mouseOver.png',
      ];

  static List<String> buttonPressedStates(String name) => [
        '$_base/${name}_pressed.png',
      ];

  /// 单路径 → [procedural, wz_extract] 候选
  static List<String> resolve(String path) {
    if (path.contains('_normal.') || path.contains('_over.') || path.contains('_pressed.')) {
      return [path];
    }
    if (!path.endsWith('.png')) return [path];
    final base = path.substring(0, path.length - 4);
    return ['$base.png', '${base}_normal.png'];
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
