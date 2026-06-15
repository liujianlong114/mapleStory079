import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/skill.dart';
import '../services/api_service.dart';

class SkillProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  final List<Skill> _skills = [];
  final Map<int, int> _skillLevels = {};
  final Map<int, DateTime> _cooldowns = {};
  final List<Skill> _skillBarSlots = List.filled(6, const Skill(
    id: -1,
    name: '',
    description: '',
    characterClass: 0,
    requiredLevel: 1,
    maxLevel: 1,
    mpCost: 0,
    cooldown: 0,
    damageMultiplier: 0,
    range: 0,
    type: '',
  ));
  int _currentMp = 0;
  int _maxMp = 100;
  bool _isLoading = false;
  String? _errorMessage;

  List<Skill> get skills => List.unmodifiable(_skills);
  Map<int, int> get skillLevels => Map.unmodifiable(_skillLevels);
  List<Skill> get skillBarSlots => List.unmodifiable(_skillBarSlots);
  int get currentMp => _currentMp;
  int get maxMp => _maxMp;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSkills(int characterId, int characterClass) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _api.getAllSkills();
      _skills.clear();
      _skillLevels.clear();

      final classSkills = list.where((s) => s.characterClass == characterClass).toList();
      if (classSkills.isEmpty) {
        _skills.addAll(SkillCatalog.skillsForClass(characterClass));
      } else {
        _skills.addAll(classSkills);
      }

      for (final skill in _skills) {
        _skillLevels[skill.id] = skill.currentLevel > 0 ? skill.currentLevel : 1;
      }

      for (int i = 0; i < _skillBarSlots.length && i < _skills.length; i++) {
        _skillBarSlots[i] = _skills[i];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载技能失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void useSkill(Skill skill) {
    if (_currentMp < skill.mpCost) return;
    if (isSkillOnCooldown(skill.id)) return;

    _currentMp -= skill.mpCost;
    if (_currentMp < 0) _currentMp = 0;

    _cooldowns[skill.id] = DateTime.now().add(Duration(milliseconds: skill.cooldown));

    Timer(Duration(milliseconds: skill.cooldown), () {
      _cooldowns.remove(skill.id);
      notifyListeners();
    });

    notifyListeners();
  }

  bool isSkillOnCooldown(int skillId) {
    final cd = _cooldowns[skillId];
    if (cd == null) return false;
    if (DateTime.now().isAfter(cd)) {
      _cooldowns.remove(skillId);
      return false;
    }
    return true;
  }

  int? getCooldownRemaining(int skillId) {
    final cd = _cooldowns[skillId];
    if (cd == null) return null;
    final remaining = cd.difference(DateTime.now()).inMilliseconds;
    if (remaining <= 0) {
      _cooldowns.remove(skillId);
      return null;
    }
    return remaining;
  }

  void levelUpSkill(int skillId) {
    final skillIndex = _skills.indexWhere((s) => s.id == skillId);
    if (skillIndex < 0) return;
    final skill = _skills[skillIndex];
    if (skill.isMaxed) return;

    final newLevel = (skill.currentLevel + 1);
    _skills[skillIndex] = skill.copyWith();
    _skillLevels[skillId] = newLevel;
    notifyListeners();
  }

  int getSkillLevel(int skillId) => _skillLevels[skillId] ?? 0;

  void setMp(int mp, {int? max}) {
    _currentMp = mp;
    if (max != null) _maxMp = max;
    notifyListeners();
  }

  void restoreMp(int amount) {
    _currentMp = (_currentMp + amount).clamp(0, _maxMp);
    notifyListeners();
  }

  void consumeMp(int amount) {
    _currentMp = (_currentMp - amount).clamp(0, _maxMp);
    notifyListeners();
  }

  void setSkillBarSlot(int slot, Skill skill) {
    if (slot < 0 || slot >= _skillBarSlots.length) return;
    _skillBarSlots[slot] = skill;
    notifyListeners();
  }

  void clearSkillBarSlot(int slot) {
    if (slot < 0 || slot >= _skillBarSlots.length) return;
    _skillBarSlots[slot] = const Skill(
      id: -1,
      name: '',
      description: '',
      characterClass: 0,
      requiredLevel: 1,
      maxLevel: 1,
      mpCost: 0,
      cooldown: 0,
      damageMultiplier: 0,
      range: 0,
      type: '',
    );
    notifyListeners();
  }

  void reset() {
    _skills.clear();
    _skillLevels.clear();
    _cooldowns.clear();
    _currentMp = 0;
    _maxMp = 100;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
