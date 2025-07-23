import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/config.dart';
import '../models/trade.dart';

class CreateTradeScreen extends StatefulWidget {
  const CreateTradeScreen({super.key});

  @override
  State<CreateTradeScreen> createState() => _CreateTradeScreenState();
}

class _CreateTradeScreenState extends State<CreateTradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stockSymbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  String _selectedType = 'buy'; // Default to buy

  // Price prediction
  bool _isPredictingPrice = false;
  double? _predictedPrice;
  String? _predictionError;

  @override
  void dispose() {
    _stockSymbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _predictPrice() async {
    final symbol = _stockSymbolController.text.trim();
    if (symbol.isEmpty) {
      setState(() {
        _predictionError = 'Please enter a stock symbol first';
      });
      return;
    }

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
        final predictedPrice = (data['predictedPrice'] ?? data['price'] ?? 0.0)
            .toDouble();
        setState(() {
          _predictedPrice = predictedPrice;
          _priceController.text = predictedPrice.toStringAsFixed(2);
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

  Future<void> _createTrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final user = authProvider.user;

    if (token == null || user == null) {
      setState(() {
        _error = 'Authentication required';
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await ApiService.createTrade(
        token: token,
        userId: user.id,
        stockSymbol: _stockSymbolController.text.trim().toUpperCase(),
        type: _selectedType,
        quantity: int.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        // Optional: Add historical data if needed
        prices: [double.parse(_priceController.text)],
        volume: [int.parse(_quantityController.text)],
        indicators: [0.0], // Default indicator value
      );

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _successMessage = 'Trade created successfully!';
          _isLoading = false;
        });

        // Clear form
        _formKey.currentState!.reset();
        _stockSymbolController.clear();
        _quantityController.clear();
        _priceController.clear();
        setState(() {
          _selectedType = 'buy';
        });

        // Show success message for a few seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to create trade';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error creating trade: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trade'),
        actions: [
          if (Config.enableDebugLogs)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _testCreateTrade,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success message
              if (_successMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: AppTheme.successColor),
                        ),
                      ),
                    ],
                  ),
                ),

              // Error message
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),

              // Form fields
              Text(
                'Trade Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Stock Symbol
              TextFormField(
                controller: _stockSymbolController,
                decoration: const InputDecoration(
                  labelText: 'Stock Symbol',
                  hintText: 'e.g., AAPL, GOOGL, MSFT',
                  prefixIcon: Icon(Icons.trending_up),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Stock symbol is required';
                  }
                  if (value.trim().length < 1 || value.trim().length > 10) {
                    return 'Stock symbol must be 1-10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Trade Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Trade Type',
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
                items: const [
                  DropdownMenuItem(value: 'buy', child: Text('Buy')),
                  DropdownMenuItem(value: 'sell', child: Text('Sell')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Trade type is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Number of shares',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Quantity must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per Share',
                  hintText: 'e.g., 150.50',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Price must be a positive number';
                  }
                  return null;
                },
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
                            'AI Price Prediction',
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
                                  : _predictPrice,
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
              const SizedBox(height: 24),

              // Total calculation
              if (_quantityController.text.isNotEmpty &&
                  _priceController.text.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trade Summary',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Value:'),
                            Text(
                              _calculateTotal(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
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
                      : const Text(
                          'Create Trade',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateTotal() {
    try {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final total = quantity * price;
      return '\$${total.toStringAsFixed(2)}';
    } catch (e) {
      return '\$0.00';
    }
  }

  Future<void> _testCreateTrade() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final user = authProvider.user;

    if (token == null || user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Failed'),
          content: const Text('Authentication required for testing'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Test with sample data
    final result = await ApiService.createTrade(
      token: token,
      userId: user.id,
      stockSymbol: 'TEST',
      type: 'buy',
      quantity: 10,
      price: 100.0,
      prices: [100.0],
      volume: [10],
      indicators: [0.0],
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result['success'] ? 'Test Success' : 'Test Failed'),
        content: Text(result['message'] ?? 'No message'),
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
