import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:naik/models/product_entry.dart';
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
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

            // ================= IMAGE =================
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

                  // ================= AUCTION BADGE =================
                  if (widget.product.isAuction)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'AUCTION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // ================= TITLE =================
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ================= PRICE =================
                  Text(
                    'Rp ${widget.product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ================= CATEGORY =================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.product.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ================= STOCK & SOLD =================
                  Row(
                    children: [
                      Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${widget.product.stock}',
                        style: TextStyle(
                          color: widget.product.stock > 0
                              ? Colors.grey[600]
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Sold: ${widget.product.countSold}'),
                    ],
                  ),

                  // ================= AUCTION INFO =================
                  if (widget.product.isAuction) ...[
                    const Divider(height: 32),
                    const Text(
                      'Auction Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.product.auctionIncrement != null)
                      Text(
                        'Bid Increment: Rp ${widget.product.auctionIncrement!.toStringAsFixed(0)}',
                      ),
                    if (widget.product.auctionEndTime != null)
                      Text(
                        'Auction Ends: ${_formatDate(widget.product.auctionEndTime)}',
                      ),
                  ],

                  const SizedBox(height: 24),

                  // ================= EDIT / DELETE =================
                  if (_canEditOrDelete())
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Edit feature coming soon!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Product'),
                                  content: Text(
                                    'Delete "${widget.product.title}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                final response = await request.post(
                                  "${AppConfig.baseUrl}/delete-flutter/${widget.product.id}/",
                                  {},
                                );

                                if (response['status'] == 'success') {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProductEntryListPage(),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // ================= BUY NOW =================
                  if (_canBuy()) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutPage(
                                product: widget.product,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'BELI SEKARANG',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
