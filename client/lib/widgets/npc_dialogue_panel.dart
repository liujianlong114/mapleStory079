import 'package:flutter/material.dart';

import '../core/resources/assets.dart';

/// 服务端 NPC 对话节点（对齐 Go DialogueNode JSON）
class NpcDialogueNode {
  final String id;
  final String speaker;
  final String text;
  final String nodeType;
  final List<NpcDialogueChoice> choices;
  final String? action;
  final String? nextId;

  const NpcDialogueNode({
    required this.id,
    required this.speaker,
    required this.text,
    this.nodeType = 'choice',
    this.choices = const [],
    this.action,
    this.nextId,
  });

  factory NpcDialogueNode.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List? ?? [];
    return NpcDialogueNode(
      id: json['id'] as String? ?? 'start',
      speaker: json['speaker'] as String? ?? '',
      text: json['text'] as String? ?? '',
      nodeType: json['node_type'] as String? ?? 'choice',
      action: json['action'] as String?,
      nextId: json['next_id'] as String?,
      choices: rawChoices
          .map((e) => NpcDialogueChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEnd => nodeType == 'end' || action == 'close';
}

class NpcDialogueChoice {
  final String text;
  final String nextId;
  final String action;
  final String data;

  const NpcDialogueChoice({
    required this.text,
    this.nextId = '',
    this.action = '',
    this.data = '',
  });

  factory NpcDialogueChoice.fromJson(Map<String, dynamic> json) {
    return NpcDialogueChoice(
      text: json['text'] as String? ?? '',
      nextId: json['next_id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      data: json['data'] as String? ?? '',
    );
  }
}

/// 079 风格 NPC 对话面板（服务端驱动多轮对话）
///
/// 节点类型：
/// - "say"：纯台词，下方显示 [OK] 按钮（或无按钮由点击文本推进），
///   对话结束时自动改为 [关闭]。
/// - "choice"：提供多个选项按钮。
/// - "end"：结束节点，显示 [关闭]。
class NpcDialoguePanel extends StatelessWidget {
  const NpcDialoguePanel({
    super.key,
    required this.node,
    required this.onChoice,
    required this.onNext,
    required this.onClose,
  });

  final NpcDialogueNode node;
  final void Function(NpcDialogueChoice choice, int index) onChoice;
  final VoidCallback onNext;
  final VoidCallback onClose;

  bool get _isSay => node.nodeType == 'say';
  bool get _isChoice => node.nodeType == 'choice' || node.choices.isNotEmpty;
  bool get _isEnd => node.isEnd || node.action == 'close';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFFf5e6c8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF8b6914), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      node.speaker,
                      style: const TextStyle(
                        color: Color(0xFF3d2817),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                    AudioManager().playUiClick();
                    onClose();
                  },
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF5c4033)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _isSay ? () {
                  AudioManager().playUiClick();
                  onNext();
                } : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFfff8e8),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: const Color(0xFFc4a574)),
                  ),
                  child: Text(
                    node.text,
                    style: const TextStyle(
                      color: Color(0xFF3d2817),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isChoice && node.choices.isNotEmpty)
                ...List.generate(node.choices.length, (i) {
                  final c = node.choices[i];
                  final isClose = c.action == 'close' || c.nextId == 'end';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          AudioManager().playUiClick();
                          onChoice(c, i);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: isClose ? const Color(0xFFd9c8a0) : const Color(0xFFe8d4a8),
                          foregroundColor: const Color(0xFF3d2817),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                            side: const BorderSide(color: Color(0xFF8b6914)),
                          ),
                        ),
                        child: Text(c.text, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  );
                })
              else if (_isSay && !_isEnd)
                Align(
                  alignment: Alignment.centerRight,
                  child: _okButton(() {
                    AudioManager().playUiClick();
                    onNext();
                  }, 'OK'),
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: _okButton(() {
                    AudioManager().playUiClick();
                    onClose();
                  }, '关闭'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _okButton(VoidCallback onTap, String text) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFe8d4a8),
        foregroundColor: const Color(0xFF3d2817),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: Color(0xFF8b6914)),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
