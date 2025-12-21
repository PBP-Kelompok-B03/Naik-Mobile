import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:naik/models/product_entry.dart';
import 'package:naik/reviews/comment_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:naik/config/app_config.dart';
import 'package:naik/screens/product_entry_list.dart';
import 'package:naik/checkout/screens/checkout_page.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductEntry product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String _userRole = '';
  int _userId = 0;

  int quantity = 1;
  
  // Track edit mode for comments and replies
  Map<String, bool> _editingComments = {};
  Map<String, TextEditingController> _commentControllers = {};
  Map<String, int> _editingCommentRatings = {}; // Add this to track rating edits
  Map<String, bool> _replyingToComments = {}; // Track which comments are in reply mode
  Map<String, TextEditingController> _replyToCommentControllers = {}; // Controllers for reply inputs
  Map<String, bool> _editingReplies = {};
  Map<String, TextEditingController> _replyControllers = {};

  int get totalPrice =>
      widget.product.price.toInt() * quantity;

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

  bool _canEditOrDelete() {
    if (_userRole == 'buyer') return false;
    if (_userRole == 'admin') return true;
    if (_userRole == 'seller') {
      return widget.product.userId == _userId;
    }
    return false;
  }

  bool _canBuy() {
    return _userRole == 'buyer' && widget.product.stock > 0;
  }

  // Helper methods to check ownership
  bool _isCommentOwner(String authorId) {
    int? parsedId = int.tryParse(authorId);
    return parsedId != null && parsedId == _userId;
  }

  bool _isReplyOwner(String authorId) {
    int? parsedId = int.tryParse(authorId);
    return parsedId != null && parsedId == _userId;
  }

  @override
  void dispose() {
    // Dispose all TextEditingControllers
    for (var controller in _commentControllers.values) {
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

  Future<void> _editComment(String commentId, String newContent, int newRating) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/edit/$commentId/',
        jsonEncode( {
          'content': newContent,
          'rating': newRating,
        }),
      );
      
      if (response['status'] == true) {
        // Update the comment data locally
        for (var comment in widget.product.comments ?? []) {
          if (comment.commentId == commentId) {
            comment.commentContent = newContent;
            comment.commentRating = newRating;
            break;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar berhasil diperbarui')),
        );
        setState(() {
          _editingComments[commentId] = false;
          _commentControllers[commentId]?.dispose();
          _commentControllers.remove(commentId);
          _editingCommentRatings.remove(commentId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal mengupdate komentar')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/delete/$commentId/',
        jsonEncode( {},)
      );
      
      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar berhasil dihapus')),
        );
        setState(() {
          widget.product.comments?.removeWhere((c) => c.commentId == commentId);
          _commentControllers[commentId]?.dispose();
          _commentControllers.remove(commentId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal menghapus komentar')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editReply(String replyId, String newContent) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/reply/edit/$replyId/',
        jsonEncode( {
          'content': newContent,
        }),
      );
      
      if (response['status'] == true) {
        // Update the reply data locally
        for (var comment in widget.product.comments ?? []) {
          for (var reply in comment.replies ?? []) {
            if (reply.replyId == replyId) {
              reply.replyContent = newContent;
              break;
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

  Future<void> _deleteReply(String replyId) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/reply/delete/$replyId/',
        jsonEncode( {} ),
      );
      
      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balasan berhasil dihapus')),
        );
        setState(() {
          for (var comment in widget.product.comments ?? []) {
            comment.replies?.removeWhere((r) => r.replyId == replyId);
          }
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

  Future<void> _replyToComment(String commentId, String replyContent) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '${AppConfig.baseUrl}/comments/api/flutter/reply/$commentId/',
        jsonEncode({
          'content': replyContent,
        }),
      );
      
      if (response['status'] == true) {
        // Update the reply data locally
        for (var comment in widget.product.comments ?? []) {
          if (comment.commentId == commentId) {
            // Create new Reply object from response
            final newReply = Reply(
              replyId: response['reply_id'] ?? '',
              replyContent: replyContent,
              replyAuthorId: response['reply_author_id']?.toString() ?? _userId.toString(),
              replyAuthorUsername: response['reply_author_username'] ?? 'Unknown',
              replyAuthorRole: response['reply_author_role'] ?? 'buyer',
              replyCreatedAt: DateTime.now(),
            );
            
            // Add reply to comment's replies list
            comment.replies ??= [];
            comment.replies!.add(newReply);
            break;
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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Detail'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// IMAGE
            if (widget.product.getImageUrl().isNotEmpty)
              Image.network(
                kIsWeb
                    ? widget.product.getProxiedImageUrl()
                    : widget.product.getImageUrl(),
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TITLE
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// PRICE
                  Text(
                    'Rp ${widget.product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// STOCK
                  Text(
                    'Stok tersedia: ${widget.product.stock}',
                    style: TextStyle(
                      color: widget.product.stock > 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),

                  const Divider(height: 32),

                  /// JUMLAH
                  const Text(
                    "Jumlah",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                      ),

                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (quantity < widget.product.stock) {
                            setState(() => quantity++);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Jumlah melebihi stok tersedia",
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// TOTAL HARGA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Rp $totalPrice",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// BUY BUTTON
                  if (_canBuy())
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutPage(
                                product: widget.product,
                                quantity: quantity,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.blue.shade700,
                          disabledForegroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "BELI SEKARANG",
                          style: TextStyle(
                            fontWeight: FontWeight.w800, // 🔥 EXTRA BOLD
                            letterSpacing: 1,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  /// COMMENTS SECTION
                  const Text(
                    "Ulasan (Reviews)",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (widget.product.comments == null || widget.product.comments!.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "Belum ada ulasan",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.product.comments!.length,
                      itemBuilder: (context, index) {
                        final comment = widget.product.comments![index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '(${comment.commentAuthorRole})',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(comment.commentCreatedAt),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    /// RATING STARS
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
                                          hintText: 'Edit komentar...',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      /// RATING EDITOR
                                      const Text(
                                        'Rating',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                                _editComment(comment.commentId, newContent, newRating);
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
                                        style: const TextStyle(fontSize: 14),
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
                                                          title: const Text('Hapus Komentar'),
                                                          content: const Text('Yakin ingin menghapus komentar ini?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(ctx),
                                                              child: const Text('Batal'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(ctx);
                                                                _deleteComment(comment.commentId);
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
                                                    _replyingToComments[comment.commentId] = !(_replyingToComments[comment.commentId] ?? false);
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
                                                    _replyingToComments[comment.commentId] = !(_replyingToComments[comment.commentId] ?? false);
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
                                          )
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
                                                  hintText: 'Balas Komentar ini',
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
                                                      final replyContent = _replyToCommentControllers[comment.commentId]?.text ?? '';
                                                      if (replyContent.isNotEmpty) {
                                                        _replyToComment(comment.commentId, replyContent);
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
                                          color: Colors.grey[300]!,
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
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '(${reply.replyAuthorRole})',
                                                      style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 11,
                                                      ),
                                                    ),
                                                    ],
                                                  ),
                                                  Text(
                                                    _formatDate(reply.replyCreatedAt),
                                                    style: TextStyle(
                                                    color: Colors.grey[600],
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
                                                                final newContent = _replyControllers[reply.replyId]?.text ?? '';
                                                                if (newContent.isNotEmpty) {
                                                                  _editReply(reply.replyId, newContent);
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
                                                        style: const TextStyle(fontSize: 12),
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
                                                                        content: const Text('Yakin ingin menghapus balasan ini?'),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed: () => Navigator.pop(ctx),
                                                                            child: const Text('Batal'),
                                                                          ),
                                                                          TextButton(
                                                                            onPressed: () {
                                                                              Navigator.pop(ctx);
                                                                              _deleteReply(reply.replyId);
                                                                            },
                                                                            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  },
                                                                  icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                                                                  label: const Text('Hapus', style: TextStyle(fontSize: 11, color: Colors.red)),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to format date
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
}
