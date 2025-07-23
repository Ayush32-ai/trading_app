import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/stock.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final List<Stock> _watchlist = _getMockWatchlist();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Add to watchlist functionality
            },
          ),
        ],
      ),
      body: _watchlist.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _watchlist.length,
              itemBuilder: (context, index) {
                return _buildWatchlistItem(_watchlist[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Your watchlist is empty',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add stocks to your watchlist to track them',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Add stocks functionality
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Stocks'),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistItem(Stock stock) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            stock.symbol.substring(0, 2),
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
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
                    stock.company,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${stock.change >= 0 ? '+' : ''}\$${stock.change.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: stock.isPositive
                        ? AppTheme.profitGreen
                        : AppTheme.lossRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
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
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'trade':
                // Navigate to trading screen
                break;
              case 'remove':
                setState(() {
                  _watchlist.remove(stock);
                });
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'trade',
              child: Row(
                children: [
                  Icon(Icons.trending_up),
                  SizedBox(width: 8),
                  Text('Trade'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.remove_circle_outline),
                  SizedBox(width: 8),
                  Text('Remove from Watchlist'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to stock detail screen
        },
      ),
    );
  }

  static List<Stock> _getMockWatchlist() {
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
