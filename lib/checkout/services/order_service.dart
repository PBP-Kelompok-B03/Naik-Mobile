import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/order.dart';

class OrderService {
  static Future<List<Order>> fetchOrders(CookieRequest request) async {
    final response = await request.get(
      "https://raymundo-rafaelito-naik.pbp.cs.ui.ac.id/checkout/api/orders/",
    );

    return (response as List).map((json) => Order.fromJson(json)).toList();
  }
}
