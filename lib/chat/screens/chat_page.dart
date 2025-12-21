// lib/chat/screens/chat_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:naik/chat/models/chat_entry.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:naik/config/app_config.dart';

class ChatPage extends StatefulWidget {
  final String convoId;
  final String otherUsername;

  const ChatPage({super.key, required this.convoId, required this.otherUsername});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final String baseUrl = AppConfig.baseUrl;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  Timer? timer;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchMessages());
    timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchMessages());
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('$baseUrl/chat/api/${widget.convoId}/messages/');
      if (response != null && response is Map && response['messages'] != null) {
        List<ChatMessage> newMsgs = [];
        for (var m in response['messages']) {
          try {
            newMsgs.add(ChatMessage.fromJson(Map<String, dynamic>.from(m)));
          } catch (e) {
            debugPrint("msg parse error: $e");
          }
        }
        setState(() => messages = newMsgs);
        // scroll to bottom
        Future.delayed(const Duration(milliseconds: 120), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("fetchMessages error: $e");
    }
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => sending = true);
    _controller.clear();
    final request = context.read<CookieRequest>();
    try {
      final resp = await request.post('$baseUrl/chat/api/${widget.convoId}/send/', {'content': text});
      if (resp != null && resp['ok'] == true) {
        await fetchMessages();
      } else {
        debugPrint("Failed send: $resp");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim pesan')));
        }
      }
    } catch (e) {
      debugPrint("sendMessage error: $e");
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.otherUsername;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.chat_bubble_outline, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(username, overflow: TextOverflow.ellipsis)),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  // asumsikan backend menyertakan username pengirim; kalau tidak, bandingkan senderId dengan current user id
                  final isMe = msg.senderUsername.toLowerCase() == 'you' || msg.senderUsername == 'You' || msg.senderUsername.isEmpty == false && msg.senderUsername == 'me';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blueAccent : Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Image.network(msg.imageUrl!.startsWith('http') ? msg.imageUrl! : '$baseUrl${msg.imageUrl!}'),
                            ),
                          Text(msg.content, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 6),
                          Text(msg.createdAt, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan...',
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white),
                    onPressed: sending ? null : sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
