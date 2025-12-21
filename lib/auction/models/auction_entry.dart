// lib/auction/models/auction_entry.dart
// Model untuk auction dan bid.

class AuctionEntry {
  final String id;
  final String title;
  final double price;
  final double currentBid;
  final String category;
  final String? thumbnail;
  final String? auctionEndTime;
  final double? auctionIncrement;
  final bool isActive;
  final String? sellerUsername;

  AuctionEntry({
    required this.id,
    required this.title,
    required this.price,
    required this.currentBid,
    required this.category,
    this.thumbnail,
    this.auctionEndTime,
    this.auctionIncrement,
    required this.isActive,
    this.sellerUsername,
  });

  factory AuctionEntry.fromJson(Map<String, dynamic> json) {
    return AuctionEntry(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      currentBid: (json['current_bid'] is num) ? (json['current_bid'] as num).toDouble() : 0.0,
      category: json['category'] ?? '',
      thumbnail: json['thumbnail'],
      auctionEndTime: json['auction_end_time'],
      auctionIncrement: (json['auction_increment'] is num) ? (json['auction_increment'] as num).toDouble() : null,
      isActive: json['is_active'] == true,
      sellerUsername: json['seller_username'],
    );
  }
}

class BidEntry {
  final String id;
  final String userUsername;
  final double amount;
  final String createdAt;

  BidEntry({
    required this.id,
    required this.userUsername,
    required this.amount,
    required this.createdAt,
  });

  factory BidEntry.fromJson(Map<String, dynamic> json) {
    return BidEntry(
      id: json['id']?.toString() ?? '',
      userUsername: json['user_username'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class AuctionDetail {
  final AuctionEntry product;
  final List<BidEntry> bids;
  final double currentHighestBid;
  final double minBid;
  final bool auctionActive;
  final bool isWinner;

  AuctionDetail({
    required this.product,
    required this.bids,
    required this.currentHighestBid,
    required this.minBid,
    required this.auctionActive,
    required this.isWinner,
  });

  factory AuctionDetail.fromJson(Map<String, dynamic> json) {
    var productJson = json['product'] as Map<String, dynamic>;
    var bidsJson = json['bids'] as List<dynamic>;
    
    return AuctionDetail(
      product: AuctionEntry.fromJson(productJson),
      bids: bidsJson.map((bid) => BidEntry.fromJson(bid)).toList(),
      currentHighestBid: (json['current_highest_bid'] is num) ? (json['current_highest_bid'] as num).toDouble() : 0.0,
      minBid: (json['min_bid'] is num) ? (json['min_bid'] as num).toDouble() : 0.0,
      auctionActive: json['auction_active'] == true,
      isWinner: json['is_winner'] == true,
    );
  }
}