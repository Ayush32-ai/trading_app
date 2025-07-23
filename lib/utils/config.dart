import 'dart:io';

class Config {
  // API Configuration
  static String get apiBaseUrl {
    // Use Railway deployment URL
    return 'https://ayyy-production.up.railway.app';
  }

  // Timeout configuration
  static const int requestTimeout = 15; // increased timeout
  static const int connectionTimeout = 10; // increased timeout

  // App configuration
  static const String appName = 'Trading App';
  static const String appVersion = '1.0.0';

  // Feature flags
  static const bool enableMockData = true; // Set to false when backend is ready
  static const bool enableDebugLogs = true;

  // API Endpoints
  static String get signupEndpoint => '$apiBaseUrl/api/v1/auth/signup';
  static String get loginEndpoint => '$apiBaseUrl/api/v1/auth/login';
  static String get meEndpoint => '$apiBaseUrl/api/v1/auth/me';
  static String get healthEndpoint => '$apiBaseUrl/health';

  // Portfolio endpoints
  static String get portfolioEndpoint => '$apiBaseUrl/api/v1/portfolio';
  static String get portfolioSummaryEndpoint =>
      '$apiBaseUrl/api/v1/portfolio/summary';
  static String get portfolioBuyEndpoint => '$apiBaseUrl/api/v1/portfolio/buy';
  static String get portfolioSellEndpoint =>
      '$apiBaseUrl/api/v1/portfolio/sell';
  static String getPortfolioHoldingsEndpoint(String symbol) =>
      '$apiBaseUrl/api/v1/portfolio/holdings/$symbol';

  // Trades endpoints
  static String get tradesEndpoint {
    final endpoint = '$apiBaseUrl/api/v1/trades';
    if (enableDebugLogs) {
      print('Trades endpoint URL: $endpoint');
    }
    return endpoint;
  }

  static String getUserProfileEndpoint(String userId) =>
      '$apiBaseUrl/api/users/$userId';
  static String updateUserProfileEndpoint(String userId) =>
      '$apiBaseUrl/api/users/$userId';
}
