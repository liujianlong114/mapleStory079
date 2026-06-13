import 'package:shared_preferences/shared_preferences.dart';

/// 本地持久化存储服务
///
/// 封装 shared_preferences，提供统一的键值读写能力，
/// 管理用户 token、角色 ID、主题偏好等应用级配置。
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _kToken = 'auth_token';
  static const String _kCharacterId = 'current_character_id';
  static const String _kTheme = 'app_theme';
  static const String _kBrightness = 'app_brightness'; // 'light' | 'dark'

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ================== Token ==================

  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_kToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_kToken);
  }

  Future<void> removeToken() async {
    final prefs = await _prefs;
    await prefs.remove(_kToken);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ================== Character ID ==================

  Future<void> saveCharacterId(int id) async {
    final prefs = await _prefs;
    await prefs.setInt(_kCharacterId, id);
  }

  Future<int?> getCharacterId() async {
    final prefs = await _prefs;
    return prefs.getInt(_kCharacterId);
  }

  Future<void> removeCharacterId() async {
    final prefs = await _prefs;
    await prefs.remove(_kCharacterId);
  }

  // ================== Theme ==================

  /// 保存主题名称，例如 'adventure' / 'ocean' 等
  Future<void> saveTheme(String themeName) async {
    final prefs = await _prefs;
    await prefs.setString(_kTheme, themeName);
  }

  Future<String?> getTheme() async {
    final prefs = await _prefs;
    return prefs.getString(_kTheme);
  }

  /// 保存亮度模式：'light' | 'dark'
  Future<void> saveBrightness(String brightness) async {
    final prefs = await _prefs;
    await prefs.setString(_kBrightness, brightness);
  }

  Future<String> getBrightness() async {
    final prefs = await _prefs;
    return prefs.getString(_kBrightness) ?? 'dark';
  }

  // ================== Generic ==================

  Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await _prefs;
    await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _prefs;
    return prefs.getInt(key);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _prefs;
    return prefs.getBool(key);
  }

  Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
