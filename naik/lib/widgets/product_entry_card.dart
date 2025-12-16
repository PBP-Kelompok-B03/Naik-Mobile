import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:naik/models/product_entry.dart';

class ProductEntryCard extends StatelessWidget {
  final ProductEntry product;
  final VoidCallback onTap;

  const ProductEntryCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: onTap,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: product.getImageUrl().isNotEmpty
                      ? Image.network(
                          // Use proxy on web to avoid CORS, direct URL on mobile
                          kIsWeb ? product.getProxiedImageUrl() : product.getImageUrl(),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // Print error for debugging
                            print('Image loading error for ${product.title}: $error');
                            print('Attempted URL: ${kIsWeb ? product.getProxiedImageUrl() : product.getImageUrl()}');
                            return Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 40),
                                    SizedBox(height: 8),
                                    Text('Image load failed', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.image, size: 50)),
                        ),
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // Price
                Text(
                  'Rp ${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),

                // Category
                Text('Category: ${product.category}'),
                const SizedBox(height: 6),

                // Stock info
                Row(
                  children: [
                    Text(
                      'Stock: ${product.stock}',
                      style: TextStyle(
                        color: product.stock > 0 ? Colors.black54 : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Sold: ${product.countSold}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Auction indicator
                if (product.isAuction)
                  const Text(
                    'AUCTION',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
