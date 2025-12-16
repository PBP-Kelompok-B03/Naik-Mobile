import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:naik/models/product_entry.dart';
import 'package:naik/widgets/left_drawer.dart';
import 'package:naik/screens/product_detail.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:naik/config/app_config.dart';

class ProductEntryListPage extends StatefulWidget {
  const ProductEntryListPage({super.key});

  @override
  State<ProductEntryListPage> createState() => _ProductEntryListPageState();
}

class _ProductEntryListPageState extends State<ProductEntryListPage> {
  // All products from backend
  List<ProductEntry> allProducts = [];
  // Filtered products
  List<ProductEntry> filteredProducts = [];
  // Products to display (with pagination)
  List<ProductEntry> displayedProducts = [];

  // Pagination
  static const int itemsPerPage = 10;
  int currentPage = 1;

  // Loading state
  bool isLoading = true;
  String? errorMessage;

  // Filter states
  String searchQuery = '';
  String selectedCategory = '';
  double? minPrice;
  double? maxPrice;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch products when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = context.read<CookieRequest>();
      fetchProducts(request);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts(CookieRequest request) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await request.get(AppConfig.productJsonEndpoint);

      List<ProductEntry> products = [];
      for (var d in response) {
        if (d != null) {
          products.add(ProductEntry.fromJson(d));
        }
      }

      setState(() {
        allProducts = products;
        isLoading = false;
        applyFilters();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void applyFilters() {
    setState(() {
      filteredProducts = allProducts.where((product) {
        // Search filter
        bool matchesSearch = searchQuery.isEmpty ||
            product.title.toLowerCase().contains(searchQuery.toLowerCase());

        // Category filter
        bool matchesCategory = selectedCategory.isEmpty ||
            product.category == selectedCategory;

        // Price filter
        bool matchesMinPrice = minPrice == null || product.price >= minPrice!;
        bool matchesMaxPrice = maxPrice == null || product.price <= maxPrice!;

        return matchesSearch && matchesCategory && matchesMinPrice && matchesMaxPrice;
      }).toList();

      // Reset pagination when filters change
      currentPage = 1;
      updateDisplayedProducts();
    });
  }

  void updateDisplayedProducts() {
    setState(() {
      int endIndex = currentPage * itemsPerPage;
      if (endIndex > filteredProducts.length) {
        endIndex = filteredProducts.length;
      }
      displayedProducts = filteredProducts.sublist(0, endIndex);
    });
  }

  void loadMore() {
    setState(() {
      currentPage++;
      updateDisplayedProducts();
    });
  }

  bool get hasMoreProducts => displayedProducts.length < filteredProducts.length;

  void clearFilters() {
    setState(() {
      searchQuery = '';
      selectedCategory = '';
      minPrice = null;
      maxPrice = null;
      searchController.clear();
      minPriceController.clear();
      maxPriceController.clear();
      applyFilters();
    });
  }

  void showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['', "Men's Shoes", "Women's Shoes", "Kids' Shoes"].map((category) {
              return ListTile(
                title: Text(category.isEmpty ? 'All Categories' : category),
                leading: Radio<String>(
                  value: category,
                  groupValue: selectedCategory,
                  activeColor: Colors.black,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value ?? '';
                      applyFilters();
                    });
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                    applyFilters();
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void showPriceFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Price Range (IDR)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: minPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Min Price',
                hintText: 'e.g., 100000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Max Price',
                hintText: 'e.g., 5000000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      minPrice = double.tryParse(minPriceController.text);
                      maxPrice = double.tryParse(maxPriceController.text);
                      applyFilters();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: const LeftDrawer(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading products',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
            children: [
              // Search and Filter Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    searchQuery = '';
                                    searchController.clear();
                                    applyFilters();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                          applyFilters();
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Filter Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: showCategoryFilter,
                            icon: const Icon(Icons.category, size: 18),
                            label: Text(
                              selectedCategory.isEmpty
                                  ? 'Category'
                                  : selectedCategory,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: selectedCategory.isEmpty
                                  ? Colors.black
                                  : Colors.white,
                              backgroundColor: selectedCategory.isEmpty
                                  ? Colors.white
                                  : Colors.black,
                              side: BorderSide(
                                color: selectedCategory.isEmpty
                                    ? Colors.grey.shade300
                                    : Colors.black,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: showPriceFilter,
                            icon: const Icon(Icons.attach_money, size: 18),
                            label: Text(
                              (minPrice != null || maxPrice != null)
                                  ? 'Price Range'
                                  : 'Price',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: (minPrice != null || maxPrice != null)
                                  ? Colors.white
                                  : Colors.black,
                              backgroundColor: (minPrice != null || maxPrice != null)
                                  ? Colors.black
                                  : Colors.white,
                              side: BorderSide(
                                color: (minPrice != null || maxPrice != null)
                                    ? Colors.black
                                    : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        if (selectedCategory.isNotEmpty ||
                            minPrice != null ||
                            maxPrice != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: clearFilters,
                            icon: const Icon(Icons.clear_all),
                            tooltip: 'Clear all filters',
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),

                    // Active Filters Chips
                    if (selectedCategory.isNotEmpty ||
                        minPrice != null ||
                        maxPrice != null)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: double.infinity,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (selectedCategory.isNotEmpty)
                              Chip(
                                label: Text('Category: $selectedCategory'),
                                onDeleted: () {
                                  setState(() {
                                    selectedCategory = '';
                                    applyFilters();
                                  });
                                },
                                backgroundColor: Colors.grey[200],
                                deleteIconColor: Colors.red,
                              ),
                            if (minPrice != null || maxPrice != null)
                              Chip(
                                label: Text(
                                  'Price: Rp ${minPrice?.toStringAsFixed(0) ?? '0'} - Rp ${maxPrice?.toStringAsFixed(0) ?? '∞'}',
                                ),
                                onDeleted: () {
                                  setState(() {
                                    minPrice = null;
                                    maxPrice = null;
                                    minPriceController.clear();
                                    maxPriceController.clear();
                                    applyFilters();
                                  });
                                },
                                backgroundColor: Colors.grey[200],
                                deleteIconColor: Colors.red,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Results count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Text(
                  '${filteredProducts.length} products found${displayedProducts.length < filteredProducts.length ? ' (showing ${displayedProducts.length})' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),

              // Product Grid
              Expanded(
                child: displayedProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 2;
                          if (constraints.maxWidth > 1200) {
                            crossAxisCount = 4;
                          } else if (constraints.maxWidth > 800) {
                            crossAxisCount = 3;
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.7,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: displayedProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = displayedProducts[index];
                                    return _buildProductCard(product);
                                  },
                                ),

                                // Load More Button
                                if (hasMoreProducts) ...[
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: loadMore,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 48,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      'LOAD MORE (${filteredProducts.length - displayedProducts.length} remaining)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
    );
  }

  Widget _buildProductCard(ProductEntry product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: product.getImageUrl().isNotEmpty
                    ? Image.network(
                        kIsWeb ? product.getProxiedImageUrl() : product.getImageUrl(),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 30, color: Colors.grey[400]),
                              const SizedBox(height: 4),
                              Text(
                                'Image unavailable',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Set timeouts to prevent hanging
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                            child: child,
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image, size: 40, color: Colors.grey),
                        ),
                      ),
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
