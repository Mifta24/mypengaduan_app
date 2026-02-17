import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class FCMDebugScreen extends StatefulWidget {
  const FCMDebugScreen({super.key});

  @override
  State<FCMDebugScreen> createState() => _FCMDebugScreenState();
}

class _FCMDebugScreenState extends State<FCMDebugScreen> {
  String? _fcmToken;
  String? _savedToken;
  bool _isLoading = true;
  String? _error;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _logs.clear();
    });

    try {
      _addLog('🔍 Getting FCM token...');
      
      // Get current FCM token
      final token = await FirebaseMessaging.instance.getToken();
      _addLog('✅ FCM Token: ${token?.substring(0, 50)}...');
      
      // Get saved token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_token');
      _addLog('💾 Saved token: ${savedToken?.substring(0, 50) ?? 'None'}...');
      
      // Check if they match
      if (token == savedToken) {
        _addLog('✅ Tokens match!');
      } else {
        _addLog('⚠️ Tokens DO NOT match!');
      }

      setState(() {
        _fcmToken = token;
        _savedToken = savedToken;
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    debugPrint(message);
  }

  Future<void> _registerToken() async {
    if (_fcmToken == null) {
      _addLog('❌ No FCM token available');
      return;
    }

    _addLog('🔄 Registering token to backend...');
    
    try {
      final authService = AuthService();
      final notificationService = NotificationService(authService);
      
      final success = await notificationService.registerFCMToken(_fcmToken!);
      
      if (success) {
        _addLog('✅ Token registered successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token berhasil didaftarkan!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _addLog('❌ Failed to register token');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mendaftarkan token'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyToken() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token copied to clipboard!')),
      );
    }
  }

  Future<void> _testNotification() async {
    _addLog('🔔 Test Notification Info');
    _addLog('');
    _addLog('📋 CARA TEST:');
    _addLog('1. Copy FCM Token (tombol Copy di atas)');
    _addLog('2. Buka Firebase Console');
    _addLog('3. Cloud Messaging → Send test message');
    _addLog('4. Paste token dan kirim');
    _addLog('');
    _addLog('🔥 ATAU kirim dari backend:');
    _addLog('   php artisan tinker');
    _addLog('   \$fcm = new \\App\\Services\\FcmService();');
    _addLog('   \$fcm->sendToMultipleDevices(');
    _addLog('     [\'YOUR_TOKEN\'],');
    _addLog('     \'Test\', \'Hello from backend\'');
    _addLog('   );');
    _addLog('');
    _addLog('📱 ATAU buat complaint baru dari user!');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lihat debug logs untuk cara test!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Token Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FCM Token',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_fcmToken != null) ...[
                            Text(
                              _fcmToken!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _copyToken,
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _registerToken,
                                  icon: const Icon(Icons.send, size: 16),
                                  label: const Text('Register'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const Text('No FCM token available'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Saved Token Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saved Token (SharedPreferences)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _savedToken ?? 'No saved token',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Test Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testNotification,
                      icon: const Icon(Icons.notification_add),
                      label: const Text('Test Notification'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Logs Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debug Logs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _logs.map((log) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    log,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Instructions Card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Cara Test Notifikasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. Copy FCM Token\n'
                            '2. Buka Firebase Console\n'
                            '3. Cloud Messaging → Send test message\n'
                            '4. Paste token dan kirim\n'
                            '5. Atau buat complaint baru dari user',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
