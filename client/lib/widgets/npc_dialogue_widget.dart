import 'package:flutter/material.dart';

class NPCDialogueWidget extends StatelessWidget {
  final String npcName;
  final String? npcIcon;
  final String dialogue;
  final List<String> options;
  final void Function(String option)? onOptionSelected;
  final VoidCallback? onClose;

  const NPCDialogueWidget({
    super.key,
    required this.npcName,
    this.npcIcon,
    required this.dialogue,
    this.options = const [],
    this.onOptionSelected,
    this.onClose,
  });

  factory NPCDialogueWidget.basic({
    Key? key,
    required String npcName,
    required String dialogue,
    VoidCallback? onClose,
  }) {
    return NPCDialogueWidget(
      key: key,
      npcName: npcName,
      dialogue: dialogue,
      options: const ['继续'],
      onOptionSelected: (_) => onClose?.call(),
      onClose: onClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.amberAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      npcName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  dialogue,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              if (options.isNotEmpty)
                ...options.map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onOptionSelected != null
                              ? () => onOptionSelected!(option)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.amberAccent.withOpacity(0.5)),
                            ),
                          ),
                          child: Text(option, style: const TextStyle(fontSize: 14)),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

void showNPCDialogue(BuildContext context, {
  required String npcName,
  required String dialogue,
  List<String> options = const ['继续'],
  void Function(String option)? onOptionSelected,
}) {
  showDialog(
    context: context,
    builder: (context) => NPCDialogueWidget(
      npcName: npcName,
      dialogue: dialogue,
      options: options,
      onOptionSelected: (option) {
        onOptionSelected?.call(option);
        Navigator.of(context).pop();
      },
    ),
  );
}
