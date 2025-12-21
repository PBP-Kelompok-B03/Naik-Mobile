import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../widgets/left_drawer.dart';
import '../../reviews/comment_entry.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  String _userRole = '';
  int _userId = 0;

  // Track edit mode for comments and replies
  Map<String, bool> _editingComments = {};
  Map<String, TextEditingController> _commentControllers = {};
  Map<String, int> _editingCommentRatings = {};
  Map<String, bool> _creatingCommentForItem = {}; // Track which items are creating new comments
  Map<String, TextEditingController> _createCommentControllers = {}; // Controllers for new comment inputs
  Map<String, int> _newCommentRatings = {}; // Rating for new comments
  Map<String, bool> _replyingToComments = {};
  Map<String, TextEditingController> _replyToCommentControllers = {};
  Map<String, bool> _editingReplies = {};
  Map<String, TextEditingController> _replyControllers = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'buyer';
      _userId = prefs.getInt('user_id') ?? 0;
    });
  }

  @override
  void dispose() {
    // Dispose all TextEditingControllers
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    for (var controller in _createCommentControllers.values) {
      controller.dispose();
    }
    for (var controller in _replyToCommentControllers.values) {
      controller.dispose();
    }
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isCommentOwner(String authorId) {
    int? parsedId = int.tryParse(authorId);
    return parsedId != null && parsedId == _userId;
  }

  bool _isReplyOwner(String authorId) {
    int? parsedId = int.tryParse(authorId);
    return parsedId != null && parsedId == _userId;
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        return 'Baru saja';
      }
      return '${difference.inHours}jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}hari yang lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _createComment(String itemId, String content, int rating, List<dynamic> items) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/create-comment/',
        jsonEncode({
          'order_item_id': itemId,
          'content': content,
          'rating': rating,
        }),
      );

      if (response['status'] == true) {
        // Find item and update comments list locally
        for (var itemDynamic in items) {
          final item = itemDynamic as Map<String, dynamic>;
          if (item['product_id'] == itemId) {
            final newComment = Comment(
              commentId: response['comment_id'] ?? '',
              commentRating: rating,
              commentContent: content,
              commentAuthorId: response['comment_author_id']?.toString() ?? _userId.toString(),
              commentAuthorUsername: response['comment_author_username'] ?? 'You',
              commentAuthorRole: _userRole,
              commentCreatedAt: DateTime.now(),
              replies: [],
            );

            if (item['comments'] == null) {
              item['comments'] = [];
            }
            (item['comments'] as List<dynamic>).add(newComment);
            break;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan berhasil dibuat')),
        );
        setState(() {
          _creatingCommentForItem[itemId] = false;
          _createCommentControllers[itemId]?.dispose();
          _createCommentControllers.remove(itemId);
          _newCommentRatings.remove(itemId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal membuat ulasan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editComment(String commentId, String newContent, int newRating, List<dynamic> items) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/edit/$commentId/',
        jsonEncode({
          'content': newContent,
          'rating': newRating,
        }),
      );

      if (response['status'] == true) {
        // Update comment data locally
        for (var itemDynamic in items) {
          final item = itemDynamic as Map<String, dynamic>;
          final comments = item['comments'] as List<dynamic>?;
          if (comments != null) {
            for (var comment in comments) {
              if (comment is Comment && comment.commentId == commentId) {
                comment.commentContent = newContent;
                comment.commentRating = newRating;
                break;
              }
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan berhasil diperbarui')),
        );
        setState(() {
          _editingComments[commentId] = false;
          _commentControllers[commentId]?.dispose();
          _commentControllers.remove(commentId);
          _editingCommentRatings.remove(commentId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal mengupdate ulasan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteComment(String commentId, List<dynamic> items) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/delete/$commentId/',
        jsonEncode({}),
      );

      if (response['status'] == true) {
        // Remove comment from items list
        for (var itemDynamic in items) {
          final item = itemDynamic as Map<String, dynamic>;
          final comments = item['comments'] as List<dynamic>?;
          if (comments != null) {
            comments.removeWhere((c) => c is Comment && c.commentId == commentId);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan berhasil dihapus')),
        );
        setState(() {
          _commentControllers[commentId]?.dispose();
          _commentControllers.remove(commentId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal menghapus ulasan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _replyToComment(String commentId, String replyContent, List<dynamic> items) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/reply/$commentId/',
        jsonEncode({'content': replyContent}),
      );

      if (response['status'] == true) {
        // Update reply data locally
        for (var itemDynamic in items) {
          final item = itemDynamic as Map<String, dynamic>;
          final comments = item['comments'] as List<dynamic>?;
          if (comments != null) {
            for (var commentDynamic in comments) {
              if (commentDynamic is Comment && commentDynamic.commentId == commentId) {
                final newReply = Reply(
                  replyId: response['reply_id'] ?? '',
                  replyContent: replyContent,
                  replyAuthorId: response['reply_author_id']?.toString() ?? _userId.toString(),
                  replyAuthorUsername: response['reply_author_username'] ?? 'You',
                  replyAuthorRole: _userRole,
                  replyCreatedAt: DateTime.now(),
                );

                commentDynamic.replies ??= [];
                commentDynamic.replies!.add(newReply);
                break;
              }
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balasan berhasil dikirim')),
        );
        setState(() {
          _replyingToComments[commentId] = false;
          _replyToCommentControllers[commentId]?.dispose();
          _replyToCommentControllers.remove(commentId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal mengirim balasan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editReply(String replyId, String newContent, List<dynamic> items) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/reply/edit/$replyId/',
        jsonEncode({'content': newContent}),
      );

      if (response['status'] == true) {
        // Update reply data locally
        for (var itemDynamic in items) {
          final item = itemDynamic as Map<String, dynamic>;
          final comments = item['comments'] as List<dynamic>?;
          if (comments != null) {
            for (var commentDynamic in comments) {
              if (commentDynamic is Comment) {
                for (var reply in commentDynamic.replies ?? []) {
                  if (reply.replyId == replyId) {
                    reply.replyContent = newContent;
                    break;
                  }
                }
              }
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balasan berhasil diperbarui')),
        );
        setState(() {
          _editingReplies[replyId] = false;
          _replyControllers[replyId]?.dispose();
          _replyControllers.remove(replyId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal mengupdate balasan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteReply(String replyId, List<dynamic> items) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/reply/delete/$replyId/',
        jsonEncode({}),
      );

      if (response['status'] == true) {
        // Remove reply from items
        for (var itemDynamic in items) {
          final item = itemDynamic as Map<String, dynamic>;
          final comments = item['comments'] as List<dynamic>?;
          if (comments != null) {
            for (var commentDynamic in comments) {
              if (commentDynamic is Comment) {
                commentDynamic.replies?.removeWhere((r) => r.replyId == replyId);
              }
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balasan berhasil dihapus')),
        );
        setState(() {
          _replyControllers[replyId]?.dispose();
          _replyControllers.remove(replyId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal menghapus balasan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<List<dynamic>> fetchOrders(CookieRequest request) async {
    try {
      final response = await request.get("${AppConfig.baseUrl}/checkout/api/orders/");
      
      // // Debug: Print response untuk melihat struktur JSON
      // print('=== ORDER LIST RESPONSE ===');
      // print('Response type: ${response.runtimeType}');
      // print('Response: $response');
      
      // if (response is List) {
      //   print('Total orders: ${response.length}');
      //   if (response.isNotEmpty) {
      //     print('First order: ${response[0]}');
      //     final firstOrder = response[0] as Map<String, dynamic>;
      //     final items = firstOrder['items'] as List?;
      //     print('Items in first order: ${items?.length ?? 0}');
      //     if (items != null && items.isNotEmpty) {
      //       print('First item: ${items[0]}');
      //       final firstItem = items[0] as Map<String, dynamic>;
      //       final comments = firstItem['comments'];
      //       print('Comments field type: ${comments.runtimeType}');
      //       print('Comments: $comments');
      //     }
      //   }
      // }
      
      return response is List ? response : [];
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "PAID":
        return Colors.greenAccent;
      case "PENDING":
        return Colors.orangeAccent;
      case "SHIPPED":
        return Colors.blueAccent;
      case "COMPLETED":
        return Colors.tealAccent;
      default:
        return Colors.redAccent;
    }
  }

  String safe(dynamic v, [String fallback = "-"]) {
    if (v == null) return fallback;
    return v.toString().isEmpty ? fallback : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Pesanan Saya"),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const LeftDrawer(),
      body: FutureBuilder<List<dynamic>>(
        future: fetchOrders(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada pesanan",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index] as Map<String, dynamic>;
              final items = order['items'] as List<dynamic>? ?? [];
              final item = items.isNotEmpty ? items.first : null;

              final productName = safe(item?['product_name']);
              final quantity = safe(item?['quantity'], "0");

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "#${safe(order['id'])}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor(order['status'])
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            safe(order['status']),
                            style: TextStyle(
                              color: statusColor(order['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24),

                    /// PRODUK
                    _row("Produk", productName, bold: true),
                    _row("Jumlah", "x $quantity"),

                    const SizedBox(height: 12),

                    /// COMMENTS SECTION
                    _buildCommentsSection(item, items),

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),

                    /// META
                    _row("Pembayaran", safe(order['payment_method'])),
                    _row("Pengiriman", safe(order['shipping_type'])),
                    _row("Asuransi",
                        order['insurance'] == true ? "Ya" : "Tidak"),

                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),

                    /// FOOTER
                    _row("TOTAL", "Rp ${safe(order['total_price'])}",
                        bold: true,
                        valueColor: Colors.greenAccent),
                    const SizedBox(height: 6),
                    Text(
                      safe(order['created_at']),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCommentsSection(dynamic item, List<dynamic> items) {
    if (item == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: const Text(
          "💬 Item tidak valid",
          style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
        ),
      );
    }

    // Get itemId (OrderItem ID for API) dan productId (Product ID for display) dengan safe access
    final orderItemId = item['order_item_id']?.toString() ?? '';
    final productId = item['product_id']?.toString() ?? '';
    
    if (orderItemId.isEmpty || productId.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: const Text(
          "💬 ID item tidak ditemukan",
          style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
        ),
      );
    }

    // Get comments dengan safe access - default empty list jika tidak ada
    final commentsList = item['comments'];
    final List<dynamic> comments = commentsList is List ? commentsList : [];
    
    // Convert raw JSON maps to Comment objects
    final List<Comment> convertedComments = comments.map((commentDynamic) {
      if (commentDynamic is Comment) {
        return commentDynamic;
      }
      final commentMap = commentDynamic as Map<String, dynamic>;
      final repliesList = (commentMap['replies'] as List<dynamic>?)?.map((replyDynamic) {
        if (replyDynamic is Reply) {
          return replyDynamic;
        }
        final replyMap = replyDynamic as Map<String, dynamic>;
        return Reply(
          replyId: replyMap['reply_id']?.toString() ?? '',
          replyContent: replyMap['reply_content']?.toString() ?? '',
          replyAuthorId: replyMap['reply_author_id']?.toString() ?? '',
          replyAuthorUsername: replyMap['reply_author_username']?.toString() ?? 'Unknown',
          replyAuthorRole: replyMap['reply_author_role']?.toString() ?? 'user',
          replyCreatedAt: DateTime.parse(replyMap['reply_created_at']?.toString() ?? DateTime.now().toIso8601String()),
        );
      }).toList() ?? [];
      
      return Comment(
        commentId: commentMap['comment_id']?.toString() ?? '',
        commentRating: int.tryParse(commentMap['comment_rating']?.toString() ?? '0') ?? 0,
        commentContent: commentMap['comment_content']?.toString() ?? '',
        commentAuthorId: commentMap['comment_author_id']?.toString() ?? '',
        commentAuthorUsername: commentMap['comment_author_username']?.toString() ?? 'Unknown',
        commentAuthorRole: commentMap['comment_author_role']?.toString() ?? 'user',
        commentCreatedAt: DateTime.parse(commentMap['comment_created_at']?.toString() ?? DateTime.now().toIso8601String()),
        replies: repliesList,
      );
    }).toList();

    // No comments case
    if (convertedComments.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kamu belum memberikan ulasan",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _creatingCommentForItem[orderItemId] = !(_creatingCommentForItem[orderItemId] ?? false);
                    if (_creatingCommentForItem[orderItemId] == false) {
                      _createCommentControllers[orderItemId]?.dispose();
                      _createCommentControllers.remove(orderItemId);
                      _newCommentRatings.remove(orderItemId);
                    }
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Tambahkan Ulasan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            // Create comment form
            if (_creatingCommentForItem[orderItemId] == true)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _createCommentControllers.putIfAbsent(
                        orderItemId,
                        () => TextEditingController(),
                      ),
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Buat ulasan untuk produk ini',
                        isDense: true,
                        contentPadding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rating',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (starIndex) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _newCommentRatings[orderItemId] = starIndex + 1;
                            });
                          },
                          child: Icon(
                            starIndex < (_newCommentRatings[orderItemId] ?? 0)
                                ? Icons.star
                                : Icons.star_outline,
                            size: 28,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _creatingCommentForItem[orderItemId] = false;
                              _createCommentControllers[orderItemId]?.dispose();
                              _createCommentControllers.remove(orderItemId);
                              _newCommentRatings.remove(orderItemId);
                            });
                          },
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final content = _createCommentControllers[orderItemId]?.text ?? '';
                            final rating = _newCommentRatings[orderItemId] ?? 0;
                            if (content.isNotEmpty && rating > 0) {
                              _createComment(orderItemId, content, rating, items);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Silakan isi konten dan pilih rating')),
                              );
                            }
                          },
                          child: const Text('Kirim'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    // Show comments
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        convertedComments.length,
        (commentIndex) {
          final comment = convertedComments[commentIndex];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: const Color(0xFF232323),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// COMMENT HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comment.commentAuthorUsername,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${comment.commentAuthorRole})',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(comment.commentCreatedAt),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (starIndex) => Icon(
                            starIndex < comment.commentRating
                                ? Icons.star
                                : Icons.star_outline,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// COMMENT CONTENT
                  if (_editingComments[comment.commentId] == true)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _commentControllers[comment.commentId],
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Edit ulasan...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Rating',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            5,
                            (starIndex) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  _editingCommentRatings[comment.commentId] = starIndex + 1;
                                });
                              },
                              child: Icon(
                                starIndex < (_editingCommentRatings[comment.commentId] ?? comment.commentRating)
                                    ? Icons.star
                                    : Icons.star_outline,
                                size: 28,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _editingComments[comment.commentId] = false;
                                  _commentControllers[comment.commentId]?.dispose();
                                  _commentControllers.remove(comment.commentId);
                                  _editingCommentRatings.remove(comment.commentId);
                                });
                              },
                              child: const Text('Batal'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final newContent = _commentControllers[comment.commentId]?.text ?? '';
                                final newRating = _editingCommentRatings[comment.commentId] ?? comment.commentRating;
                                if (newContent.isNotEmpty) {
                                  _editComment(comment.commentId, newContent, newRating, items);
                                }
                              },
                              child: const Text('Kirim'),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.commentContent,
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        if (_isCommentOwner(comment.commentAuthorId))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        _commentControllers[comment.commentId] =
                                            TextEditingController(text: comment.commentContent);
                                        _editingCommentRatings[comment.commentId] = comment.commentRating;
                                        setState(() {
                                          _editingComments[comment.commentId] = true;
                                        });
                                      },
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Hapus Ulasan'),
                                            content: const Text('Yakin ingin menghapus ulasan ini?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Batal'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _deleteComment(comment.commentId, items);
                                                },
                                                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                      label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _replyingToComments[comment.commentId] =
                                          !(_replyingToComments[comment.commentId] ?? false);
                                      if (_replyingToComments[comment.commentId] == false) {
                                        _replyToCommentControllers[comment.commentId]?.dispose();
                                        _replyToCommentControllers.remove(comment.commentId);
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.reply, size: 16),
                                  label: const Text('Balas'),
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox.shrink(),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _replyingToComments[comment.commentId] =
                                          !(_replyingToComments[comment.commentId] ?? false);
                                      if (_replyingToComments[comment.commentId] == false) {
                                        _replyToCommentControllers[comment.commentId]?.dispose();
                                        _replyToCommentControllers.remove(comment.commentId);
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.reply, size: 16),
                                  label: const Text('Balas'),
                                ),
                              ],
                            ),
                          ),
                        /// REPLY INPUT
                        if (_replyingToComments[comment.commentId] == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _replyToCommentControllers.putIfAbsent(
                                    comment.commentId,
                                    () => TextEditingController(),
                                  ),
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    hintText: 'Balas Ulasan ini',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.all(8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _replyingToComments[comment.commentId] = false;
                                          _replyToCommentControllers[comment.commentId]?.dispose();
                                          _replyToCommentControllers.remove(comment.commentId);
                                        });
                                      },
                                      child: const Text('Batal'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        final replyContent =
                                            _replyToCommentControllers[comment.commentId]?.text ?? '';
                                        if (replyContent.isNotEmpty) {
                                          _replyToComment(comment.commentId, replyContent, items);
                                        }
                                      },
                                      child: const Text('Kirim'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                  /// REPLIES SECTION
                  if (comment.replies != null && comment.replies!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(left: 16, top: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.grey[600]!,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          comment.replies!.length,
                          (replyIndex) {
                            final reply = comment.replies![replyIndex];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            reply.replyAuthorUsername,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${reply.replyAuthorRole})',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _formatDate(reply.replyCreatedAt),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (_editingReplies[reply.replyId] == true)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: _replyControllers[reply.replyId],
                                          maxLines: 2,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            hintText: 'Edit balasan...',
                                            isDense: true,
                                            contentPadding: const EdgeInsets.all(8),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            SizedBox(
                                              height: 28,
                                              child: TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _editingReplies[reply.replyId] = false;
                                                    _replyControllers[reply.replyId]?.dispose();
                                                    _replyControllers.remove(reply.replyId);
                                                  });
                                                },
                                                child: const Text('Batal', style: TextStyle(fontSize: 12)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            SizedBox(
                                              height: 28,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  final newContent =
                                                      _replyControllers[reply.replyId]?.text ?? '';
                                                  if (newContent.isNotEmpty) {
                                                    _editReply(reply.replyId, newContent, items);
                                                  }
                                                },
                                                child: const Text('Kirim', style: TextStyle(fontSize: 12)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reply.replyContent,
                                          style: const TextStyle(fontSize: 12, color: Colors.white),
                                        ),
                                        if (_isReplyOwner(reply.replyAuthorId))
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  height: 28,
                                                  child: TextButton.icon(
                                                    onPressed: () {
                                                      _replyControllers[reply.replyId] =
                                                          TextEditingController(text: reply.replyContent);
                                                      setState(() {
                                                        _editingReplies[reply.replyId] = true;
                                                      });
                                                    },
                                                    icon: const Icon(Icons.edit, size: 14),
                                                    label: const Text('Edit', style: TextStyle(fontSize: 11)),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 28,
                                                  child: TextButton.icon(
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text('Hapus Balasan'),
                                                          content:
                                                              const Text('Yakin ingin menghapus balasan ini?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(ctx),
                                                              child: const Text('Batal'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(ctx);
                                                                _deleteReply(reply.replyId, items);
                                                              },
                                                              child: const Text('Hapus',
                                                                  style: TextStyle(color: Colors.red)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                                                    label: const Text('Hapus',
                                                        style: TextStyle(fontSize: 11, color: Colors.red)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54)),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
