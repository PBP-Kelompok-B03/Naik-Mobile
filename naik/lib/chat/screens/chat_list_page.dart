// lib/chat/screens/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:naik/chat/models/chat_entry.dart';
import 'package:naik/chat/screens/chat_page.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:naik/widgets/left_drawer.dart';
import 'package:naik/config/app_config.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final String baseUrl = AppConfig.baseUrl;
  bool loadingCreate = false;

  Future<List<ChatConversation>> fetchConversations(CookieRequest request) async {
    final response = await request.get('$baseUrl/chat/api/list/');
    List<ChatConversation> listChat = [];
    if (response != null && response is Map && response['conversations'] != null) {
      for (var d in response['conversations']) {
        try {
          listChat.add(ChatConversation.fromJson(Map<String, dynamic>.from(d)));
        } catch (e) {
          debugPrint("Failed parsing conversation: $e");
        }
      }
    }
    return listChat;
  }

  Future<void> createConversationDialog(CookieRequest request) async {
    final TextEditingController _other = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat percakapan baru'),
        content: TextField(
          controller: _other,
          decoration: const InputDecoration(hintText: 'Masukkan username lawan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final otherUsername = _other.text.trim();
              if (otherUsername.isEmpty) return;
              Navigator.pop(context);
              await createConversation(request, otherUsername);
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  Future<void> createConversation(CookieRequest request, String otherUsername) async {
    setState(() => loadingCreate = true);
    try {
      final body = {'other_username': otherUsername};
      final resp = await request.post('$baseUrl/chat/api/create/', body);
      print("CREATE CONVERSATION RESPONSE: $resp");
      if (resp != null && resp is Map && resp['conversation'] != null) {
        // success: open new convo langsung
        final convo = ChatConversation.fromJson(Map<String, dynamic>.from(resp['conversation']));
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatPage(convoId: convo.id, otherUsername: convo.otherUsername)),
          ).then((_) => setState(() {}));
        }
      } else {
        // Tampilkan pesan error jika ada
        final msg = (resp is Map && resp['message'] != null) ? resp['message'] : 'Gagal membuat percakapan';
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      debugPrint("createConversation error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan saat membuat percakapan')));
      }
    } finally {
      if (mounted) setState(() => loadingCreate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.read<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      drawer: const LeftDrawer(),
      body: FutureBuilder<List<ChatConversation>>(
        future: fetchConversations(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final chats = snapshot.data ?? [];
            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Belum ada percakapan.'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Buat percakapan'),
                      onPressed: () => createConversationDialog(request),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    ),
                  ],
                ),
              );
            } else {
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // paksa reload FutureBuilder
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      title: Text(chat.otherUsername, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: chat.unreadCount > 0
                          ? CircleAvatar(radius: 12, child: Text(chat.unreadCount.toString(), style: const TextStyle(fontSize: 12)))
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(convoId: chat.id, otherUsername: chat.otherUsername),
                          ),
                        ).then((_) => setState(() {})); // refresh saat kembali
                      },
                    );
                  },
                ),
              );
            }
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => createConversationDialog(request),
        child: loadingCreate ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add),
        backgroundColor: Colors.black,
      ),
    );
  }
}
