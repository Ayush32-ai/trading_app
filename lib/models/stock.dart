class Stock {
  final String symbol;
  final String name;
  final String company;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double previousClose;
  final int volume;
  final double marketCap;
  final String sector;
  final String industry;

  Stock({
    required this.symbol,
    required this.name,
    required this.company,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.previousClose,
    required this.volume,
    required this.marketCap,
    required this.sector,
    required this.industry,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'],
      name: json['name'],
      company: json['company'],
      currentPrice: (json['currentPrice'] ?? 0.0).toDouble(),
      change: (json['change'] ?? 0.0).toDouble(),
      changePercent: (json['changePercent'] ?? 0.0).toDouble(),
      openPrice: (json['openPrice'] ?? 0.0).toDouble(),
      highPrice: (json['highPrice'] ?? 0.0).toDouble(),
      lowPrice: (json['lowPrice'] ?? 0.0).toDouble(),
      previousClose: (json['previousClose'] ?? 0.0).toDouble(),
      volume: json['volume'] ?? 0,
      marketCap: (json['marketCap'] ?? 0.0).toDouble(),
      sector: json['sector'] ?? '',
      industry: json['industry'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'company': company,
      'currentPrice': currentPrice,
      'change': change,
      'changePercent': changePercent,
      'openPrice': openPrice,
      'highPrice': highPrice,
      'lowPrice': lowPrice,
      'previousClose': previousClose,
      'volume': volume,
      'marketCap': marketCap,
      'sector': sector,
      'industry': industry,
    };
  }

  bool get isPositive => change >= 0;
  bool get isNegative => change < 0;
}
