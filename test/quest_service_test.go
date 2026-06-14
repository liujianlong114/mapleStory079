package test

import (
	"testing"
	"time"

	"mapleStory079/internal/service"
	"mapleStory079/pkg/database"
)

func TestQuestAcceptAndComplete(t *testing.T) {
	if database.DB == nil {
		t.Skip("database not available")
	}

	char := &database.Character{
		AccountID: 99999,
		Name:      "quest_test_" + time.Now().Format("150405"),
		Class:     0,
		Level:     1,
		Exp:       0,
		Mesos:     0,
		MapID:     1000000,
		CreatedAt: time.Now(),
	}
	if err := database.DB.Create(char).Error; err != nil {
		t.Fatalf("create character: %v", err)
	}
	defer database.DB.Delete(char)

	qs := service.NewQuestService()

	cq, err := qs.AcceptQuest(char.ID, 400000)
	if err != nil {
		t.Fatalf("accept quest: %v", err)
	}
	if cq.Status != service.QuestStatusInProgress {
		t.Fatalf("expected in progress, got %d", cq.Status)
	}

	effect, err := qs.CompleteQuest(char.ID, 400000)
	if err != nil {
		t.Fatalf("complete quest: %v", err)
	}
	if effect.ExpGained <= 0 {
		t.Errorf("expected exp reward, got %d", effect.ExpGained)
	}
	if !qs.IsQuestCompleted(char.ID, 400000) {
		t.Error("quest should be completed")
	}
}

func TestQuestMirrorChain(t *testing.T) {
	if database.DB == nil {
		t.Skip("database not available")
	}

	char := &database.Character{
		AccountID: 99998,
		Name:      "mirror_test_" + time.Now().Format("150405"),
		Class:     0,
		Level:     1,
		MapID:     1000000,
		CreatedAt: time.Now(),
	}
	if err := database.DB.Create(char).Error; err != nil {
		t.Fatalf("create character: %v", err)
	}
	defer database.DB.Delete(char)

	qs := service.NewQuestService()
	inv := service.NewInventoryService()

	if _, err := qs.AcceptQuest(char.ID, 1000); err != nil {
		t.Fatalf("accept 1000: %v", err)
	}
	if err := inv.AddItem(char.ID, service.ItemSallyMirror, 1); err != nil {
		t.Fatalf("add mirror: %v", err)
	}
	if _, err := qs.CompleteQuest(char.ID, 1000); err != nil {
		t.Fatalf("complete 1000: %v", err)
	}
	if _, err := qs.AcceptQuest(char.ID, 1001); err != nil {
		t.Fatalf("accept 1001: %v", err)
	}
	effect, err := qs.CompleteQuest(char.ID, 1001)
	if err != nil {
		t.Fatalf("complete 1001: %v", err)
	}
	if effect.ExpGained <= 0 {
		t.Errorf("expected exp from 1001")
	}
}
