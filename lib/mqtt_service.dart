import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';

import 'config.dart';
import 'mqtt_factory.dart';

class MqttService {
  MqttService({
    required this.aoAcidente,
    required this.aoReceberUltimos,
    required this.aoMudarEstado,
  });

  final void Function(Map<String, dynamic> evento) aoAcidente;
  final void Function(List<Map<String, dynamic>> eventos) aoReceberUltimos;

  final void Function(bool aoVivo, String? detalhe) aoMudarEstado;

  static const _intervaloTentativa = Duration(seconds: 15);

  MqttClient? _cliente;
  Timer? _timer;
  bool _tentando = false;
  bool _conectado = false;
  bool _encerrado = false;

  void iniciar() {
    _tentar();
    _timer = Timer.periodic(_intervaloTentativa, (_) {
      if (!_conectado) _tentar();
    });
  }

  void _marcar(bool aoVivo, String? detalhe) {
    _conectado = aoVivo;
    aoMudarEstado(aoVivo, detalhe);
  }

  Future<void> _tentar() async {
    if (_tentando || _encerrado) return;
    _tentando = true;

    final id = 'bikesafe-app-${DateTime.now().millisecondsSinceEpoch}';
    final cliente = criarClienteMqtt(Config.host, Config.brokerPorta, id);

    cliente
      ..setProtocolV311()
      ..keepAlivePeriod = 30
      ..connectTimeoutPeriod = 5000
      ..autoReconnect = false          
      ..logging(on: false)
      ..connectionMessage = MqttConnectMessage().withClientIdentifier(id).startClean();

    try {
      await cliente.connect();
    } catch (e) {
      _falhou(cliente, e);
      return;
    }

    if (cliente.connectionStatus?.state != MqttConnectionState.connected) {
      _falhou(cliente, cliente.connectionStatus?.returnCode ?? 'sem resposta');
      return;
    }

    _cliente?.disconnect();
    _cliente = cliente;

    cliente.onDisconnected = () {
      if (!_encerrado) {
        _marcar(false, 'Conexão com o broker perdida. Nova tentativa em 15 s.');
      }
    };

    cliente.subscribe(Config.topicoApp, MqttQos.atLeastOnce);
    cliente.updates!.listen(_receber);

    _marcar(true, null);
    _tentando = false;
  }

  void _falhou(MqttClient cliente, Object motivo) {
    cliente.disconnect();
    _marcar(
      false,
      'Broker ${Config.host}:${Config.brokerPorta} indisponível ($motivo). '
      'Nova tentativa em 15 s.',
    );
    _tentando = false;
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
       
      }
    }
  }

  void desconectar() {
    _encerrado = true;
    _timer?.cancel();
    _cliente?.disconnect();
  }
}
