import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Trade {
  final String tradeId;
  final String userId;
  final String stockSymbol;
  final int quantity;
  final double price;
  final DateTime createdAt;
  final List<double> prices;
  final List<int> volume;
  final List<double> indicators;

  // Latest price data (optional, for display purposes)
  final double? latestPrice;
  final int? latestVolume;

  Trade({
    required this.tradeId,
    required this.userId,
    required this.stockSymbol,
    required this.quantity,
    required this.price,
    required this.createdAt,
    required this.prices,
    required this.volume,
    required this.indicators,
    this.latestPrice,
    this.latestVolume,
  });

  // Getter for trade type (buy/sell)
  String get type => quantity >= 0 ? 'buy' : 'sell';

  // Check if this is a buy trade
  bool get isBuy => quantity >= 0;

  // Check if this is a sell trade
  bool get isSell => quantity < 0;

  // Formatted price string
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  // Formatted quantity string (absolute value for display)
  String get formattedQuantity => quantity.abs().toString();

  // Formatted total value string
  String get formattedTotalValue {
    final total = (quantity * price).abs();
    return '\$${total.toStringAsFixed(2)}';
  }

  // Formatted date string
  String get formattedCreatedAt => DateFormat('MMM dd, yyyy').format(createdAt);

  // Check if historical data is available
  bool get hasHistoricalData => latestPrice != null && latestVolume != null;

  // Factory method to create a Trade from JSON
  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      tradeId: json['tradeId'] ?? json['_id'] ?? '',
      userId: json['userId'],
      stockSymbol: json['stockSymbol'],
      quantity: json['quantity'] is int
          ? json['quantity']
          : (json['quantity'] as num).toInt(),
      price: json['price'] is double
          ? json['price']
          : (json['price'] as num).toDouble(),
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt']
          : DateTime.parse(json['createdAt']),
      prices: List<double>.from(
        json['prices']?.map((x) => x is double ? x : (x as num).toDouble()) ??
            [],
      ),
      volume: List<int>.from(
        json['volume']?.map((x) => x is int ? x : (x as num).toInt()) ?? [],
      ),
      indicators: List<double>.from(
        json['indicators']?.map(
              (x) => x is double ? x : (x as num).toDouble(),
            ) ??
            [],
      ),
      latestPrice: json['latestPrice']?.toDouble(),
      latestVolume: json['latestVolume']?.toInt(),
    );
  }

  // Convert Trade to JSON
  Map<String, dynamic> toJson() {
    return {
      'tradeId': tradeId,
      'userId': userId,
      'stockSymbol': stockSymbol,
      'quantity': quantity,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
      'prices': prices,
      'volume': volume,
      'indicators': indicators,
      if (latestPrice != null) 'latestPrice': latestPrice,
      if (latestVolume != null) 'latestVolume': latestVolume,
    };
  }

  // For debugging
  @override
  String toString() {
    return 'Trade(tradeId: $tradeId, userId: $userId, stockSymbol: $stockSymbol, quantity: $quantity, '
        'price: $price, createdAt: $createdAt, prices: $prices, volume: $volume, '
        'indicators: $indicators, latestPrice: $latestPrice, latestVolume: $latestVolume)';
  }

  // Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trade &&
        other.tradeId == tradeId &&
        other.userId == userId &&
        other.stockSymbol == stockSymbol &&
        other.quantity == quantity &&
        other.price == price &&
        other.createdAt == createdAt &&
        listEquals(other.prices, prices) &&
        listEquals(other.volume, volume) &&
        listEquals(other.indicators, indicators);
  }

  @override
  int get hashCode {
    return tradeId.hashCode ^
        userId.hashCode ^
        stockSymbol.hashCode ^
        quantity.hashCode ^
        price.hashCode ^
        createdAt.hashCode ^
        prices.hashCode ^
        volume.hashCode ^
        indicators.hashCode;
  }
}
