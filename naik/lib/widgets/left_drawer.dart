import 'package:flutter/material.dart';
import 'package:naik/screens/menu.dart';
import 'package:naik/screens/productlist_form.dart';
import 'package:naik/screens/product_entry_list.dart';
import 'package:naik/screens/login.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:naik/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 50,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium Footwear Collection',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          _buildDrawerItem(
            context,
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
              );
            },
          ),

          _buildDrawerItem(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'Products',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductEntryListPage(),
                ),
              );
            },
          ),

          // Only show "Add Product" for sellers and admins
          if (_userRole == 'seller' || _userRole == 'admin')
            _buildDrawerItem(
              context,
              icon: Icons.add_box_outlined,
              title: 'Add Product',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductFormPage()),
                );
              },
            ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: Colors.grey[700], thickness: 1),
          ),

          // Logout
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            isLogout: true,
            onTap: () async {
              final response = await request.logout(
                "${AppConfig.baseUrl}/auth/logout/",
              );

              // Clear user data from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('username');
              await prefs.remove('role');
              await prefs.remove('user_id');

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
