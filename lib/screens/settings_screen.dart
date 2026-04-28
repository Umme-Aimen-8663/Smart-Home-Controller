import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/storage_service.dart';
import '../providers/mqtt_provider.dart';
import '../providers/theme_provider.dart';
import 'connection_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _brokerCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService().loadBrokerSettings();
    setState(() {
      _brokerCtrl.text = settings['brokerUrl'];
      _portCtrl.text = settings['port'].toString();
      _clientCtrl.text = settings['clientId'];
    });
  }

  @override
  void dispose() {
    _brokerCtrl.dispose();
    _portCtrl.dispose();
    _clientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final mqttStatus = ref.watch(mqttProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Broker Settings Section ---
            _sectionTitle('Broker Settings'),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Broker URL',
              controller: _brokerCtrl,
              icon: Icons.dns,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              label: 'Port',
              controller: _portCtrl,
              icon: Icons.settings_input_antenna,
              isNumber: true,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              label: 'Client ID',
              controller: _clientCtrl,
              icon: Icons.perm_identity,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await StorageService().saveBrokerSettings(
                    brokerUrl: _brokerCtrl.text.trim(),
                    port: int.tryParse(_portCtrl.text.trim()) ?? 1883,
                    clientId: _clientCtrl.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Settings saved!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- Appearance Section ---
            _sectionTitle('Appearance'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Toggle light / dark theme'),
              secondary: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Colors.amber),
              value: themeMode == ThemeMode.dark,
              activeThumbColor: Colors.amber,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).state =
                    val ? ThemeMode.dark : ThemeMode.light;
              },
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // --- Connection Section ---
            _sectionTitle('Connection'),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(
                Icons.circle,
                color: mqttStatus == MqttStatus.connected
                    ? Colors.green
                    : Colors.red,
                size: 14,
              ),
              title: Text(
                mqttStatus == MqttStatus.connected
                    ? 'Connected to broker'
                    : 'Disconnected',
              ),
              subtitle: Text(_brokerCtrl.text),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.wifi_off, color: Colors.red),
                label: const Text('Disconnect & Go Back',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  ref.read(mqttProvider.notifier).disconnect();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.amber),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.amber, width: 1.5),
        ),
      ),
    );
  }
}
