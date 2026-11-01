import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient criarClienteMqtt(String host, int porta, String id) {
  final cliente = MqttServerClient.withPort('ws://$host', id, porta);
  cliente.useWebSocket = true;

  return cliente;
}
