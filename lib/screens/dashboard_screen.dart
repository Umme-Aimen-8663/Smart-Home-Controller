import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_provider.dart';
import '../providers/mqtt_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/device_card.dart';
import 'settings_screen.dart';
import 'connection_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceProvider);
    final mqttStatus = ref.watch(mqttProvider);
    final themeMode = ref.watch(themeModeProvider);

    final activeCount = devices.where((d) => d.isOn).length;

    Color statusColor = mqttStatus == MqttStatus.connected
        ? Colors.green
        : mqttStatus == MqttStatus.connecting
            ? Colors.orange
            : Colors.red;

    String statusText = mqttStatus == MqttStatus.connected
        ? 'Connected'
        : mqttStatus == MqttStatus.connecting
            ? 'Connecting...'
            : 'Disconnected';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🏠 Smart Home',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Connection status badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: statusColor, size: 8),
                const SizedBox(width: 5),
                Text(statusText,
                    style: TextStyle(color: statusColor, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Theme toggle
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card at top
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade800, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$activeCount of ${devices.length} devices ON',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mqttStatus == MqttStatus.connected
                          ? 'Tap a device to control it'
                          : 'Not connected to broker',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Disconnected banner
          if (mqttStatus == MqttStatus.disconnected)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade700),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.red, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Broker disconnected',
                        style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const ConnectionScreen()),
                    ),
                    child: const Text('Reconnect',
                        style: TextStyle(color: Colors.amber)),
                  ),
                ],
              ),
            ),

          // Device grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return DeviceCard(device: devices[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
