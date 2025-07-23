import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _token != null;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    clearError();

    try {
      final result = await ApiService.login(email: email, password: password);

      if (result['success']) {
        final data = result['data'];

        // Debug: Print the response data to understand the structure
        print('Login response data: $data');

        // Extract token from the response (backend returns it at root level)
        _token = data['token'];
        print('Stored token: $_token');

        if (_token == null) {
          setError('No authentication token received from server');
          setLoading(false);
          return false;
        }

        // Extract user data from the nested 'user' object
        final userData = data['user'];

        if (userData == null) {
          setError('No user data received from server');
          setLoading(false);
          return false;
        }

        _user = User.fromJson(userData);

        setLoading(false);
        return true;
      } else {
        // Check if it's a server error (500) and provide more helpful message
        if (result['message']?.contains('Server error') == true) {
          setError(
            'Server is experiencing issues. This might be due to:\n'
            '• Database connection problems\n'
            '• Invalid API endpoint configuration\n'
            '• Backend service not properly deployed\n'
            '• Missing environment variables',
          );
        } else {
          setError(result['message']);
        }
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Login failed. Please try again.');
      setLoading(false);
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    setLoading(true);
    clearError();

    try {
      final result = await ApiService.signup(
        name: name,
        email: email,
        password: password,
      );

      if (result['success']) {
        final data = result['data'];

        // Debug: Print the response data to understand the structure
        print('Signup response data: $data');
        print('Signup response data type: ${data.runtimeType}');
        print('Signup response keys: ${data.keys.toList()}');

        // Extract token from the response (backend returns it at root level)
        _token = data['token'];
        print('Stored token: $_token');

        if (_token == null) {
          setError('No authentication token received from server');
          setLoading(false);
          return false;
        }

        // Extract user data from the nested 'user' object
        final userData = data['user'];
        print('User data to parse: $userData');

        if (userData == null) {
          setError('No user data received from server');
          setLoading(false);
          return false;
        }

        _user = User.fromJson(userData);

        if (_token == null) {
          setError('No authentication token received from server');
          setLoading(false);
          return false;
        }

        setLoading(false);
        return true;
      } else {
        setError(result['message']);
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Network error. Please check your connection and try again.');
      setLoading(false);
      return false;
    }
  }

  void logout() {
    _user = null;
    _token = null;
    _error = null;
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
}
