import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplestory_client/features/game/game_scene_page.dart';
import 'package:maplestory_client/providers/game_provider.dart';
import 'package:maplestory_client/providers/inventory_provider.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GameScenePage layout does not throw setState-during-build', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GameProvider()),
          ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ],
        child: MaterialApp(
          home: SizedBox(
            width: 1280,
            height: 800,
            child: GameScenePage(
              mapId: 1000000,
              mapName: '彩虹村',
              mapWidth: 1705,
              mapHeight: 1230,
              groundY: 605,
              characterId: 1,
              initialPosX: 400,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 500));

    final exception = tester.takeException();
    expect(exception, isNull, reason: '$exception');

    expect(find.textContaining('setState() or markNeedsBuild()'), findsNothing);
    expect(find.textContaining('size" is not ready yet'), findsNothing);
  });
}
