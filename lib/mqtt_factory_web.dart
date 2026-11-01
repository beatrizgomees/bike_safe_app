import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient criarClienteMqtt(String host, int porta, String id) =>
    MqttBrowserClient.withPort('ws://$host', id, porta);
