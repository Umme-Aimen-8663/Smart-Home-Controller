import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mqtt_provider.dart';
import '../providers/device_provider.dart';
import '../core/services/storage_service.dart';
import 'dashboard_screen.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _brokerCtrl = TextEditingController(text: 'broker.emqx.io');
  final _portCtrl = TextEditingController(text: '1883');
  final _clientCtrl = TextEditingController(
      text: 'smart_home_app_${DateTime.now().millisecondsSinceEpoch % 100000}');

  @override
  void dispose() {
    _brokerCtrl.dispose();
    _portCtrl.dispose();
    _clientCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    await StorageService().saveBrokerSettings(
      brokerUrl: _brokerCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text.trim()) ?? 1883,
      clientId: _clientCtrl.text.trim(),
    );

    await ref.read(mqttProvider.notifier).connect();
    final status = ref.read(mqttProvider);

    if (status == MqttStatus.connected && mounted) {
      ref.read(deviceProvider.notifier).subscribeAll();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Connection failed. Check broker settings.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqttStatus = ref.watch(mqttProvider);
    final isConnecting = mqttStatus == MqttStatus.connecting;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.wifi, color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Connect to\nMQTT Broker',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your broker details below',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 48),
              _buildLabel('Broker URL'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _brokerCtrl,
                hint: 'broker.emqx.io',
                icon: Icons.dns,
              ),
              const SizedBox(height: 20),
              _buildLabel('Port'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _portCtrl,
                hint: '1883',
                icon: Icons.settings_input_antenna,
                isNumber: true,
              ),
              const SizedBox(height: 20),
              _buildLabel('Client ID'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _clientCtrl,
                hint: 'flutter_home_001',
                icon: Icons.perm_identity,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isConnecting ? null : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isConnecting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Connecting...',
                                style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Text(
                          'Connect',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Using free public broker: broker.emqx.io',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.amber),
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.amber, width: 1.5),
        ),
      ),
    );
  }
}
