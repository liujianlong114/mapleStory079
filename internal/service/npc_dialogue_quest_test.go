package service

import "testing"

func TestRegisterQuestDialogueScriptsDistinctNPCs(t *testing.T) {
	svc := NewNPCService()
	for _, id := range []int{2101, 2100, 12100} {
		script, ok := svc.scripts[id]
		if !ok {
			t.Fatalf("missing script for npc %d", id)
		}
		if script.GetNPCID() != id {
			t.Fatalf("npc %d script reports GetNPCID()=%d", id, script.GetNPCID())
		}
	}
}
