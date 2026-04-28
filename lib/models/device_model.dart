class DeviceModel {
  final String id;
  final String name;
  final String topic;
  final String icon;
  bool isOn;

  DeviceModel({
    required this.id,
    required this.name,
    required this.topic,
    required this.icon,
    this.isOn = false,
  });

  DeviceModel copyWith({bool? isOn}) {
    return DeviceModel(
      id: id,
      name: name,
      topic: topic,
      icon: icon,
      isOn: isOn ?? this.isOn,
    );
  }
}