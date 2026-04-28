import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class MqttService {
  MqttClient? client;

  Function(String deviceId, bool isOn)? onDeviceMessageReceived;

  Future<bool> connect({
    required String brokerUrl,
    required int port,
    required String clientId,
  }) async {
    try {
      if (kIsWeb) {
        final connected = await _connectWeb(brokerUrl, clientId);
        if (connected) {
          _setupListeners();
          subscribeToAllDevices();
        }
        return connected;
      }

      final MqttClient mqttClient = kIsWeb
          ? MqttBrowserClient('ws://$brokerUrl:8083/mqtt', clientId)
          : MqttServerClient.withPort(brokerUrl, clientId, port);

      client = mqttClient;

      mqttClient.logging(on: true);
      mqttClient.keepAlivePeriod = 60;
      mqttClient.autoReconnect = true;
      mqttClient.onDisconnected = onDisconnected;
      mqttClient.onConnected = onConnected;
      mqttClient.onSubscribed = onSubscribed;

      final connMessage = MqttConnectMessage()
          .withProtocolName('MQTT')
          .withProtocolVersion(4)
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      mqttClient.connectionMessage = connMessage;

      if (kIsWeb) {
        print(
            '🔄 Connecting (WebSocket) to ws://$brokerUrl:8083/mqtt as $clientId');
      } else {
        print('🔄 Connecting to $brokerUrl:$port as $clientId');
      }
      await mqttClient.connect();

      if (mqttClient.connectionStatus?.state != MqttConnectionState.connected) {
        print('❌ MQTT connection failed: ${mqttClient.connectionStatus}');
        mqttClient.disconnect();
        return false;
      }

      print('✅ Connected to $brokerUrl');
      _setupListeners();
      subscribeToAllDevices();
      return true;
    } catch (e) {
      print('❌ MQTT connect exception: $e');
      client?.disconnect();
      return false;
    }
  }

  Future<bool> _connectWeb(String brokerUrl, String clientId) async {
    final endpoints = <String>[
      'ws://$brokerUrl:8083/mqtt',
      'wss://$brokerUrl:8084/mqtt',
    ];

    for (final endpoint in endpoints) {
      try {
        final endpointUri = Uri.parse(endpoint);
        final mqttClient = MqttBrowserClient(endpoint, clientId)
          ..port = endpointUri.hasPort ? endpointUri.port : 1883
          ..logging(on: true)
          ..keepAlivePeriod = 60
          ..autoReconnect = true
          ..websocketProtocols = MqttClientConstants.protocolsSingleDefault
          ..onDisconnected = onDisconnected
          ..onConnected = onConnected
          ..onSubscribed = onSubscribed;

        final connMessage = MqttConnectMessage()
            .withProtocolName('MQTT')
            .withProtocolVersion(4)
            .withClientIdentifier(clientId)
            .startClean()
            .withWillQos(MqttQos.atLeastOnce);

        mqttClient.connectionMessage = connMessage;
        mqttClient.setProtocolV311();

        print('🔄 Connecting (WebSocket) to $endpoint as $clientId');
        await mqttClient.connect();

        if (mqttClient.connectionStatus?.state ==
            MqttConnectionState.connected) {
          client = mqttClient;
          print('✅ Connected to $endpoint');
          return true;
        }

        print('❌ WebSocket connection failed: ${mqttClient.connectionStatus}');
        mqttClient.disconnect();
      } catch (e) {
        print('❌ WebSocket connect exception on $endpoint: $e');
      }
    }

    client?.disconnect();
    return false;
  }

  void _setupListeners() {
    client?.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      if (c == null || c.isEmpty) return;
      final recMess = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = c[0].topic;

      print("📥 Received: $topic → $payload");

      try {
        final parts = topic.split('/');
        if (parts.length > 2 && parts[0] == 'home' && parts[1] == 'devices') {
          final deviceId = parts[2];

          bool isOn = false;

          // Support MQTTX JSON payloads: {"power":true}, {"isOn":"ON"}, etc.
          try {
            final data = json.decode(payload);
            final dynamic powerValue = data is Map<String, dynamic>
                ? (data['power'] ?? data['isOn'] ?? data['state'])
                : data;
            isOn = _parsePowerValue(powerValue);
          } catch (_) {
            // Also support plain MQTTX payloads: ON/OFF, true/false, 1/0.
            isOn = _parsePowerValue(payload);
          }

          onDeviceMessageReceived?.call(deviceId, isOn);
        }
      } catch (e) {
        print("Parse error: $e");
      }
    });
  }

  bool _parsePowerValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'on' || normalized == 'true' || normalized == '1';
    }
    return false;
  }

  void subscribeToAllDevices() {
    final mqttClient = client;
    if (mqttClient == null ||
        mqttClient.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }
    mqttClient.subscribe('home/devices/#', MqttQos.atLeastOnce);
  }

  void publishCommand(String deviceId, bool isOn) {
    final mqttClient = client;
    if (mqttClient == null ||
        mqttClient.connectionStatus?.state != MqttConnectionState.connected) {
      print('❌ Cannot publish while disconnected');
      return;
    }

    final topic = 'home/devices/$deviceId/command';
    final payload = json.encode({"power": isOn});

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    mqttClient.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    print("📤 Sent to $deviceId: $isOn");
  }

  void onConnected() => print("🎉 onConnected callback");
  void onSubscribed(String topic) => print("📬 Subscribed: $topic");
  void onDisconnected() => print("❌ MQTT Disconnected");

  void disconnect() => client?.disconnect();
}
