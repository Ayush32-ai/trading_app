import 'stock.dart';

class PortfolioItem {
  final String symbol;
  final String companyName;
  final int quantity;
  final double averagePrice;
  final double totalInvested;
  final double currentPrice;
  final DateTime lastUpdated;

  PortfolioItem({
    required this.symbol,
    required this.companyName,
    required this.quantity,
    required this.averagePrice,
    required this.totalInvested,
    required this.currentPrice,
    required this.lastUpdated,
  });

  double get totalValue => currentPrice * quantity;
  double get profitLoss => totalValue - totalInvested;
  double get profitLossPercent =>
      totalInvested > 0 ? (profitLoss / totalInvested) * 100 : 0;

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      symbol: json['symbol'] ?? '',
      companyName: json['companyName'] ?? '',
      quantity: json['quantity'] ?? 0,
      averagePrice: (json['averagePrice'] ?? 0.0).toDouble(),
      totalInvested: (json['totalInvested'] ?? 0.0).toDouble(),
      currentPrice: (json['currentPrice'] ?? json['averagePrice'] ?? 0.0)
          .toDouble(),
      lastUpdated: DateTime.parse(
        json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'companyName': companyName,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'totalInvested': totalInvested,
      'currentPrice': currentPrice,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class Portfolio {
  final List<PortfolioItem> items;
  final double totalValue;
  final double totalInvestment;
  final double totalProfitLoss;
  final double totalProfitLossPercent;
  final double cash;

  Portfolio({
    required this.items,
    required this.totalValue,
    required this.totalInvestment,
    required this.totalProfitLoss,
    required this.totalProfitLossPercent,
    required this.cash,
  });

  factory Portfolio.fromItems(List<PortfolioItem> items, {double cash = 0.0}) {
    double holdingsValue = 0;
    double totalInvestment = 0;

    for (var item in items) {
      holdingsValue += item.totalValue;
      totalInvestment += item.totalInvested;
    }

    double totalValue = holdingsValue + cash;
    double totalProfitLoss = holdingsValue - totalInvestment;
    double totalProfitLossPercent = totalInvestment > 0
        ? (totalProfitLoss / totalInvestment) * 100
        : 0;

    return Portfolio(
      items: items,
      totalValue: totalValue,
      totalInvestment: totalInvestment,
      totalProfitLoss: totalProfitLoss,
      totalProfitLossPercent: totalProfitLossPercent,
      cash: cash,
    );
  }

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    // Debug logging
    print('=== PORTFOLIO FROM JSON DEBUG ===');
    print('Input JSON: $json');
    print('JSON type: ${json.runtimeType}');
    print('JSON keys: ${json.keys.toList()}');

    // Handle backend response format
    List<PortfolioItem> items = [];

    if (json['holdings'] != null) {
      print('Holdings found: ${json['holdings']}');
      items = (json['holdings'] as List)
          .map((item) => PortfolioItem.fromJson(item))
          .toList();
    } else {
      print('No holdings found in JSON');
    }

    // Extract values with detailed logging
    final totalValueRaw = json['totalValue'];
    final totalInvestmentRaw = json['totalInvestment'];
    final totalGainLossRaw = json['totalGainLoss'];
    final cashRaw = json['cash'];

    print('Raw values from JSON:');
    print('  totalValue: $totalValueRaw (type: ${totalValueRaw.runtimeType})');
    print(
      '  totalInvestment: $totalInvestmentRaw (type: ${totalInvestmentRaw.runtimeType})',
    );
    print(
      '  totalGainLoss: $totalGainLossRaw (type: ${totalGainLossRaw.runtimeType})',
    );
    print('  cash: $cashRaw (type: ${cashRaw.runtimeType})');

    final totalValue = (totalValueRaw ?? 0.0).toDouble();
    final totalInvestment = (totalInvestmentRaw ?? 0.0).toDouble();
    final totalProfitLoss = (totalGainLossRaw ?? 0.0).toDouble();
    final cash = (cashRaw ?? 0.0).toDouble();

    // Calculate totalProfitLossPercent
    final totalProfitLossPercent = totalInvestment > 0
        ? (totalProfitLoss / totalInvestment) * 100
        : 0.0;

    print('Parsed values:');
    print('  totalValue: $totalValue');
    print('  totalInvestment: $totalInvestment');
    print('  totalProfitLoss: $totalProfitLoss');
    print('  cash: $cash');
    print('  totalProfitLossPercent: $totalProfitLossPercent');
    print('  items count: ${items.length}');

    return Portfolio(
      items: items,
      totalValue: totalValue,
      totalInvestment: totalInvestment,
      totalProfitLoss: totalProfitLoss,
      totalProfitLossPercent: totalProfitLossPercent,
      cash: cash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'holdings': items.map((item) => item.toJson()).toList(),
      'totalValue': totalValue,
      'totalInvestment': totalInvestment,
      'totalGainLoss': totalProfitLoss,
      'cash': cash,
    };
  }
}
