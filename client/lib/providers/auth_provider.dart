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
      if (data['account'] != null) {
        _account = Account.fromJson(data['account'] as Map<String, dynamic>);
      } else if (data['data'] != null) {
        _account = Account.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        _account = Account(
          id: 1,
          username: username,
          email: '',
          status: 1,
          createdAt: DateTime.now(),
        );
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
      _characters.clear();
      _characters.add(Character(
        id: 1,
        accountId: _account!.id,
        name: '新手角色',
        characterClass: 0,
        gender: 0,
        level: 1,
        experience: 0,
        mapId: 1,
        positionX: 100,
        positionY: 100,
        hp: 50,
        maxHp: 50,
        mp: 5,
        maxMp: 5,
        str: 12,
        dex: 5,
        intl: 4,
        luk: 4,
        mesos: 1000,
      ));
      _characters.add(Character(
        id: 2,
        accountId: _account!.id,
        name: '战士号',
        characterClass: 1,
        gender: 0,
        level: 10,
        experience: 500,
        mapId: 2,
        positionX: 50,
        positionY: 50,
        hp: 200,
        maxHp: 200,
        mp: 20,
        maxMp: 20,
        str: 50,
        dex: 20,
        intl: 4,
        luk: 4,
        mesos: 5000,
      ));
      _characters.add(Character(
        id: 3,
        accountId: _account!.id,
        name: '法师号',
        characterClass: 2,
        gender: 1,
        level: 15,
        experience: 1200,
        mapId: 3,
        positionX: 0,
        positionY: 0,
        hp: 80,
        maxHp: 80,
        mp: 300,
        maxMp: 300,
        str: 10,
        dex: 15,
        intl: 80,
        luk: 30,
        mesos: 2000,
      ));
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
