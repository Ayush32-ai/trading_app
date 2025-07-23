import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/config.dart';
import '../models/trade.dart';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'create_trade_screen.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen>
    with AutomaticKeepAliveClientMixin {
  List<Trade> _trades = [];
  bool _isLoading = false;
  String? _error;

  // Filter variables
  String? _selectedSymbol;
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _symbolController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTrades();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh trades when screen becomes visible
    if (Config.enableDebugLogs) {
      print('=== TRADES SCREEN BECAME VISIBLE ===');
    }
  }

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  Future<void> _loadTrades() async {
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
      // First, test the basic trades endpoint
      final testResult = await ApiService.testTradesEndpoint(token);

      if (Config.enableDebugLogs) {
        print('=== TRADES ENDPOINT TEST ===');
        print('Success: ${testResult['success']}');
        print('Status Code: ${testResult['statusCode']}');
        print('Message: ${testResult['message']}');
        print('Full Response: ${testResult['fullResponse']}');
      }

      if (!testResult['success']) {
        setState(() {
          _error = 'Trades endpoint test failed: ${testResult['message']}';
          _isLoading = false;
        });
        return;
      }

      // If basic test passes, try with filters
      final result = await ApiService.getTradesWithFilters(
        token: token,
        symbol: _selectedSymbol,
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        limit: 50, // Limit to 50 trades for performance
      );

      if (!mounted) return;

      if (result['success']) {
        final data = result['data'];
        List<Trade> trades = [];

        if (Config.enableDebugLogs) {
          print('=== PROCESSING TRADES DATA ===');
          print('Raw data: $data');
          print('Data type: ${data.runtimeType}');
          print('Has trades key: ${data.containsKey('trades')}');
          print('Data keys: ${(data as Map).keys.toList()}');
          if (data.containsKey('data')) {
            print('Nested data keys: ${(data['data'] as Map).keys.toList()}');
            print(
              'Has nested trades: ${(data['data'] as Map).containsKey('trades')}',
            );
          }
        }

        // Handle nested data structure: data.data.trades
        Map<String, dynamic> actualData;
        if (data.containsKey('data')) {
          actualData = data['data'] as Map<String, dynamic>;
        } else {
          actualData = data as Map<String, dynamic>;
        }

        if (actualData['trades'] != null) {
          trades = (actualData['trades'] as List)
              .map((tradeJson) => Trade.fromJson(tradeJson))
              .toList();
        } else if (data is List) {
          trades = data.map((tradeJson) => Trade.fromJson(tradeJson)).toList();
        }

        if (Config.enableDebugLogs) {
          print('=== PARSED TRADES ===');
          print('Number of trades: ${trades.length}');
          for (int i = 0; i < trades.length; i++) {
            print('Trade $i: ${trades[i]}');
          }
          print('=== SETTING STATE ===');
          print('Current mounted state: $mounted');
        }

        if (mounted) {
          setState(() {
            _trades = trades;
            _isLoading = false;
          });

          if (Config.enableDebugLogs) {
            print('=== STATE UPDATED ===');
            print('Trades list length after setState: ${_trades.length}');
          }
        }
      } else {
        if (Config.enableDebugLogs) {
          print('=== API ERROR ===');
          print('Error message: ${result['message']}');
        }
        setState(() {
          _error = result['message'] ?? 'Failed to load trades';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('=== EXCEPTION ===');
        print('Exception: $e');
        print('Exception type: ${e.runtimeType}');
      }
      if (!mounted) return;
      setState(() {
        _error = 'Error loading trades: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Trades'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Symbol filter
              TextField(
                controller: _symbolController,
                decoration: const InputDecoration(
                  labelText: 'Symbol (e.g., AAPL)',
                  hintText: 'Leave empty for all symbols',
                ),
              ),
              const SizedBox(height: 16),

              // Type filter
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Trade Type'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(value: 'buy', child: Text('Buy')),
                  DropdownMenuItem(value: 'sell', child: Text('Sell')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Start Date',
                      ),
                    ),
                  ),
                  const Text('to'),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'End Date',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedSymbol = null;
                _selectedType = null;
                _startDate = null;
                _endDate = null;
                _symbolController.clear();
              });
              Navigator.of(context).pop();
              _loadTrades();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedSymbol = _symbolController.text.trim().isEmpty
                    ? null
                    : _symbolController.text.trim().toUpperCase();
              });
              Navigator.of(context).pop();
              _loadTrades();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _testTradesEndpoints() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final user = authProvider.user;

    final endpoints = {
      'trades': Config.tradesEndpoint,
      'trades_with_auth': '${Config.tradesEndpoint} (with auth)',
      'health': Config.healthEndpoint,
    };

    String message = 'Trades Endpoint Test Results:\n\n';
    message += 'Token: ${token?.substring(0, 20)}...\n';
    message += 'User ID: ${user?.id}\n\n';

    for (final entry in endpoints.entries) {
      try {
        Map<String, String> headers = {'Content-Type': 'application/json'};

        // Add auth header for trades endpoints
        if (entry.key.contains('trades') && token != null) {
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
          title: const Text('Trades Endpoint Test Results'),
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
        title: const Text('Trade History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTrades,
          ),
          if (Config.enableDebugLogs)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _testTradesEndpoints,
            ),
          if (Config.enableDebugLogs)
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Debug Info'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trades count: ${_trades.length}'),
                        Text('Is loading: $_isLoading'),
                        Text('Error: ${_error ?? 'None'}'),
                        Text('Selected symbol: ${_selectedSymbol ?? 'None'}'),
                        Text('Selected type: ${_selectedType ?? 'None'}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTradeScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (Config.enableDebugLogs) {
      print('=== BUILDING TRADES BODY ===');
      print('Is loading: $_isLoading');
      print('Error: $_error');
      print('Trades count: ${_trades.length}');
      print('Selected symbol: $_selectedSymbol');
      print('Selected type: $_selectedType');
    }

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
              'Error Loading Trades',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadTrades, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_trades.isEmpty) {
      if (Config.enableDebugLogs) {
        print('=== SHOWING EMPTY STATE ===');
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No Trades Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start trading to see your trade history here',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTrades,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    if (Config.enableDebugLogs) {
      print('=== SHOWING TRADES LIST ===');
      print('Trades to display: ${_trades.length}');
    }

    return Column(
      children: [
        // Active filters display
        if (_selectedSymbol != null ||
            _selectedType != null ||
            _startDate != null ||
            _endDate != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildFilterText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSymbol = null;
                      _selectedType = null;
                      _startDate = null;
                      _endDate = null;
                      _symbolController.clear();
                    });
                    _loadTrades();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),

        // Trades list with pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTrades,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _trades.length,
              itemBuilder: (context, index) {
                final trade = _trades[index];
                if (Config.enableDebugLogs) {
                  print('Building trade card $index: ${trade.stockSymbol}');
                }
                return _buildTradeCard(trade);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _buildFilterText() {
    List<String> filters = [];

    if (_selectedSymbol != null) filters.add('Symbol: $_selectedSymbol');
    if (_selectedType != null)
      filters.add('Type: ${_selectedType!.toUpperCase()}');
    if (_startDate != null)
      filters.add(
        'From: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
      );
    if (_endDate != null)
      filters.add('To: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}');

    return filters.join(' • ');
  }

  Widget _buildTradeCard(Trade trade) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Trade type indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trade.isBuy
                        ? AppTheme.profitGreen
                        : AppTheme.lossRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trade.type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Symbol
                Text(
                  trade.stockSymbol,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // Total value
                Text(
                  trade.formattedTotalValue,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: trade.isBuy
                        ? AppTheme.profitGreen
                        : AppTheme.lossRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details row
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
                        trade.formattedQuantity,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                        'Price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trade.formattedPrice,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trade.formattedCreatedAt,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Trade ID (for debugging)
            if (Config.enableDebugLogs) ...[
              const SizedBox(height: 8),
              Text(
                'ID: ${trade.tradeId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],

            // Historical data indicators (if available)
            if (trade.hasHistoricalData) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Latest: \$${trade.latestPrice.toStringAsFixed(2)} | Vol: ${trade.latestVolume}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
