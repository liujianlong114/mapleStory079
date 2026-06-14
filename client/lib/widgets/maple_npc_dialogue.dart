import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'npc_dialogue_widget.dart';

/// 服务端驱动的 NPC 多轮对话（任务接取/完成）。
Future<void> showServerNpcDialogue(
  BuildContext context, {
  required int npcId,
  required int characterId,
  void Function(Map<String, dynamic>? effects)? onEffects,
}) async {
  final api = ApiService();
  Map<String, dynamic> data;
  try {
    data = await api.startNpcDialogue(npcId: npcId, characterId: characterId);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('对话失败: $e')),
      );
    }
    return;
  }

  if (!context.mounted) return;
  await _dialogueLoop(context, api: api, npcId: npcId, characterId: characterId, data: data, onEffects: onEffects);
}

Future<void> _dialogueLoop(
  BuildContext context, {
  required ApiService api,
  required int npcId,
  required int characterId,
  required Map<String, dynamic> data,
  void Function(Map<String, dynamic>? effects)? onEffects,
}) async {
  final node = data['node'] as Map<String, dynamic>?;
  if (node == null) return;

  final speaker = node['speaker'] as String? ?? data['npc_name'] as String? ?? 'NPC';
  final text = node['text'] as String? ?? '';
  final nodeType = node['node_type'] as String? ?? 'choice';
  final nodeId = node['id'] as String? ?? 'start';
  final choices = (node['choices'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  if (nodeType == 'end' || (choices.isEmpty && node['action'] == 'close')) {
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => NPCDialogueWidget.basic(
          npcName: speaker,
          dialogue: text,
          onClose: () => Navigator.pop(ctx),
        ),
      );
    }
    return;
  }

  final optionTexts = choices.map((c) => c['text'] as String? ?? '').where((t) => t.isNotEmpty).toList();
  if (optionTexts.isEmpty) return;

  final selectedIndex = await showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => NPCDialogueWidget(
      npcName: speaker,
      dialogue: text,
      options: optionTexts,
      onOptionSelected: (opt) {
        final idx = optionTexts.indexOf(opt);
        Navigator.pop(ctx, idx >= 0 ? idx : 0);
      },
      onClose: () => Navigator.pop(ctx),
    ),
  );

  if (!context.mounted || selectedIndex == null || selectedIndex < 0) return;

  Map<String, dynamic> next;
  try {
    next = await api.continueNpcDialogue(
      npcId: npcId,
      characterId: characterId,
      nodeId: nodeId,
      choiceIndex: selectedIndex,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('对话继续失败: $e')),
      );
    }
    return;
  }

  final effects = next['effects'] as Map<String, dynamic>?;
  if (effects != null) {
    onEffects?.call(effects);
    if (context.mounted) {
      final exp = (effects['exp_gained'] as num?)?.toInt() ?? 0;
      final questDone = effects['quest_completed'];
      if (exp > 0 || questDone != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              questDone != null
                  ? '任务完成！获得 $exp 经验'
                  : '获得 $exp 经验',
            ),
          ),
        );
      }
    }
  }

  if (!context.mounted) return;
  await _dialogueLoop(context, api: api, npcId: npcId, characterId: characterId, data: next, onEffects: onEffects);
}
