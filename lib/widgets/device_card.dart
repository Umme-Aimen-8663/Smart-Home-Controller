import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../providers/device_provider.dart';
import '../providers/mqtt_provider.dart';
import '../screens/device_detail_screen.dart';

class DeviceCard extends ConsumerWidget {
  final DeviceModel device;
  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mqttStatus = ref.watch(mqttProvider);
    final isConnected = mqttStatus == MqttStatus.connected;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DeviceDetailScreen(device: device)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: device.isOn
              ? LinearGradient(
                  colors: [Colors.amber.shade700, Colors.orange.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Theme.of(context).cardColor,
                    Theme.of(context).cardColor,
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: device.isOn
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(device.icon, style: const TextStyle(fontSize: 36)),
                  Switch(
                    value: device.isOn,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.orange.shade800,
                    onChanged: isConnected
                        ? (_) =>
                            ref.read(deviceProvider.notifier).toggle(device)
                        : null,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                device.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: device.isOn ? Colors.white : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                device.isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 12,
                  color: device.isOn ? Colors.white70 : Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
