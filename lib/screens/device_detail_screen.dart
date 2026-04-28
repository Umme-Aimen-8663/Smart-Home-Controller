import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../providers/device_provider.dart';
import '../providers/mqtt_provider.dart';

class DeviceDetailScreen extends ConsumerWidget {
  final DeviceModel device;
  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceProvider);
    final current = devices.firstWhere((d) => d.id == device.id);
    final mqttStatus = ref.watch(mqttProvider);
    final isConnected = mqttStatus == MqttStatus.connected;

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Device icon with glow when ON
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: current.isOn
                      ? Colors.amber.shade700
                      : Colors.grey.shade800,
                  shape: BoxShape.circle,
                  boxShadow: current.isOn
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.6),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child:
                      Text(current.icon, style: const TextStyle(fontSize: 72)),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                current.name,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // MQTT Topic chip
              Chip(
                avatar: const Icon(Icons.tag, size: 16, color: Colors.amber),
                label:
                    Text(current.topic, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.amber.withValues(alpha: 0.1),
                side: const BorderSide(color: Colors.amber, width: 1),
              ),

              const SizedBox(height: 40),

              // ON/OFF Status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  current.isOn ? 'ON' : 'OFF',
                  key: ValueKey(current.isOn),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: current.isOn ? Colors.amber : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Big toggle switch
              Transform.scale(
                scale: 1.6,
                child: Switch.adaptive(
                  value: current.isOn,
                  activeThumbColor: Colors.amber,
                  onChanged: isConnected
                      ? (_) => ref.read(deviceProvider.notifier).toggle(current)
                      : null,
                ),
              ),

              const SizedBox(height: 32),

              // Publish info
              if (isConnected)
                Text(
                  'Publishes "${current.isOn ? "ON" : "OFF"}" → ${current.topic}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade800),
                  ),
                  child: const Text(
                    '⚠️ Not connected to broker',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
