import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _brokerKey = 'broker_url';
  static const _portKey = 'broker_port';
  static const _clientIdKey = 'client_id';

  Future<void> saveBrokerSettings({
    required String brokerUrl,
    required int port,
    required String clientId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_brokerKey, brokerUrl);
    await prefs.setInt(_portKey, port);
    await prefs.setString(_clientIdKey, clientId);
  }

  Future<Map<String, dynamic>> loadBrokerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final shortId =
        'smart_home_app_${DateTime.now().millisecondsSinceEpoch % 100000}';
    return {
      'brokerUrl': prefs.getString(_brokerKey) ?? 'broker.emqx.io',
      'port': prefs.getInt(_portKey) ?? 1883,
      'clientId': prefs.getString(_clientIdKey) ?? shortId,
    };
  }
}
