import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../models/stock.dart';
import 'trades_screen.dart';
import 'create_trade_screen.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  Stock? _selectedStock;
  bool _isBuying = true;
  bool _isExecutingTrade = false;
  bool _isPredictingPrice = false;
  double? _predictedPrice;
  String? _predictionError;
  final List<Stock> _popularStocks = _getPopularStocks();

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _predictPrice(String symbol) async {
    if (symbol.isEmpty) return;

    setState(() {
      _isPredictingPrice = true;
      _predictedPrice = null;
      _predictionError = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _predictionError = 'Authentication required';
        _isPredictingPrice = false;
      });
      return;
    }

    try {
      final result = await ApiService.predictPrice(
        token: token,
        stockSymbol: symbol.toUpperCase(),
        predictionData: {'timestamp': DateTime.now().toIso8601String()},
      );

      if (!mounted) return;

      if (result['success']) {
        final data = result['data'];
        setState(() {
          _predictedPrice = (data['predictedPrice'] ?? data['price'] ?? 0.0)
              .toDouble();
          _isPredictingPrice = false;
        });
      } else {
        setState(() {
          _predictionError = result['message'] ?? 'Failed to predict price';
          _isPredictingPrice = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _predictionError = 'Error predicting price: ${e.toString()}';
        _isPredictingPrice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TradesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTradeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Balance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${user?.balance.toStringAsFixed(2) ?? '0.00'}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Search Section
            Text(
              'Search Stocks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter stock symbol (e.g., AAPL)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedStock = null;
                    });
                  },
                ),
              ),
              onChanged: (value) {
                // Search functionality
                if (value.isNotEmpty) {
                  final stock = _popularStocks.firstWhere(
                    (s) => s.symbol.toLowerCase() == value.toLowerCase(),
                    orElse: () => _popularStocks.first,
                  );
                  setState(() {
                    _selectedStock = stock;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Popular Stocks
            Text(
              'Popular Stocks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _popularStocks.length,
                itemBuilder: (context, index) {
                  return _buildPopularStockCard(_popularStocks[index]);
                },
              ),
            ),
            const SizedBox(height: 24),

            // Trading Section
            if (_selectedStock != null) ...[
              Text(
                'Trade ${_selectedStock!.symbol}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Price Prediction Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Price Prediction',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (_isPredictingPrice)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_predictedPrice != null) ...[
                        Row(
                          children: [
                            Text(
                              'Predicted Price: ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '\$${_predictedPrice!.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (_predictionError != null) ...[
                        Text(
                          _predictionError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.errorColor),
                        ),
                        const SizedBox(height: 8),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isPredictingPrice
                                  ? null
                                  : () => _predictPrice(_selectedStock!.symbol),
                              icon: const Icon(Icons.psychology),
                              label: const Text('Predict Price'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _predictedPrice = null;
                                  _predictionError = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTradingCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPopularStockCard(Stock stock) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStock = stock;
        });
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.symbol,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${stock.currentPrice.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${stock.change >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: stock.isPositive
                        ? AppTheme.profitGreen
                        : AppTheme.lossRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTradingCard() {
    if (_selectedStock == null) return const SizedBox.shrink();

    final stock = _selectedStock!;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final totalCost = quantity * stock.currentPrice;
    final user = Provider.of<AuthProvider>(context).user;
    final canAfford = (user?.balance ?? 0) >= totalCost;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    stock.symbol.substring(0, 2),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.symbol,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        stock.company,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${stock.currentPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${stock.change >= 0 ? '+' : ''}\$${stock.change.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: stock.isPositive
                            ? AppTheme.profitGreen
                            : AppTheme.lossRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Buy/Sell Toggle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isBuying = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBuying
                          ? AppTheme.profitGreen
                          : AppTheme.textLight,
                      foregroundColor: _isBuying
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                    child: const Text('BUY'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isBuying = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isBuying
                          ? AppTheme.lossRed
                          : AppTheme.textLight,
                      foregroundColor: !_isBuying
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                    child: const Text('SELL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quantity Input
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(Icons.numbers),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),

            // Total Cost
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Cost:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '\$${totalCost.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Execute Trade Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    quantity > 0 &&
                        (_isBuying ? canAfford : true) &&
                        !_isExecutingTrade
                    ? _executeTrade
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBuying
                      ? AppTheme.profitGreen
                      : AppTheme.lossRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isExecutingTrade
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _isBuying
                            ? 'BUY ${stock.symbol}'
                            : 'SELL ${stock.symbol}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            if (_isBuying && !canAfford) ...[
              const SizedBox(height: 12),
              Text(
                'Insufficient balance for this trade',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _executeTrade() async {
    if (_selectedStock == null) return;

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) return;

    final totalCost = quantity * _selectedStock!.currentPrice;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      _showErrorDialog('Authentication token not found. Please log in again.');
      return;
    }

    if (_isBuying && (user?.balance ?? 0) < totalCost) {
      _showErrorDialog('Insufficient balance for this trade.');
      return;
    }

    setState(() {
      _isExecutingTrade = true;
    });

    try {
      if (user == null) {
        _showErrorDialog('User not found. Please log in again.');
        return;
      }

      final result = _isBuying
          ? await ApiService.buyStock(
              token: token,
              userId: user.id,
              symbol: _selectedStock!.symbol,
              quantity: quantity,
              price: _selectedStock!.currentPrice,
            )
          : await ApiService.sellStock(
              token: token,
              userId: user.id,
              symbol: _selectedStock!.symbol,
              quantity: quantity,
              price: _selectedStock!.currentPrice,
            );

      if (result['success']) {
        _showSuccessDialog(
          _isBuying ? 'Stock Purchased' : 'Stock Sold',
          _isBuying
              ? 'Successfully purchased $quantity shares of ${_selectedStock!.symbol}'
              : 'Successfully sold $quantity shares of ${_selectedStock!.symbol}',
        );

        // Reset form
        _quantityController.clear();
        setState(() {
          _selectedStock = null;
        });
      } else {
        _showErrorDialog(
          result['message'] ?? 'Trade failed. Please try again.',
        );
      }
    } catch (e) {
      _showErrorDialog('Error executing trade: ${e.toString()}');
    } finally {
      setState(() {
        _isExecutingTrade = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static List<Stock> _getPopularStocks() {
    return [
      Stock(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        company: 'Apple Inc.',
        currentPrice: 150.25,
        change: 2.50,
        changePercent: 1.69,
        openPrice: 148.00,
        highPrice: 151.00,
        lowPrice: 147.50,
        previousClose: 147.75,
        volume: 50000000,
        marketCap: 2500000000000,
        sector: 'Technology',
        industry: 'Consumer Electronics',
      ),
      Stock(
        symbol: 'GOOGL',
        name: 'Alphabet Inc.',
        company: 'Alphabet Inc.',
        currentPrice: 2750.00,
        change: -15.50,
        changePercent: -0.56,
        openPrice: 2765.00,
        highPrice: 2770.00,
        lowPrice: 2740.00,
        previousClose: 2765.50,
        volume: 1500000,
        marketCap: 1800000000000,
        sector: 'Technology',
        industry: 'Internet Services',
      ),
      Stock(
        symbol: 'TSLA',
        name: 'Tesla Inc.',
        company: 'Tesla Inc.',
        currentPrice: 850.75,
        change: 25.25,
        changePercent: 3.05,
        openPrice: 825.00,
        highPrice: 855.00,
        lowPrice: 820.00,
        previousClose: 825.50,
        volume: 25000000,
        marketCap: 850000000000,
        sector: 'Consumer Discretionary',
        industry: 'Automobiles',
      ),
      Stock(
        symbol: 'MSFT',
        name: 'Microsoft Corporation',
        company: 'Microsoft Corporation',
        currentPrice: 320.50,
        change: 5.25,
        changePercent: 1.67,
        openPrice: 315.00,
        highPrice: 322.00,
        lowPrice: 314.50,
        previousClose: 315.25,
        volume: 30000000,
        marketCap: 2400000000000,
        sector: 'Technology',
        industry: 'Software',
      ),
      Stock(
        symbol: 'AMZN',
        name: 'Amazon.com Inc.',
        company: 'Amazon.com Inc.',
        currentPrice: 135.75,
        change: -2.25,
        changePercent: -1.63,
        openPrice: 138.00,
        highPrice: 139.50,
        lowPrice: 135.00,
        previousClose: 138.00,
        volume: 40000000,
        marketCap: 1400000000000,
        sector: 'Consumer Discretionary',
        industry: 'Internet Retail',
      ),
    ];
  }
}
