import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';

import 'config.dart';
import 'mqtt_factory.dart';

/// Tempo real: assina bikesafe/app/# no broker (a saída do MP).
///   app/acidente -> um acidente novo, já tratado
///   app/ultimos  -> mensagem retida com os últimos acidentes (chega ao conectar)
class MqttService {
  MqttService({
    required this.aoAcidente,
    required this.aoReceberUltimos,
    required this.aoMudarEstado,
  });

  final void Function(Map<String, dynamic> evento) aoAcidente;
  final void Function(List<Map<String, dynamic>> eventos) aoReceberUltimos;
  final void Function(String estado) aoMudarEstado;

  MqttClient? _cliente;

  Future<void> conectar() async {
    final id = 'bikesafe-app-${DateTime.now().millisecondsSinceEpoch}';
    final cliente = criarClienteMqtt(Config.host, Config.brokerPorta, id);

    cliente
      ..keepAlivePeriod = 30
      ..autoReconnect = true
      ..logging(on: false)
      ..onConnected = (() => aoMudarEstado('ao vivo'))
      ..onDisconnected = (() => aoMudarEstado('sem conexão com o broker'))
      ..onAutoReconnect = (() => aoMudarEstado('reconectando…'))
      ..onAutoReconnected = (() => aoMudarEstado('ao vivo'))
      ..connectionMessage = MqttConnectMessage().withClientIdentifier(id).startClean();

    _cliente = cliente;

    try {
      await cliente.connect();
    } catch (_) {
      cliente.disconnect();
      aoMudarEstado('sem conexão com o broker');
      return;
    }

    cliente.subscribe(Config.topicoApp, MqttQos.atLeastOnce);
    cliente.updates!.listen(_receber);
  }

  void _receber(List<MqttReceivedMessage<MqttMessage>> mensagens) {
    for (final m in mensagens) {
      try {
        final publicada = m.payload as MqttPublishMessage;
        final dado = jsonDecode(utf8.decode(publicada.payload.message));

        if (m.topic == Config.topicoAcidente && dado is Map) {
          aoAcidente(Map<String, dynamic>.from(dado));
        } else if (m.topic == Config.topicoUltimos && dado is List) {
          aoReceberUltimos([for (final e in dado) Map<String, dynamic>.from(e as Map)]);
        }
      } catch (_) {
        // mensagem fora do formato esperado: ignora
      }
    }
  }

  void desconectar() => _cliente?.disconnect();
}
