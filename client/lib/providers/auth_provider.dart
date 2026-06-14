import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/account.dart';
import '../models/character.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  Account? _account;
  final List<Character> _characters = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  Account? get account => _account;
  int get accountId => _account?.id ?? 0;
  String get username => _account?.username ?? '未登录';
  List<Character> get characters => List.unmodifiable(_characters);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _account != null || _isLoggedIn;
  bool get isLoggedStatus => _isLoggedIn;

  Future<bool> register(String username, String password, String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _account = await _api.register(username, password, email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '注册失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required int accountId,
    required String username,
    String? token,
    String? password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _account = Account(
        id: accountId,
        username: username,
        email: '',
        status: 1,
        createdAt: DateTime.now(),
        token: token,
      );
      _isLoggedIn = true;
      await loadCharacters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '登录失败: $e';
      _isLoading = false;
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginByCredentials(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.login(username, password);
      _account = _api.parseLoginAccount(data);
      if (_account!.id <= 0) {
        throw Exception('账号 ID 无效，请检查服务端登录响应');
      }
      _isLoggedIn = true;
      await loadCharacters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '登录失败: $e';
      _isLoading = false;
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadCharacters() async {
    if (_account == null) return;

    try {
      final list = await _api.getCharacters(_account!.id);
      _characters
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (e) {
      debugPrint('加载角色失败: $e');
    }
  }

  void logout() {
    _account = null;
    _characters.clear();
    _isLoggedIn = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> setGender(int gender) async {
    if (_account == null) return false;
    try {
      final acc = await _api.setGender(_account!.id, gender);
      _account = _account!.copyWith(gender: acc.gender);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  int get accountGender => _account?.gender ?? Account.genderUnset;
  bool get needsGender => _account?.needsGender ?? true;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
