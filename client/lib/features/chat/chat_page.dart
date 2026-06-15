import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';

/// 聊天页面
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      if (chat.currentCharacterId == 0) {
        chat.init(characterId: 1, characterName: '玩家');
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('聊天'),
        backgroundColor: const Color(0xFF16213e),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildChannelBar(chat),
        ),
        actions: [
          if (chat.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 14),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(color: Colors.orange),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: chat.messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(chat.messages[index], chat);
              },
            ),
          ),
          _buildInputBar(chat),
        ],
      ),
    );
  }

  Widget _buildChannelBar(ChatProvider chat) {
    const channels = ChatChannel.values;
    return Container(
      height: 48,
      color: const Color(0xFF0f3460),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final ch = channels[index];
          final selected = ch == chat.currentChannel;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                chat.switchChannel(ch);
                chat.clearUnread();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selected ? Colors.blue : Colors.grey[700],
                foregroundColor: Colors.white,
              ),
              child: Text(_channelLabel(ch)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ChatProvider chat) {
    if (msg.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            msg.content,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    final isMine = msg.senderId == chat.currentCharacterId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.teal,
                child: Text(msg.senderName.characters.first,
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  msg.senderName,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: isMine
                        ? const Color(0xFF4e7cff)
                        : const Color(0xFF2d2d44),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    msg.content,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatProvider chat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF16213e),
        border: Border(top: BorderSide(color: Colors.black26)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '在【${_channelLabel(chat.currentChannel)}】发送消息...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2d2d44),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (value) => _send(chat, value),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _send(chat, _textController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _send(ChatProvider chat, String text) {
    if (text.trim().isEmpty) return;
    chat.sendMessage(text.trim());
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  String _channelLabel(ChatChannel ch) {
    switch (ch) {
      case ChatChannel.world:
        return '世界';
      case ChatChannel.guild:
        return '公会';
      case ChatChannel.party:
        return '组队';
      case ChatChannel.private:
        return '私聊';
    }
  }
}
