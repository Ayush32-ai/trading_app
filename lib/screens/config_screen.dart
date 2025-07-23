import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  String _selectedConfig = 'vercel_deployment';
  bool _isTesting = false;
  bool _testResult = false;
  String _testMessage = '';

  final Map<String, String> _configurations = {
    'vercel_deployment':
        'https://nodejs-serverless-function-express-six-orpin-12.vercel.app/api',
    'localhost': 'http://localhost:5000/api',
    'android_emulator': 'http://10.0.2.2:5000/api',
    'physical_device': 'http://192.168.1.100:5000/api', // Replace with your IP
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Configuration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Configuration',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Select the appropriate configuration based on your setup:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // Configuration Options
            ..._configurations.entries.map(
              (entry) => _buildConfigOption(entry.key, entry.value),
            ),

            const SizedBox(height: 24),

            // Test Connection Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
              ),
            ),

            if (_testMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testResult
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult ? Icons.check_circle : Icons.error,
                      color: _testResult
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testMessage,
                        style: TextStyle(
                          color: _testResult
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Troubleshooting Section
            Text(
              'Troubleshooting',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTroubleshootingItem(
              'Vercel Deployment',
              'Use "vercel_deployment" for the live server on Vercel',
              Icons.cloud,
            ),
            _buildTroubleshootingItem(
              'For Android Emulator',
              'Use "android_emulator" if your backend is running on the host machine',
              Icons.phone_android,
            ),
            _buildTroubleshootingItem(
              'For Physical Device',
              'Use "physical_device" and replace the IP with your computer\'s IP address',
              Icons.phone_iphone,
            ),
            _buildTroubleshootingItem(
              'For Web/Desktop',
              'Use "localhost" if running the app on the same machine as the server',
              Icons.computer,
            ),
            _buildTroubleshootingItem(
              'Check Server',
              'Make sure your backend server is running on port 5000',
              Icons.dns,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigOption(String key, String url) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: RadioListTile<String>(
        title: Text(key.replaceAll('_', ' ').toUpperCase()),
        subtitle: Text(
          url,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: AppTheme.textSecondary,
          ),
        ),
        value: key,
        groupValue: _selectedConfig,
        onChanged: (value) {
          setState(() {
            _selectedConfig = value!;
            _testMessage = '';
          });
        },
      ),
    );
  }

  Widget _buildTroubleshootingItem(
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testMessage = '';
    });

    try {
      // Temporarily change the config for testing
      final testUrl = _configurations[_selectedConfig]!;
      final healthUrl = testUrl.replaceAll('/api', '/api/health');

      final response = await ApiService.testConnectionWithUrl(healthUrl);

      setState(() {
        _testResult = response;
        _testMessage = response
            ? 'Connection successful! Server is reachable.'
            : 'Connection failed. Please check your server configuration.';
      });
    } catch (e) {
      setState(() {
        _testResult = false;
        _testMessage = 'Test failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }
}
