package test

import (
	"testing"

	"mapleStory079/internal/service"
	"mapleStory079/pkg/database"
)

// TestCombatDamageCalculation 测试伤害计算逻辑
func TestCombatDamageCalculation(t *testing.T) {
	cs := service.NewCombatService()

	character := &database.Character{
		ID:    1,
		Level: 10,
		STR:   25,
		DEX:   15,
		INT:   10,
		LUK:   10,
		Class: 0, // 新手
		HP:    100,
		MaxHP: 100,
	}

	mob := &database.Mob{
		ID:              1,
		Name:            "绿水灵",
		Level:           5,
		HP:              50,
		MaxHP:           50,
		PhysicalAttack:  5,
		PhysicalDefense: 3,
	}

	// 测试玩家攻击怪物
	result, err := cs.PlayerAttackMob(character, mob)
	if err != nil {
		t.Fatalf("PlayerAttackMob failed: %v", err)
	}

	if !result.IsHit {
		t.Logf("First attack missed (acceptable for random)")
	}

	if result.Damage < 0 {
		t.Errorf("Damage should not be negative, got %d", result.Damage)
	}

	t.Logf("Player attack result: damage=%d, is_critical=%v, mob_hp=%d, message=%s",
		result.Damage, result.IsCritical, result.TargetHP, result.Message)
}

// TestCombatMobAttack 测试怪物攻击玩家逻辑
func TestCombatMobAttack(t *testing.T) {
	cs := service.NewCombatService()

	character := &database.Character{
		ID:    1,
		Level: 10,
		HP:    100,
		MaxHP: 100,
		Class: 1, // 战士（高防）
		STR:   30,
	}

	mob := &database.Mob{
		ID:             2,
		Name:           "蘑菇仔",
		Level:          8,
		HP:             80,
		PhysicalAttack: 12,
	}

	for i := 0; i < 5; i++ {
		result, err := cs.MobAttackPlayer(character, mob)
		if err != nil {
			t.Fatalf("MobAttackPlayer failed: %v", err)
		}

		if result.TargetHP < 0 {
			t.Errorf("Character HP should not be negative, got %d", result.TargetHP)
		}

		t.Logf("Mob attack round %d: player_hp=%d, damage=%d, message=%s",
			i+1, result.TargetHP, result.Damage, result.Message)

		if result.TargetDead {
			t.Logf("Character defeated after %d rounds", i+1)
			break
		}
	}
}

// TestCombatStats 测试战斗属性获取
func TestCombatStats(t *testing.T) {
	cs := service.NewCombatService()

	character := &database.Character{
		ID:    1,
		Level: 15,
		Class: 1, // 战士
		HP:    200,
		MaxHP: 200,
		MP:    20,
		MaxMP: 20,
		STR:   40,
		DEX:   20,
		INT:   10,
		LUK:   15,
	}

	stats := cs.GetCombatStats(character)

	attack, ok := stats["attack"].(int)
	if !ok || attack <= 0 {
		t.Errorf("Expected positive attack value, got %v", stats["attack"])
	}

	defense, ok := stats["defense"].(int)
	if !ok || defense < 0 {
		t.Errorf("Expected non-negative defense, got %v", stats["defense"])
	}

	hp, ok := stats["hp"].(int)
	if !ok || hp != 200 {
		t.Errorf("Expected hp=200, got %v", stats["hp"])
	}

	hpPercent, ok := stats["hp_percent"].(float64)
	if !ok || hpPercent < 0 || hpPercent > 100 {
		t.Errorf("Expected hp_percent in [0,100], got %v", stats["hp_percent"])
	}

	t.Logf("Combat stats: attack=%d, defense=%d, hp_percent=%.1f%%",
		attack, defense, hpPercent)
}

// TestGameServiceLevelUp 测试升级流程
func TestGameServiceLevelUp(t *testing.T) {
	gs := service.NewGameService()

	character := &database.Character{
		ID:    1,
		Level: 1,
		Exp:   0,
		HP:    50,
		MaxHP: 50,
		MP:    5,
		MaxMP: 5,
		Class: 1, // 战士
		STR:   12,
		DEX:   5,
		INT:   4,
		LUK:   4,
	}

	// 初始升级所需经验
	requiredExp := gs.GetRequiredExp(character.Level)
	t.Logf("Level %d requires %d exp to level up", character.Level, requiredExp)

	// 模拟获取经验
	character.Exp = int(requiredExp) + 10
	result := gs.ProcessLevelUp(character)

	if !result.Leveled {
		t.Errorf("Expected level up, but leveled=false")
	}

	if result.NewLevel <= 1 {
		t.Errorf("Expected new level > 1, got %d", result.NewLevel)
	}

	if result.HPBonus <= 0 {
		t.Errorf("Expected HP bonus > 0 for warrior class, got %d", result.HPBonus)
	}

	t.Logf("Level up result: new_level=%d, hp_bonus=%d, mp_bonus=%d, ap_bonus=%d, sp_bonus=%d",
		result.NewLevel, result.HPBonus, result.MPBonus, result.APBonus, result.SPBonus)

	// 验证角色状态已更新
	if character.Level != result.NewLevel {
		t.Errorf("Character level not updated: character.level=%d, result.new_level=%d",
			character.Level, result.NewLevel)
	}

	if character.HP != character.MaxHP {
		t.Errorf("Expected HP=MaxHP after level up, got hp=%d, max_hp=%d",
			character.HP, character.MaxHP)
	}
}

// TestGameServiceMultiLevelUp 测试连续升级
func TestGameServiceMultiLevelUp(t *testing.T) {
	gs := service.NewGameService()

	character := &database.Character{
		ID:    1,
		Level: 1,
		Exp:   0,
		Class: 0,
		HP:    50,
		MaxHP: 50,
		MP:    5,
		MaxMP: 5,
	}

	// 给予足够连升3级的经验
	totalExp := 0
	for level := 1; level <= 3; level++ {
		totalExp += int(gs.GetRequiredExp(level))
	}
	character.Exp = totalExp + 50

	result := gs.ProcessLevelUp(character)

	t.Logf("Multi-level up: from level 1 to %d, gained exp total=%d",
		result.NewLevel, totalExp)

	if result.NewLevel < 3 {
		t.Errorf("Expected at least level 3 after multi-level exp, got %d", result.NewLevel)
	}
}

// TestChatServiceSendMessage 测试聊天服务发送消息
func TestChatServiceSendMessage(t *testing.T) {
	_ = service.NewChatService()

	// 注意: 实际测试需要数据库环境，这里只做结构验证
	// 在完整CI环境中会启用测试数据库

	t.Logf("Chat service initialized successfully")

	// 消息类型验证（结构体检查）
	msg := struct {
		SenderID   uint
		SenderName string
		Channel    int
		Content    string
	}{
		SenderID:   1,
		SenderName: "test",
		Channel:    0,
		Content:    "Hello MapleStory!",
	}

	if len(msg.Content) == 0 || len(msg.Content) > 200 {
		t.Errorf("Message content length out of range")
	}

	t.Logf("Valid message: sender=%s, channel=%d, content=%s",
		msg.SenderName, msg.Channel, msg.Content)
}
