import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/config.dart';
import '../models/portfolio.dart';
import '../models/stock.dart';
import 'trades_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  Portfolio? _portfolio;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Authentication token not found';
      });
      return;
    }

    try {
      final result = await ApiService.getPortfolio(token);

      if (!mounted) return;

      if (result['success']) {
        // Debug logging
        print('=== PORTFOLIO DATA DEBUG ===');
        print('Raw API response: ${result['data']}');
        print('Result type: ${result.runtimeType}');
        print('Data type: ${result['data'].runtimeType}');

        // The API response structure is: {success: true, data: {portfolio: {...}}}
        // But result['data'] is giving us the entire response again
        // Let's check the actual structure
        final responseData = result['data'];
        print('Response data keys: ${(responseData as Map).keys.toList()}');

        // If responseData has 'data' key, then we need to go deeper
        Map<String, dynamic> actualData;
        if (responseData.containsKey('data')) {
          actualData = responseData['data'] as Map<String, dynamic>;
          print('Found nested data structure');
        } else {
          actualData = responseData as Map<String, dynamic>;
          print('Using direct data structure');
        }

        print('Actual data keys: ${actualData.keys.toList()}');
        print('Portfolio key exists: ${actualData.containsKey('portfolio')}');

        // Extract portfolio data
        final portfolioData = actualData['portfolio'];
        print('Portfolio data: $portfolioData');

        if (portfolioData == null) {
          print('ERROR: portfolio data is null!');
          print('Available keys in actualData: ${actualData.keys.toList()}');
          setState(() {
            _error = 'Invalid portfolio data received from server';
            _isLoading = false;
          });
          return;
        }

        final portfolio = Portfolio.fromJson(portfolioData);
        print('Parsed portfolio:');
        print('  totalValue: ${portfolio.totalValue}');
        print('  totalInvestment: ${portfolio.totalInvestment}');
        print('  totalProfitLoss: ${portfolio.totalProfitLoss}');
        print('  cash: ${portfolio.cash}');
        print('  items count: ${portfolio.items.length}');

        setState(() {
          _portfolio = portfolio;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load portfolio';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading portfolio: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _testEndpoints() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final user = authProvider.user;

    final endpoints = {
      'health': Config.healthEndpoint,
      'portfolio': Config.portfolioEndpoint,
      'portfolio_buy': Config.portfolioBuyEndpoint,
      'portfolio_sell': Config.portfolioSellEndpoint,
    };

    String message = 'Endpoint Test Results:\n\n';
    message += 'Token: ${token?.substring(0, 20)}...\n';
    message += 'User ID: ${user?.id}\n\n';

    for (final entry in endpoints.entries) {
      try {
        Map<String, String> headers = {'Content-Type': 'application/json'};

        // Add auth header for portfolio endpoints
        if (entry.key.startsWith('portfolio') && token != null) {
          headers['Authorization'] = 'Bearer $token';
        }

        final response = await http
            .get(Uri.parse(entry.value), headers: headers)
            .timeout(Duration(seconds: 5));

        message +=
            '${entry.key}: ${response.statusCode} - ${response.body}\n\n';
      } catch (e) {
        message += '${entry.key}: Error - ${e.toString()}\n\n';
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Endpoint Test Results'),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
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
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPortfolio,
          ),
          if (Config.enableDebugLogs)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _testEndpoints,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Error Loading Portfolio',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPortfolio,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Always show portfolio summary, even if no holdings
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portfolio Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Portfolio Value
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Total Portfolio Value',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${_portfolio?.totalValue.toStringAsFixed(2) ?? '0.00'}',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Grid of portfolio metrics
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          'Total Investment',
                          '\$${_portfolio?.totalInvestment.toStringAsFixed(2) ?? '0.00'}',
                          Icons.trending_up,
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          'Available Cash',
                          '\$${_portfolio?.cash.toStringAsFixed(2) ?? '0.00'}',
                          Icons.account_balance_wallet,
                          AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          'Total P&L',
                          '\$${_portfolio?.totalProfitLoss.toStringAsFixed(2) ?? '0.00'}',
                          Icons.show_chart,
                          (_portfolio?.totalProfitLoss ?? 0) >= 0
                              ? AppTheme.profitGreen
                              : AppTheme.lossRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          'P&L %',
                          '${_portfolio?.totalProfitLossPercent.toStringAsFixed(2) ?? '0.00'}%',
                          Icons.percent,
                          (_portfolio?.totalProfitLoss ?? 0) >= 0
                              ? AppTheme.profitGreen
                              : AppTheme.lossRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Holdings Section
          if (_portfolio != null && _portfolio!.items.isNotEmpty) ...[
            Text('Holdings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ..._portfolio!.items.map(
              (item) => _buildHoldingCard(context, item),
            ),
          ] else ...[
            // No Holdings Message
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Holdings Yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start trading to build your portfolio',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingCard(BuildContext context, PortfolioItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Stock Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      item.symbol.isNotEmpty
                          ? item.symbol.substring(0, 1)
                          : '?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Stock Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.symbol,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.companyName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${item.currentPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.profitLossPercent >= 0 ? '+' : ''}${item.profitLossPercent.toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: item.profitLossPercent >= 0
                            ? AppTheme.profitGreen
                            : AppTheme.lossRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Holdings Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avg Price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${item.averagePrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Value',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${item.totalValue.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'P&L',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${item.profitLoss.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: item.profitLoss >= 0
                              ? AppTheme.profitGreen
                              : AppTheme.lossRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
