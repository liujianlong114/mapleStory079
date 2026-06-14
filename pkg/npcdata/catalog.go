package npcdata

import (
	"mapleStory079/pkg/database"
	"mapleStory079/pkg/maplife"
)

// Meta 079 WZ String.wz/Npc.img 中的名称与默认台词（d0）。
type Meta struct {
	Name     string
	Dialogue string
	HasShop  bool
}

// Catalog 常用 NPC 元数据（彩虹岛新手链优先）。
var Catalog = map[uint]Meta{
	2101: {Name: "希娜", Dialogue: "你是第一次到冒险岛来吗？怎么样？虽然还很陌生，不过很漂亮吧？希望你能在这里找到很多乐趣~"},
	2100: {Name: "莎丽", Dialogue: "真是个晒衣服的好天气~ 你不觉得吗？"},
	2007: {Name: "冒险岛运营员", Dialogue: ""},
	2000: {Name: "罗杰", Dialogue: "天气真好啊～"},
	2102: {Name: "妮娜", Dialogue: "#p2001#会在做什么呢？不晓得有没有到处乱跑…会不会肚子饿了在哭呢……"},
	2001: {Name: "珊", Dialogue: "居然都没有东西可以吃，呜呜呜呜~~"},
	2002: {Name: "彼特", Dialogue: "怎么样？旅途愉快吗？"},
	2004: {Name: "透德", Dialogue: "你不知道该去哪里，我来告诉你吧"},
	12000: {Name: "路卡斯", Dialogue: "到时候该收到#p2103#的信了啊。。。发生了什么事情呢？唔。。。谁能给我传来消息呢。。"},
	10000: {Name: "皮奥", Dialogue: "啊，好可惜。到处丢掉的都是可以再用的好东西。。呼。。"},
	12101: {Name: "瑞恩", Dialogue: "你想挑战一下瑞恩的脑筋急转弯吗？你要是有自信，就跟我谈谈。"},
	2103: {Name: "玛丽亚", Dialogue: "啊啊~为什么看不到有人经过呢？难道没有亲切的冒险家吗？"},
	12100: {Name: "麦加", Dialogue: "呜呼。。。不要在那里逛来逛去的，来接受我的修炼怎么样？随时都可以来找我~我会让你变得更强壮。。。"},
	20100: {Name: "尤娜", Dialogue: "什么时候才能离开金银岛看更广阔的世界呢?"},
	20001: {Name: "白瑞德", Dialogue: "制作任何东东我都很有自信.因为彩虹村的皮奥可是我的叔叔哦,从小开始叔叔就教我这些技术."},
	20002: {Name: "比格斯", Dialogue: "总有一天我会离开这个小村落的，有谁能帮帮我？"},
	22000: {Name: "桑克斯", Dialogue: "我就是船长。新手一旦离开彩虹岛就很难返回，外面的世界很危险，务必做好准备再出航~"},
	11000: {Name: "赛德", Dialogue: "战斗中需要的药水和武器在村落中都可以买到"},
	11100: {Name: "露茜", Dialogue: ""},
}

// Lookup 返回 NPC 元数据；未知 ID 时给出占位名。
func Lookup(id uint) Meta {
	if m, ok := Catalog[id]; ok {
		return m
	}
	return Meta{Name: "NPC", Dialogue: "你好，冒险者！"}
}

// NPCsFromMapLife 按 WZ life 刷点生成 NPC 列表（坐标为屏幕坐标，与 maplife JSON 一致）。
func NPCsFromMapLife(ml *maplife.MapLife) []database.NPC {
	if ml == nil {
		return nil
	}
	spawns := ml.NpcSpawns()
	if len(spawns) == 0 {
		return nil
	}
	out := make([]database.NPC, 0, len(spawns))
	for _, e := range spawns {
		meta := Lookup(e.ID)
		out = append(out, database.NPC{
			ID:          e.ID,
			Name:        meta.Name,
			Description: meta.Dialogue,
			MapID:       ml.MapID,
			PositionX:   int(e.X),
			PositionY:   int(e.Y),
			HasShop:     meta.HasShop,
		})
	}
	return out
}
