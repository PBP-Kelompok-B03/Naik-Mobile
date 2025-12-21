import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naik/widgets/left_drawer.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:naik/screens/menu.dart';
import 'package:naik/config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductFormPage extends StatefulWidget {
  final bool isAuctionEnabled;
  
  const ProductFormPage({
    super.key,
    this.isAuctionEnabled = false,
  });

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  String _title = "";
  int _price = 0;
  String _category = "Men's Shoes";
  int _stock = 1;
  bool _isLoading = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Auction fields
  bool _isAuction = false;
  int _auctionIncrement = 1000;
  int _auctionDuration = 24;

  @override
  void initState() {
    super.initState();
    _isAuction = widget.isAuctionEnabled;
    if (_isAuction) {
      _stock = 1;
    }
  }

  final List<String> _categories = [
    "Men's Shoes",
    "Women's Shoes",
    "Kids' Shoes",
    "Golf Shoes",
  ];

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create Product',
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const Text(
                      'CREATE PRODUCT',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your new drop with the Naik community',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Product Name
                    _buildLabel('PRODUCT NAME'),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: _buildInputDecoration('Enter product name'),
                      onChanged: (String value) {
                        setState(() {
                          _title = value;
                        });
                      },
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return "Product name cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Price
                    _buildLabel('PRICE (IDR)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: _buildInputDecoration('Enter price'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (String value) {
                        setState(() {
                          _price = int.tryParse(value) ?? 0;
                        });
                      },
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return "Price cannot be empty!";
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return "Price must be a valid positive number!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Category
                    _buildLabel('CATEGORY'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: _buildInputDecoration('Select category'),
                      initialValue: _category,
                      items: _categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _category = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Stock
                    _buildLabel(_isAuction ? 'STOCK (DISABLED FOR AUCTIONS)' : 'STOCK'),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: _buildInputDecoration(_isAuction ? 'Stock set to 1 for auctions' : 'Enter stock quantity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      initialValue: _isAuction ? '1' : '1',
                      enabled: !_isAuction,
                      onChanged: (String value) {
                        setState(() {
                          _stock = int.tryParse(value) ?? 1;
                        });
                      },
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return "Stock cannot be empty!";
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 0) {
                          return "Stock must be a valid number!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Auction Option
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _isAuction,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isAuction = value ?? false;
                                    if (_isAuction) {
                                      _stock = 1;
                                    }
                                  });
                                },
                                activeColor: Colors.blue[700],
                              ),
                              const Text(
                                'Sell as Auction',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          if (_isAuction) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Note: Product price will be used as starting bid price',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Auction Increment
                            _buildLabel('MINIMUM BID INCREMENT (IDR)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              decoration: _buildInputDecoration('e.g., 1000'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              initialValue: '1000',
                              onChanged: (String value) {
                                setState(() {
                                  _auctionIncrement = int.tryParse(value) ?? 1000;
                                });
                              },
                              validator: (String? value) {
                                if (_isAuction && (value == null || value.isEmpty)) {
                                  return "Auction increment cannot be empty!";
                                }
                                if (_isAuction && value != null) {
                                  final parsed = int.tryParse(value);
                                  if (parsed == null || parsed <= 0) {
                                    return "Auction increment must be a valid positive number!";
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Auction Duration
                            _buildLabel('AUCTION DURATION (HOURS)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              decoration: _buildInputDecoration('e.g., 24'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              initialValue: '24',
                              onChanged: (String value) {
                                setState(() {
                                  _auctionDuration = int.tryParse(value) ?? 24;
                                });
                              },
                              validator: (String? value) {
                                if (_isAuction && (value == null || value.isEmpty)) {
                                  return "Auction duration cannot be empty!";
                                }
                                if (_isAuction && value != null) {
                                  final parsed = int.tryParse(value);
                                  if (parsed == null || parsed <= 0) {
                                    return "Auction duration must be a valid positive number!";
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Image Upload
                    _buildLabel('PRODUCT IMAGE (OPTIONAL)'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setState(() {
                            _imageFile = image;
                          });
                        }
                      },
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: _imageFile == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to select image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(
                                      File(_imageFile!.path),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black.withValues(alpha: 0.7),
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _imageFile = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Divider
                    Divider(color: Colors.grey[300], thickness: 1),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Publish Button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _isLoading = true);

                                      try {
                                        final response = await request.postJson(
                                          "${AppConfig.baseUrl}/create-flutter/",
                                          jsonEncode({
                                            "title": _title,
                                            "price": _price,
                                            "category": _category,
                                            "stock": _stock,
                                            "is_auction": _isAuction,
                                            if (_isAuction) ...{
                                              "auction_increment": _auctionIncrement,
                                              "auction_duration": _auctionDuration,
                                            },
                                          }),
                                        );

                                        print("Response received: $response");

                                        if (context.mounted) {
                                          if (response['status'] == 'success') {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Product successfully created!"),
                                                backgroundColor: Colors.black,
                                              ),
                                            );
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const MyHomePage(),
                                              ),
                                            );
                                          } else {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  'Error',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                content: Text(
                                                  response['message'] ??
                                                  'Something went wrong, please try again.',
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.black,
                                                    ),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        print("Error creating product: $e");
                                        if (context.mounted) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Error',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              content: Text(
                                                'Failed to create product: $e',
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.black,
                                                  ),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[400],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Publish Product',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey[700],
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}
