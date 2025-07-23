import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../utils/config.dart';

class ApiService {
  // Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers with authentication token
  static Map<String, String> _headersWithAuth(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Signup API call
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Validate input parameters (matching backend validation)
      if (name.trim().isEmpty) {
        return {'success': false, 'message': 'Name is required'};
      }
      if (email.trim().isEmpty) {
        return {'success': false, 'message': 'Email is required'};
      }
      if (password.isEmpty) {
        return {'success': false, 'message': 'Password is required'};
      }
      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters long',
        };
      }

      // Use trimmed values (matching backend)
      final trimmedName = name.trim();
      final trimmedEmail = email.toLowerCase().trim();

      // Generate username from email if not provided (matching backend logic)
      final finalUsername = username?.trim() ?? trimmedEmail.split('@')[0];

      // Single request format matching backend exactly
      final requestBody = {
        'name': trimmedName,
        'email': trimmedEmail,
        'password': password,
        'username': finalUsername,
      };

      if (Config.enableDebugLogs) {
        print('=== SIGNUP REQUEST ===');
        print('URL: ${Config.signupEndpoint}');
        print('Headers: $_headers');
        print('Request body: ${jsonEncode(requestBody)}');
      }

      final response = await http
          .post(
            Uri.parse(Config.signupEndpoint),
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(
            Duration(seconds: Config.requestTimeout),
            onTimeout: () {
              throw TimeoutException(
                'Request timed out after ${Config.requestTimeout} seconds',
              );
            },
          );

      if (Config.enableDebugLogs) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        // Enhanced error handling for debugging
        String errorMessage =
            data['message'] ??
            'Signup failed with status ${response.statusCode}';

        // Handle specific error cases
        if (response.statusCode == 400) {
          if (data['message']?.contains('Email already exists') == true) {
            errorMessage =
                'This email is already registered. Please use a different email or try logging in.';
          } else if (data['message']?.contains('Username already exists') ==
              true) {
            errorMessage =
                'This username is already taken. Please choose a different username.';
          } else if (data['message']?.contains('Password must be at least 6') ==
              true) {
            errorMessage = 'Password must be at least 6 characters long.';
          } else if (data['message']?.contains('required') == true) {
            errorMessage = 'Please fill in all required fields.';
          }
        } else if (response.statusCode == 500) {
          errorMessage =
              'Server error (500). This usually means:\n'
              '• Database connection issue\n'
              '• Missing environment variables (JWT_SECRET)\n'
              '• User model schema mismatch\n'
              '• Backend code error\n\n'
              'Original error: ${data['message'] ?? 'Unknown server error'}';
        }

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
          'responseData': data,
        };
      }
    } on SocketException catch (e) {
      if (Config.enableDebugLogs) {
        print('Socket Exception: $e');
      }
      return {
        'success': false,
        'message':
            'Cannot connect to server at ${Config.apiBaseUrl}. Please check:\n'
            '• Railway deployment is accessible\n'
            '• Your internet connection is stable\n'
            '• API endpoints are correct',
      };
    } on TimeoutException catch (e) {
      if (Config.enableDebugLogs) {
        print('Timeout Exception: $e');
      }
      return {
        'success': false,
        'message':
            'Request timed out. The server might be:\n'
            '• Too slow to respond\n'
            '• Overloaded\n'
            '• Not accessible from this network',
      };
    } on FormatException catch (e) {
      if (Config.enableDebugLogs) {
        print('Format Exception: $e');
      }
      return {
        'success': false,
        'message':
            'Invalid response from server. Please check if the server is returning valid JSON.',
      };
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('General Exception: $e');
      }
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Login API call
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input parameters (matching backend validation)
      if (email.trim().isEmpty && password.trim().isEmpty) {
        return {'success': false, 'message': 'Email and password are required'};
      }
      if (email.trim().isEmpty) {
        return {'success': false, 'message': 'Email is required'};
      }
      if (password.isEmpty) {
        return {'success': false, 'message': 'Password is required'};
      }

      // Use trimmed and lowercase email (matching backend)
      final trimmedEmail = email.toLowerCase().trim();

      if (Config.enableDebugLogs) {
        print('Attempting to login to: ${Config.loginEndpoint}');
        print(
          'Request body: ${jsonEncode({'email': trimmedEmail, 'password': password})}',
        );
        print('Request headers: $_headers');
      }

      final response = await http
          .post(
            Uri.parse(Config.loginEndpoint),
            headers: _headers,
            body: jsonEncode({'email': trimmedEmail, 'password': password}),
          )
          .timeout(
            Duration(seconds: Config.requestTimeout),
            onTimeout: () {
              throw TimeoutException(
                'Request timed out after ${Config.requestTimeout} seconds',
              );
            },
          );

      if (Config.enableDebugLogs) {
        print('Login response status: ${response.statusCode}');
        print('Login response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message':
              data['message'] ??
              'Login failed with status ${response.statusCode}',
        };
      }
    } on SocketException catch (e) {
      if (Config.enableDebugLogs) {
        print('Socket Exception: $e');
      }
      return {
        'success': false,
        'message':
            'Cannot connect to server at ${Config.apiBaseUrl}. Please check:\n'
            '• Railway deployment is accessible\n'
            '• Your internet connection is stable\n'
            '• API endpoints are correct',
      };
    } on TimeoutException catch (e) {
      if (Config.enableDebugLogs) {
        print('Timeout Exception: $e');
      }
      return {
        'success': false,
        'message':
            'Request timed out. The server might be:\n'
            '• Too slow to respond\n'
            '• Overloaded\n'
            '• Not accessible from this network',
      };
    } on FormatException catch (e) {
      if (Config.enableDebugLogs) {
        print('Format Exception: $e');
      }
      return {
        'success': false,
        'message':
            'Invalid response from server. Please check if the server is returning valid JSON.',
      };
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('General Exception: $e');
      }
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse(Config.getUserProfileEndpoint(userId)),
            headers: _headers,
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get user profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(Config.updateUserProfileEndpoint(userId)),
            headers: _headers,
            body: jsonEncode(updates),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Test connection to server
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      if (Config.enableDebugLogs) {
        print('Testing connection to: ${Config.healthEndpoint}');
      }

      final response = await http
          .get(Uri.parse(Config.healthEndpoint), headers: _headers)
          .timeout(Duration(seconds: Config.connectionTimeout));

      if (Config.enableDebugLogs) {
        print('Health check response status: ${response.statusCode}');
        print('Health check response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Server is accessible',
          'data': {'status': 'healthy'},
        };
      } else {
        return {
          'success': false,
          'message':
              'Server responded with status ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Connection test failed: $e');
      }
      return {
        'success': false,
        'message': 'Cannot connect to server: ${e.toString()}',
      };
    }
  }

  // Test health endpoint specifically
  static Future<Map<String, dynamic>> testHealthEndpoint() async {
    try {
      final response = await http
          .get(Uri.parse(Config.healthEndpoint), headers: _headers)
          .timeout(Duration(seconds: Config.connectionTimeout));

      final responseBody = response.body;

      return {
        'success': response.statusCode == 200,
        'message':
            'Health endpoint (${Config.healthEndpoint}) returned: '
            'Status ${response.statusCode} - $responseBody',
        'statusCode': response.statusCode,
        'body': responseBody,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Health endpoint test failed: ${e.toString()}',
      };
    }
  }

  // Test signup endpoint with OPTIONS method to check CORS
  static Future<Map<String, dynamic>> testSignupEndpoint() async {
    try {
      // Test OPTIONS request first (for CORS)
      final optionsResponse = await http
          .post(
            Uri.parse(Config.signupEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Request-Method': 'POST',
              'Access-Control-Request-Headers': 'Content-Type',
            },
          )
          .timeout(Duration(seconds: Config.connectionTimeout));

      return {
        'success': true,
        'message':
            'Signup endpoint (${Config.signupEndpoint}) is accessible. '
            'OPTIONS response: ${optionsResponse.statusCode} - ${optionsResponse.body}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Signup endpoint test failed: ${e.toString()}',
      };
    }
  }

  // Test backend with minimal data to identify the exact issue
  static Future<Map<String, dynamic>> testBackendWithMinimalData() async {
    try {
      final minimalData = {
        'name': 'Test User',
        'email': 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        'password': 'password123',
      };

      if (Config.enableDebugLogs) {
        print('=== TESTING BACKEND WITH MINIMAL DATA ===');
        print('URL: ${Config.signupEndpoint}');
        print('Data: ${jsonEncode(minimalData)}');
      }

      final response = await http
          .post(
            Uri.parse(Config.signupEndpoint),
            headers: _headers,
            body: jsonEncode(minimalData),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Response status: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'statusCode': response.statusCode,
        'message': data['message'] ?? 'No message in response',
        'data': data,
        'fullResponse': response.body,
      };
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Test failed: $e');
      }
      return {'success': false, 'message': 'Test failed: ${e.toString()}'};
    }
  }

  // Test connection with custom URL
  static Future<bool> testConnectionWithUrl(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: Config.connectionTimeout));

      return response.statusCode == 200;
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Connection test failed for $url: $e');
      }
      return false;
    }
  }

  // Portfolio API methods

  // Get portfolio
  static Future<Map<String, dynamic>> getPortfolio(String token) async {
    try {
      if (Config.enableDebugLogs) {
        print('Fetching portfolio from: ${Config.portfolioEndpoint}');
        print('Using token: $token');
        print('Authorization header: Bearer $token');
      }

      // Use GET request since backend expects JWT token in Authorization header
      final response = await http
          .get(
            Uri.parse(Config.portfolioEndpoint),
            headers: _headersWithAuth(token),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Portfolio response status: ${response.statusCode}');
        print('Portfolio response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get portfolio',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Portfolio fetch error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Portfolio fetch failed: ${e.toString()}',
        };
      }
    }
  }

  // Buy stock
  static Future<Map<String, dynamic>> buyStock({
    required String token,
    required String userId,
    required String symbol,
    required int quantity,
    required double price,
  }) async {
    try {
      if (Config.enableDebugLogs) {
        print('Buying stock at: ${Config.portfolioBuyEndpoint}');
        print('User ID: $userId');
      }

      final response = await http
          .post(
            Uri.parse(Config.portfolioBuyEndpoint),
            headers: _headersWithAuth(token),
            body: jsonEncode({
              'userId': userId,
              'symbol': symbol,
              'quantity': quantity,
              'price': price,
            }),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Buy response status: ${response.statusCode}');
        print('Buy response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to buy stock',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Buy stock error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Buy stock failed: ${e.toString()}',
        };
      }
    }
  }

  // Sell stock
  static Future<Map<String, dynamic>> sellStock({
    required String token,
    required String userId,
    required String symbol,
    required int quantity,
    required double price,
  }) async {
    try {
      if (Config.enableDebugLogs) {
        print('Selling stock at: ${Config.portfolioSellEndpoint}');
        print('User ID: $userId');
      }

      final response = await http
          .post(
            Uri.parse(Config.portfolioSellEndpoint),
            headers: _headersWithAuth(token),
            body: jsonEncode({
              'userId': userId,
              'symbol': symbol,
              'quantity': quantity,
              'price': price,
            }),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Sell response status: ${response.statusCode}');
        print('Sell response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to sell stock',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Sell stock error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Sell stock failed: ${e.toString()}',
        };
      }
    }
  }

  // Get holdings for a specific symbol
  static Future<Map<String, dynamic>> getHoldings({
    required String token,
    required String userId,
    required String symbol,
  }) async {
    try {
      final endpoint = Config.getPortfolioHoldingsEndpoint(symbol);

      if (Config.enableDebugLogs) {
        print('Getting holdings from: $endpoint');
        print('User ID: $userId');
      }

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: _headersWithAuth(token),
            body: jsonEncode({'userId': userId}),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Holdings response status: ${response.statusCode}');
        print('Holdings response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get holdings',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Get holdings error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Get holdings failed: ${e.toString()}',
        };
      }
    }
  }

  // Get portfolio summary
  static Future<Map<String, dynamic>> getPortfolioSummary(String token) async {
    try {
      if (Config.enableDebugLogs) {
        print(
          'Fetching portfolio summary from: ${Config.portfolioSummaryEndpoint}',
        );
        print('Using token: $token');
      }

      final response = await http
          .get(
            Uri.parse(Config.portfolioSummaryEndpoint),
            headers: _headersWithAuth(token),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Portfolio summary response status: ${response.statusCode}');
        print('Portfolio summary response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get portfolio summary',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Portfolio summary fetch error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Portfolio summary fetch failed: ${e.toString()}',
        };
      }
    }
  }

  // Get trades
  static Future<Map<String, dynamic>> getTrades(String token) async {
    try {
      if (Config.enableDebugLogs) {
        print('Fetching trades from: ${Config.tradesEndpoint}');
        print('Using token: $token');
      }

      final response = await http
          .get(
            Uri.parse(Config.tradesEndpoint),
            headers: _headersWithAuth(token),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Trades response status: ${response.statusCode}');
        print('Trades response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get trades',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Trades fetch error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Trades fetch failed: ${e.toString()}',
        };
      }
    }
  }

  // Get trades with filters
  static Future<Map<String, dynamic>> getTradesWithFilters({
    required String token,
    String? symbol,
    String? type, // 'buy' or 'sell'
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (symbol != null) queryParams['symbol'] = symbol;
      if (type != null) queryParams['type'] = type;
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse(
        Config.tradesEndpoint,
      ).replace(queryParameters: queryParams);

      if (Config.enableDebugLogs) {
        print('Fetching trades with filters from: $uri');
        print('Using token: $token');
        print('Query parameters: $queryParams');
      }

      final response = await http
          .get(uri, headers: _headersWithAuth(token))
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Trades with filters response status: ${response.statusCode}');
        print('Trades with filters response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get trades with filters',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Trades with filters fetch error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Trades with filters fetch failed: ${e.toString()}',
        };
      }
    }
  }

  // Test trades endpoint
  static Future<Map<String, dynamic>> testTradesEndpoint(String token) async {
    try {
      if (Config.enableDebugLogs) {
        print('Testing trades endpoint: ${Config.tradesEndpoint}');
        print('Using token: ${token.substring(0, 20)}...');
      }

      final response = await http
          .get(
            Uri.parse(Config.tradesEndpoint),
            headers: _headersWithAuth(token),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Trades endpoint test status: ${response.statusCode}');
        print('Trades endpoint test body: ${response.body}');
        print('Trades endpoint test headers: ${response.headers}');
      }

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': data['message'] ?? 'No message in response',
        'data': data,
        'fullResponse': response.body,
      };
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Trades endpoint test failed: $e');
      }
      return {'success': false, 'message': 'Trades endpoint test failed: $e'};
    }
  }

  // Create trade
  static Future<Map<String, dynamic>> createTrade({
    required String token,
    required String userId,
    required String stockSymbol,
    required String type, // 'buy' or 'sell'
    required int quantity,
    required double price,
    List<double>? prices,
    List<int>? volume,
    List<double>? indicators,
  }) async {
    try {
      if (Config.enableDebugLogs) {
        print('Creating trade at: ${Config.tradesEndpoint}');
        print('User ID: $userId');
        print('Stock Symbol: $stockSymbol');
        print('Type: $type');
        print('Quantity: $quantity');
        print('Price: $price');
      }

      final requestBody = {
        'userId': userId,
        'stockSymbol': stockSymbol,
        'type': type,
        'quantity': quantity,
        'price': price,
        'prices': prices ?? [],
        'volume': volume ?? [],
        'indicators': indicators ?? [],
      };

      final response = await http
          .post(
            Uri.parse(Config.tradesEndpoint),
            headers: _headersWithAuth(token),
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Create trade response status: ${response.statusCode}');
        print('Create trade response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create trade',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Create trade error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Create trade failed: ${e.toString()}',
        };
      }
    }
  }

  // Get trade by ID
  static Future<Map<String, dynamic>> getTradeById({
    required String token,
    required String tradeId,
  }) async {
    try {
      final endpoint = '${Config.tradesEndpoint}/$tradeId';

      if (Config.enableDebugLogs) {
        print('Getting trade by ID from: $endpoint');
        print('Trade ID: $tradeId');
      }

      final response = await http
          .get(Uri.parse(endpoint), headers: _headersWithAuth(token))
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Get trade by ID response status: ${response.statusCode}');
        print('Get trade by ID response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get trade',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Get trade by ID error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Get trade by ID failed: ${e.toString()}',
        };
      }
    }
  }

  // Delete trade
  static Future<Map<String, dynamic>> deleteTrade({
    required String token,
    required String tradeId,
  }) async {
    try {
      final endpoint = '${Config.tradesEndpoint}/$tradeId';

      if (Config.enableDebugLogs) {
        print('Deleting trade at: $endpoint');
        print('Trade ID: $tradeId');
      }

      final response = await http
          .delete(Uri.parse(endpoint), headers: _headersWithAuth(token))
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Delete trade response status: ${response.statusCode}');
        print('Delete trade response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete trade',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Delete trade error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Delete trade failed: ${e.toString()}',
        };
      }
    }
  }

  // Predict price
  static Future<Map<String, dynamic>> predictPrice({
    required String token,
    required String stockSymbol,
    Map<String, dynamic>? predictionData,
  }) async {
    try {
      final endpoint = '${Config.tradesEndpoint}/predict-price';

      if (Config.enableDebugLogs) {
        print('Predicting price at: $endpoint');
        print('Stock Symbol: $stockSymbol');
      }

      final requestBody = {'stockSymbol': stockSymbol, ...?predictionData};

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: _headersWithAuth(token),
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: Config.requestTimeout));

      if (Config.enableDebugLogs) {
        print('Predict price response status: ${response.statusCode}');
        print('Predict price response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to predict price',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Predict price error: $e');
      }

      if (e is SocketException) {
        return {
          'success': false,
          'message':
              'Network error: Unable to connect to server. Please check your internet connection.',
        };
      } else if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else if (e is FormatException) {
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      } else {
        return {
          'success': false,
          'message': 'Predict price failed: ${e.toString()}',
        };
      }
    }
  }

  // Health check method to test server connectivity
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      if (Config.enableDebugLogs) {
        print('Testing server health at: ${Config.healthEndpoint}');
      }

      final response = await http
          .get(Uri.parse(Config.healthEndpoint), headers: _headers)
          .timeout(
            Duration(seconds: Config.requestTimeout),
            onTimeout: () {
              throw TimeoutException(
                'Health check timed out after ${Config.requestTimeout} seconds',
              );
            },
          );

      if (Config.enableDebugLogs) {
        print('Health check status: ${response.statusCode}');
        print('Health check headers: ${response.headers}');
        print('Health check body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Server is healthy'};
      } else {
        return {
          'success': false,
          'message': 'Server returned status ${response.statusCode}',
        };
      }
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Health check failed: $e');
      }
      return {'success': false, 'message': 'Health check failed: $e'};
    }
  }

  // Simple test signup method for debugging
  static Future<Map<String, dynamic>> testSignup() async {
    try {
      final testData = {
        'name': 'Test User',
        'email': 'test@example.com',
        'password': 'password123',
      };

      if (Config.enableDebugLogs) {
        print('=== TEST SIGNUP ===');
        print('URL: ${Config.signupEndpoint}');
        print('Headers: $_headers');
        print('Test data: ${jsonEncode(testData)}');
      }

      final response = await http
          .post(
            Uri.parse(Config.signupEndpoint),
            headers: _headers,
            body: jsonEncode(testData),
          )
          .timeout(
            Duration(seconds: Config.requestTimeout),
            onTimeout: () {
              throw TimeoutException(
                'Test signup timed out after ${Config.requestTimeout} seconds',
              );
            },
          );

      if (Config.enableDebugLogs) {
        print('Test signup status: ${response.statusCode}');
        print('Test signup headers: ${response.headers}');
        print('Test signup body: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      if (Config.enableDebugLogs) {
        print('Test signup failed: $e');
      }
      return {'success': false, 'message': 'Test signup failed: $e'};
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
