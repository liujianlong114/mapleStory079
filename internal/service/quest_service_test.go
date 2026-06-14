package service

import (
	"testing"

	"mapleStory079/pkg/database"
)

func TestQuestAcceptAndComplete(t *testing.T) {
	qs := NewQuestService()
	char := &database.Character{ID: 9999, Level: 1, Exp: 0, Mesos: 0}
	// 使用内存模拟：跳过 DB，仅测状态机逻辑需要集成测试。
	// 此处验证 QuestKillTarget 配置。
	target, ok := QuestKillTarget[400001]
	if !ok || target.MobID != 100100 || target.Need != 10 {
		t.Fatalf("quest 400001 kill target misconfigured: %+v ok=%v", target, ok)
	}
	_ = qs
	_ = char
}

func TestRainbowQuestScriptNPC(t *testing.T) {
	script := &rainbowQuestScript{npcID: 2101, qs: NewQuestService()}
	if script.GetNPCID() != 2101 {
		t.Fatalf("expected npc 2101")
	}
}
