import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import 'mqtt_provider.dart';

class DeviceNotifier extends StateNotifier<List<DeviceModel>> {
  final Ref ref;

  DeviceNotifier(this.ref)
      : super([
          DeviceModel(
              id: '1',
              name: 'Living Room Light',
              topic: 'home/light1',
              icon: '💡'),
          DeviceModel(
              id: '2', name: 'Bedroom Fan', topic: 'home/fan1', icon: '🌀'),
          DeviceModel(
              id: '3',
              name: 'Front Door Lock',
              topic: 'home/lock1',
              icon: '🔒'),
          DeviceModel(
              id: '4', name: 'Air Conditioner', topic: 'home/ac1', icon: '❄️'),
        ]) {
    // Listen for incoming MQTT messages and update device state
    ref.read(mqttProvider.notifier).service.onDeviceMessageReceived =
        (deviceId, isOn) {
      state = state.map((d) {
        if (d.id == deviceId) {
          return d.copyWith(isOn: isOn);
        }
        return d;
      }).toList();
    };
  }

  void toggle(DeviceModel device) {
    final newState = !device.isOn;
    final mqttNotifier = ref.read(mqttProvider.notifier);
    mqttNotifier.service.publishCommand(device.id, newState);

    state = state.map((d) {
      if (d.id == device.id) return d.copyWith(isOn: newState);
      return d;
    }).toList();
  }

  void subscribeAll() {
    final mqttNotifier = ref.read(mqttProvider.notifier);
    mqttNotifier.service.subscribeToAllDevices();
  }
}

final deviceProvider =
    StateNotifierProvider<DeviceNotifier, List<DeviceModel>>((ref) {
  return DeviceNotifier(ref);
});
