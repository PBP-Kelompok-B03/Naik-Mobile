import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:naik/models/product_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:naik/config/app_config.dart';
import 'package:naik/screens/product_entry_list.dart';

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
    // Buyers cannot edit or delete
    if (_userRole == 'buyer') return false;

    // Admins can edit/delete anything
    if (_userRole == 'admin') return true;

    // Sellers can only edit/delete their own products
    if (_userRole == 'seller') {
      return widget.product.userId == _userId;
    }

    return false;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    // Simple date formatter without intl package
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
            // Thumbnail image
            if (widget.product.getImageUrl().isNotEmpty)
              Image.network(
                // Use proxy on web to avoid CORS, direct URL on mobile
                kIsWeb ? widget.product.getProxiedImageUrl() : widget.product.getImageUrl(),
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auction badge
                  if (widget.product.isAuction)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20.0),
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

                  // Title
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price
                  Text(
                    'Rp ${widget.product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          borderRadius: BorderRadius.circular(12.0),
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

                  // Stock and Sold info
                  Row(
                    children: [
                      Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${widget.product.stock}',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.product.stock > 0 ? Colors.grey[600] : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Sold: ${widget.product.countSold}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  // Auction details
                  if (widget.product.isAuction) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 32),
                    const Text(
                      'Auction Details',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.product.auctionIncrement != null)
                      Text(
                        'Bid Increment: Rp ${widget.product.auctionIncrement!.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 14.0),
                      ),
                    if (widget.product.auctionEndTime != null)
                      Text(
                        'Auction Ends: ${_formatDate(widget.product.auctionEndTime)}',
                        style: const TextStyle(fontSize: 14.0),
                      ),
                  ],

                  const SizedBox(height: 24),

                  // Edit and Delete buttons (only for sellers/admins)
                  if (_canEditOrDelete())
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement edit functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Edit feature coming soon!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo,
                              side: const BorderSide(color: Colors.indigo),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Confirm delete
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Product'),
                                  content: Text(
                                    'Are you sure you want to delete "${widget.product.title}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                try {
                                  final response = await request.post(
                                    "${AppConfig.baseUrl}/delete-flutter/${widget.product.id}/",
                                    {},
                                  );

                                  if (context.mounted) {
                                    if (response['status'] == 'success') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Product deleted successfully!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ProductEntryListPage(),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(response['message'] ?? 'Failed to delete product'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
