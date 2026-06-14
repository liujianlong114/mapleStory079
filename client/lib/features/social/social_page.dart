import 'package:flutter/material.dart';

/// 社交页面 - 好友/公会/组队
class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Friend> _friends = [
    Friend(id: 2, name: '小明', level: 35, class_: '战士', online: true),
    Friend(id: 3, name: '冒险王', level: 52, class_: '法师', online: true),
    Friend(id: 4, name: '弓箭手艾拉', level: 28, class_: '弓箭手', online: false),
    Friend(id: 5, name: '飞侠小黑', level: 41, class_: '飞侠', online: false),
    Friend(id: 6, name: '海盗杰克', level: 33, class_: '海盗', online: true),
  ];

  final List<GuildMember> _guildMembers = [
    GuildMember(id: 1, name: '玩家', role: '会长', level: 30, online: true),
    GuildMember(id: 2, name: '小明', role: '副会长', level: 35, online: true),
    GuildMember(id: 3, name: '冒险王', role: '成员', level: 52, online: true),
    GuildMember(id: 4, name: '无名剑客', role: '成员', level: 22, online: false),
    GuildMember(id: 5, name: '治疗师娜娜', role: '成员', level: 18, online: false),
  ];

  final List<PartyMember> _partyMembers = [
    PartyMember(id: 1, name: '玩家', role: '队长', class_: '新手'),
    PartyMember(id: 2, name: '小明', role: '队员', class_: '战士'),
    PartyMember(id: 3, name: '冒险王', role: '队员', class_: '法师'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('社交'),
        backgroundColor: const Color(0xFF16213e),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: '好友'),
            Tab(text: '公会'),
            Tab(text: '组队'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildGuildTab(),
          _buildPartyTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    final online = _friends.where((f) => f.online).length;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF0f3460),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('好友 ${_friends.length} 人（在线 $online）',
                  style: const TextStyle(color: Colors.white)),
              TextButton.icon(
                onPressed: () => _showAddFriendDialog(),
                icon: const Icon(Icons.person_add, color: Colors.blue, size: 18),
                label: const Text('添加', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: _friends.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10),
            itemBuilder: (_, i) {
              final f = _friends[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: f.online ? Colors.green : Colors.grey,
                  child: Text(f.name.characters.first,
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(f.name,
                    style: TextStyle(
                        color: f.online ? Colors.white : Colors.grey)),
                subtitle: Text('Lv.${f.level} ${f.class_}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: f.online
                    ? const Icon(Icons.chat, color: Colors.blue)
                    : const Icon(Icons.chat, color: Colors.grey),
                onTap: () => _showFriendOptions(f),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGuildTab() {
    final online = _guildMembers.where((m) => m.online).length;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF0f3460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('冒险岛勇士公会',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 4),
              Text('等级: 5 | 成员: ${_guildMembers.length} (在线 $online)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('公告: 欢迎加入，一起冒险吧！',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: _guildMembers.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10),
            itemBuilder: (_, i) {
              final m = _guildMembers[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: m.online ? Colors.green : Colors.grey,
                  child: Text(m.name.characters.first,
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(m.name,
                    style: TextStyle(
                        color: m.online ? Colors.white : Colors.grey)),
                subtitle: Text('${m.role} · Lv.${m.level}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPartyTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF0f3460),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('当前队伍: ${_partyMembers.length} 人',
                  style: const TextStyle(color: Colors.white)),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('邀请'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.leave_bags_at_home, size: 16),
                    label: const Text('离开'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: _partyMembers.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10),
            itemBuilder: (_, i) {
              final p = _partyMembers[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(p.name.characters.first,
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(p.name,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text('${p.role} · ${p.class_}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: p.role == '队长'
                    ? const Icon(Icons.star, color: Colors.orange)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('添加好友', style: TextStyle(color: Colors.white)),
        content: const TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '输入玩家名称',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已发送好友请求')),
              );
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  void _showFriendOptions(Friend f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213e),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.blue),
              title: Text('与 ${f.name} 私聊',
                  style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.green),
              title: Text('邀请 ${f.name} 加入队伍',
                  style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('删除好友 ${f.name}',
                  style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class Friend {
  final int id;
  final String name;
  final int level;
  final String class_;
  final bool online;
  Friend({required this.id, required this.name, required this.level,
      required this.class_, required this.online});
}

class GuildMember {
  final int id;
  final String name;
  final String role;
  final int level;
  final bool online;
  GuildMember({required this.id, required this.name, required this.role,
      required this.level, required this.online});
}

class PartyMember {
  final int id;
  final String name;
  final String role;
  final String class_;
  PartyMember({required this.id, required this.name, required this.role,
      required this.class_});
}
