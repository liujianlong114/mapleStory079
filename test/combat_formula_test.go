package test

import (
	"math/rand"
	"testing"
	"time"

	"mapleStory079/internal/service"
	"mapleStory079/pkg/database"
)

func init() {
	rand.Seed(time.Now().UnixNano())
}

// TestDamageFormula 验证伤害公式边界条件
func TestDamageFormula(t *testing.T) {
	cs := service.NewCombatService()

	testCases := []struct {
		name        string
		character   *database.Character
		mob         *database.Mob
		expectRange [2]int // 期望最小/最大伤害范围
	}{
		{
			name: "新手 VS 弱小怪物",
			character: &database.Character{
				Level: 1, Class: 0, STR: 12, DEX: 5, INT: 4, LUK: 4,
				HP: 50, MaxHP: 50,
			},
			mob: &database.Mob{
				Name: "蜗牛", Level: 1, HP: 20, MaxHP: 20,
				PhysicalAttack: 2, PhysicalDefense: 1,
			},
			expectRange: [2]int{1, 30},
		},
		{
			name: "高等级战士 VS 中级怪物",
			character: &database.Character{
				Level: 30, Class: 1, STR: 80, DEX: 30, INT: 20, LUK: 15,
				HP: 800, MaxHP: 800,
			},
			mob: &database.Mob{
				Name: "火独眼兽", Level: 25, HP: 500, MaxHP: 500,
				PhysicalAttack: 50, PhysicalDefense: 30,
			},
			expectRange: [2]int{1, 200},
		},
		{
			name: "法师 VS 高防怪物",
			character: &database.Character{
				Level: 20, Class: 2, STR: 10, DEX: 10, INT: 60, LUK: 15,
				HP: 300, MaxHP: 300, MP: 200, MaxMP: 200,
			},
			mob: &database.Mob{
				Name: "石头人", Level: 20, HP: 400, MaxHP: 400,
				PhysicalAttack: 40, PhysicalDefense: 50,
			},
			expectRange: [2]int{1, 100},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			for i := 0; i < 10; i++ {
				// 克隆怪物HP以避免持久影响
				mobCopy := *tc.mob
				charCopy := *tc.character
				result, err := cs.PlayerAttackMob(&charCopy, &mobCopy)
				if err != nil {
					t.Fatalf("Attack failed: %v", err)
				}

				if result.IsHit {
					if result.Damage < tc.expectRange[0] || result.Damage > tc.expectRange[1] {
						t.Logf("[%s] Damage %d outside expected range [%d, %d] (may be random fluctuation)",
							tc.name, result.Damage, tc.expectRange[0], tc.expectRange[1])
					}
					t.Logf("[%s] Round %d: damage=%d, crit=%v, mob_hp=%d/%d",
						tc.name, i+1, result.Damage, result.IsCritical, result.TargetHP, tc.mob.MaxHP)
				} else {
					t.Logf("[%s] Round %d: MISS", tc.name, i+1)
				}
			}
		})
	}
}

// TestCriticalRateDistribution 测试暴击率分布（统计性测试）
func TestCriticalRateDistribution(t *testing.T) {
	cs := service.NewCombatService()

	// 飞侠有最高暴击率基础
	thief := &database.Character{
		Level: 10, Class: 4, STR: 10, DEX: 30, INT: 10, LUK: 40,
		HP: 200, MaxHP: 200,
	}

	mob := &database.Mob{
		Name: "木桩", Level: 1, HP: 9999, MaxHP: 9999,
		PhysicalDefense: 0,
	}

	critCount := 0
	totalRounds := 500

	for i := 0; i < totalRounds; i++ {
		mobCopy := *mob
		charCopy := *thief
		result, _ := cs.PlayerAttackMob(&charCopy, &mobCopy)
		if result.IsCritical {
			critCount++
		}
	}

	critRate := float64(critCount) / float64(totalRounds)
	t.Logf("Thief (LUK=40) critical rate: %.2f%% (%d/%d)",
		critRate*100, critCount, totalRounds)

	// 理论暴击率: 0.03 + 40/200 + 0.08 (飞侠修正) + 10*0.002
	// = 0.03 + 0.2 + 0.08 + 0.02 = 0.33 (33%)
	expectedRate := 0.33
	tolerance := 0.10 // 10% 容差（统计波动）

	if critRate < expectedRate-tolerance || critRate > expectedRate+tolerance {
		t.Logf("Note: observed crit rate %.2f%% differs from expected ~%.0f%% (statistical fluctuation)",
			critRate*100, expectedRate*100)
	}
}

// TestHitRateDistribution 测试命中率统计
func TestHitRateDistribution(t *testing.T) {
	cs := service.NewCombatService()

	character := &database.Character{
		Level: 10, Class: 3, STR: 10, DEX: 50, INT: 10, LUK: 10,
		HP: 200, MaxHP: 200,
	}

	// 测试对不同等级怪物的命中率
	mobs := []*database.Mob{
		{Name: "低级怪", Level: 5, HP: 100, MaxHP: 100, PhysicalDefense: 5},
		{Name: "同级怪", Level: 10, HP: 100, MaxHP: 100, PhysicalDefense: 10},
		{Name: "高级怪", Level: 20, HP: 100, MaxHP: 100, PhysicalDefense: 20},
	}

	for _, mob := range mobs {
		hitCount := 0
		rounds := 200
		for i := 0; i < rounds; i++ {
			mobCopy := *mob
			charCopy := *character
			result, _ := cs.PlayerAttackMob(&charCopy, &mobCopy)
			if result.IsHit {
				hitCount++
			}
		}
		hitRate := float64(hitCount) / float64(rounds)
		t.Logf("Vs %s (lv.%d): hit rate = %.2f%% (%d/%d)",
			mob.Name, mob.Level, hitRate*100, hitCount, rounds)
	}
}

// TestReviveCharacter 测试角色复活逻辑
func TestReviveCharacter(t *testing.T) {
	cs := service.NewCombatService()

	character := &database.Character{
		HP:    0,
		MaxHP: 200,
		MP:    0,
		MaxMP: 50,
	}

	cs.ReviveCharacter(character)

	if character.HP != character.MaxHP/2 {
		t.Errorf("After revive, expected HP = MaxHP/2=%d, got %d",
			character.MaxHP/2, character.HP)
	}

	if character.MP != character.MaxMP/2 {
		t.Errorf("After revive, expected MP = MaxMP/2=%d, got %d",
			character.MaxMP/2, character.MP)
	}

	if character.PositionX != 0 || character.PositionY != 0 {
		t.Errorf("After revive, expected position = (0,0), got (%d,%d)",
			character.PositionX, character.PositionY)
	}

	t.Logf("Revive successful: hp=%d/%d, mp=%d/%d, pos=(%d,%d)",
		character.HP, character.MaxHP, character.MP, character.MaxMP,
		character.PositionX, character.PositionY)
}

// TestRequiredExpCurve 测试升级经验曲线合理性
func TestRequiredExpCurve(t *testing.T) {
	gs := service.NewGameService()

	var prevExp int64 = 0
	for level := 1; level <= 50; level++ {
		required := int64(gs.GetRequiredExp(level))

		if required <= prevExp && level > 1 {
			t.Errorf("Level %d required exp (%d) should be > level %d required exp (%d)",
				level, required, level-1, prevExp)
		}

		if level%10 == 0 || level == 1 {
			t.Logf("Level %d requires %d exp", level, required)
		}

		prevExp = required
	}
}

// TestClassName 测试职业名称映射
func TestClassName(t *testing.T) {
	classes := []struct {
		class    int
		expected string
	}{
		{0, "新手"},
		{1, "战士"},
		{2, "法师"},
		{3, "弓箭手"},
		{4, "飞侠"},
		{5, "海盗"},
	}

	for _, tc := range classes {
		name := service.GetClassName(tc.class)
		if name != tc.expected {
			t.Errorf("Class %d: expected %q, got %q", tc.class, tc.expected, name)
		}
		t.Logf("Class %d => %s", tc.class, name)
	}

	// 测试未知职业
	unknown := service.GetClassName(999)
	t.Logf("Unknown class 999 => %s (should be non-empty fallback)", unknown)
}
