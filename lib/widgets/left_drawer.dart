import 'package:flutter/material.dart';
import 'package:naik/screens/menu.dart';
import 'package:naik/screens/productlist_form.dart';
import 'package:naik/screens/product_entry_list.dart';
import 'package:naik/screens/login.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:naik/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naik/checkout/screens/order_list_page.dart';
// Import halaman Chat
import 'package:naik/chat/screens/chat_list_page.dart';
// Import halaman Auction
import 'package:naik/auction/screens/auction_list_page.dart';

class LeftDrawer extends StatefulWidget {
  const LeftDrawer({super.key});

  @override
  State<LeftDrawer> createState() => _LeftDrawerState();
}

class _LeftDrawerState extends State<LeftDrawer> {
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'buyer';
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A), // Dark theme background
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0B0B0B), // Header darker background
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 50,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
                const Padding(padding: EdgeInsets.all(10)),
                const Text(
                  "Platform Jual, Beli, dan Lelang Sepatu Terpercaya",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Home
          _buildDrawerItem(
            context,
            icon: Icons.home_outlined,
            title: 'Halaman Utama',
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyHomePage(),
                  ));
            },
          ),

          // Menu Tambah Produk (Contoh logika role, sesuaikan jika perlu)
          if (_userRole == 'seller' || _userRole == 'admin')
            _buildDrawerItem(
              context,
              icon: Icons.add_circle_outline,
              title: 'Tambah Produk',
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductFormPage(),
                    ));
              },
            ),
          
          // Menu Daftar Produk
          _buildDrawerItem(
            context,
            icon: Icons.list_alt,
            title: 'Daftar Produk',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductEntryListPage()),
              );
            },
          ),

          // Menu Daftar Pesanan
          if (_userRole == 'buyer' || _userRole == 'admin')
            _buildDrawerItem(
              context,
              icon: Icons.shopping_bag_outlined,
              title: 'Daftar Pesanan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderListPage()),
                );
              },
            ),

          // --- MENU AUCTION (BARU) ---
          _buildDrawerItem(
            context,
            icon: Icons.gavel,  // Icon palu lelang
            title: 'Auction',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuctionListPage(),
                ),
              );
            },
          ),
          // ------------------------

          // --- MENU CHAT (BARU) ---
          _buildDrawerItem(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'Chat',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatListPage(),
                ),
              );
            },
          ),
          // ------------------------

          // Menu Logout
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            isLogout: true,
            onTap: () async {
              final response = await request.logout(
                  "${AppConfig.baseUrl}/auth/logout/"); // Sesuaikan URL logout
              String message = response["message"];
              if (context.mounted) {
                if (response['status']) {
                  String uname = response["username"];
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$message See you again, $uname."),
                      backgroundColor: Colors.black,
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red[400] : Colors.grey[300],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red[400] : Colors.grey[300],
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.grey[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}