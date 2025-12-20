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

  int quantity = 1;

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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
