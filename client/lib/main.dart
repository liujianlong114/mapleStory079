import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'config/app_config.dart';
import 'features/login/login_page.dart';
import 'features/character/character_select_page.dart';
import 'features/game/game_page.dart';
import 'features/game/game_scene_loader.dart';
import 'features/chat/chat_page.dart';
import 'features/combat/combat_page.dart';
import 'features/inventory/inventory_page.dart';
import 'features/skills/skills_page.dart';
import 'features/social/social_page.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/combat_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/chat_provider.dart';

void main() {
  runApp(const MapleStoryApp());
}

class MapleStoryApp extends StatelessWidget {
  const MapleStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => CombatProvider(context.read<GameProvider>())),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => SkillProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.mapleStory079,
        initialRoute: Routes.login,
        routes: {
          Routes.login: (context) => const LoginPage(),
          Routes.characterSelect: (context) => const CharacterSelectPage(),
          Routes.game: (context) => const GamePage(),
          Routes.gameScene: (context) => const GameSceneLoader(),
          Routes.chat: (context) => const ChatPage(),
          Routes.combat: (context) => const CombatPage(),
          Routes.inventory: (context) => const InventoryPage(),
          Routes.skills: (context) => const SkillsPage(),
          Routes.social: (context) => const SocialPage(),
        },
      ),
    );
  }
}

class Routes {
  static const String login = '/login';
  static const String characterSelect = '/character-select';
  static const String game = '/game';
  static const String gameScene = '/game-scene';
  static const String chat = '/chat';
  static const String combat = '/combat';
  static const String inventory = '/inventory';
  static const String skills = '/skills';
  static const String social = '/social';
}
