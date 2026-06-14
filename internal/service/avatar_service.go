package service

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sync"

	"mapleStory079/pkg/look"
	"mapleStory079/pkg/utils"
)

// AvatarService Phase 1：运行时 CharacterRenderer.compose（wzpy）
type AvatarService struct {
	cacheDir string
	mu       sync.Mutex
}

func NewAvatarService() *AvatarService {
	dir := filepath.Join(utils.ProjectRoot(), ".cache", "composed-looks")
	_ = os.MkdirAll(dir, 0o755)
	return &AvatarService{cacheDir: dir}
}

type composePayload struct {
	Gender    int      `json:"gender"`
	Face      int      `json:"face"`
	Hair      int      `json:"hair"`
	Skin      int      `json:"skin"`
	Top       int      `json:"top"`
	Bottom    int      `json:"bottom"`
	Longcoat  int      `json:"longcoat"`
	Shoes     int      `json:"shoes"`
	Cap       int      `json:"cap"`
	Cape      int      `json:"cape"`
	Glove     int      `json:"glove"`
	Shield    int      `json:"shield"`
	Weapon    int      `json:"weapon"`
	FaceAcc   int      `json:"face_acc"`
	EyeAcc    int      `json:"eye_acc"`
	Earring   int      `json:"earring"`
	EquipIDs  []string `json:"equip_ids"`
	Pose      string   `json:"pose"`
	Frame     int      `json:"frame"`
}

// ComposePNG 合成完整 CharLook PNG（带磁盘缓存）
func (s *AvatarService) ComposePNG(l look.CharLook, pose string, frame int, scale int, pad int) ([]byte, error) {
	if pose == "" {
		pose = "stand1"
	}
	if scale < 1 {
		scale = 1
	}
	if scale > 8 {
		scale = 8
	}
	if pad < 0 {
		pad = 0
	}
	if pad > 32 {
		pad = 32
	}
	cachePath := filepath.Join(s.cacheDir, fmt.Sprintf("%s_s%d_p%d_%s_f%d.png", l.CacheKey(), scale, pad, pose, frame))
	if data, err := os.ReadFile(cachePath); err == nil && len(data) > 256 {
		return data, nil
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	if data, err := os.ReadFile(cachePath); err == nil && len(data) > 256 {
		return data, nil
	}

	python := utils.WzPythonVenv()
	if _, err := os.Stat(python); err != nil {
		return nil, fmt.Errorf("wzpy venv not found at %s: run scripts/setup_maple_wz.sh", python)
	}
	client := utils.MapleClientDir()
	if _, err := os.Stat(filepath.Join(client, "Character.wz")); err != nil {
		return nil, fmt.Errorf("Character.wz not found at %s", client)
	}

	tmpJSON := filepath.Join(s.cacheDir, l.CacheKey()+".json")
	payload := composePayload{
		Gender: l.Gender, Face: l.Face, Hair: l.Hair, Skin: l.Skin,
		Top: l.Top, Bottom: l.Bottom, Longcoat: l.Longcoat,
		Shoes: l.Shoes, Cap: l.Cap, Cape: l.Cape, Glove: l.Glove,
		Shield: l.Shield, Weapon: l.Weapon,
		FaceAcc: l.FaceAcc, EyeAcc: l.EyeAcc, Earring: l.Earring,
		EquipIDs: l.EquipIDs(), Pose: pose, Frame: frame,
	}
	raw, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}
	if err := os.WriteFile(tmpJSON, raw, 0o644); err != nil {
		return nil, err
	}

	script := filepath.Join(utils.ProjectRoot(), "scripts", "extract_wz_py", "compose_look.py")
	cmd := exec.Command(python, script,
		"--client", client,
		"--out", cachePath,
		"--json", tmpJSON,
		"--pose", pose,
		"--frame", fmt.Sprintf("%d", frame),
		"--scale", fmt.Sprintf("%d", scale),
		"--pad", fmt.Sprintf("%d", pad),
	)
	cmd.Env = append(os.Environ(), "PYTHONPATH="+filepath.Join(utils.ProjectRoot(), ".cache", "wz-python"))
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("compose failed: %w\n%s", err, string(out))
	}
	data, err := os.ReadFile(cachePath)
	if err != nil {
		return nil, err
	}
	return data, nil
}
