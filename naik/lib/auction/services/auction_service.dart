// lib/auction/services/auction_service.dart
// Service untuk mengelola API auction.

import 'package:naik/auction/models/auction_entry.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class AuctionService {
  final String baseUrl;

  AuctionService(this.baseUrl);

  Future<List<AuctionEntry>> fetchAuctions(CookieRequest request) async {
    final response = await request.get('$baseUrl/auction/api/list/');
    List<AuctionEntry> listAuction = [];
    if (response != null && response is Map && response['auctions'] != null) {
      for (var d in response['auctions']) {
        try {
          listAuction.add(AuctionEntry.fromJson(Map<String, dynamic>.from(d)));
        } catch (e) {
          print("Failed parsing auction: $e");
        }
      }
    }
    return listAuction;
  }

  Future<AuctionDetail> fetchAuctionDetail(CookieRequest request, String productId) async {
    final response = await request.get('$baseUrl/auction/api/product/$productId/');
    if (response != null && response is Map) {
      return AuctionDetail.fromJson(Map<String, dynamic>.from(response));
    }
    throw Exception('Failed to load auction detail');
  }

  Future<Map<String, dynamic>> placeBid(CookieRequest request, String productId, double amount) async {
    final body = {'amount': amount.toString()};
    final response = await request.post('$baseUrl/auction/api/bid/$productId/', body);
    return response ?? {};
  }
}