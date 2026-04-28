import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/mqtt_service.dart';
import '../core/services/storage_service.dart';

enum MqttStatus { disconnected, connecting, connected }

class MqttNotifier extends StateNotifier<MqttStatus> {
  final MqttService _mqttService = MqttService();
  final StorageService _storageService = StorageService();

  MqttNotifier() : super(MqttStatus.disconnected);

  MqttService get service => _mqttService;

  Future<void> connect() async {
    state = MqttStatus.connecting;
    final settings = await _storageService.loadBrokerSettings();
    final savedClientId = (settings['clientId'] as String?)?.trim() ?? '';

    final success = await _mqttService.connect(
      brokerUrl: (settings['brokerUrl'] as String?)?.trim().isNotEmpty == true
          ? settings['brokerUrl'] as String
          : 'broker.emqx.io',
      port: settings['port'] is int ? settings['port'] as int : 1883,
      // If client ID is empty, create one so MQTTX and app can both connect.
      clientId: savedClientId.isNotEmpty
          ? savedClientId
          : 'flutter_home_${DateTime.now().millisecondsSinceEpoch}',
    );
    state = success ? MqttStatus.connected : MqttStatus.disconnected;
  }

  void disconnect() {
    _mqttService.disconnect();
    state = MqttStatus.disconnected;
  }
}

final mqttProvider = StateNotifierProvider<MqttNotifier, MqttStatus>((ref) {
  return MqttNotifier();
});
