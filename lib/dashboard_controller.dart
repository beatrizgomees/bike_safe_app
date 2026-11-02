import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'api_service.dart';
import 'models.dart';
import 'mqtt_service.dart';

/// Junta os dois caminhos do dado: histórico (API) e tempo real (MQTT).
class DashboardController extends ChangeNotifier {
  final _api = ApiService();
  late final MqttService _mqtt;

  final mapController = MapController();

  Resumo resumo = Resumo();
  List<Acidente> acidentes = [];          // mais recente primeiro
  List<Polyline> ciclovias = [];          // montadas uma vez (são muitas)
  Acidente? selecionado;
  String estado = 'conectando…';
  String? erroApi;

  final _protocolos = <String>{};

  Future<void> iniciar() async {
    _mqtt = MqttService(
      aoAcidente: (e) => _adicionar(Acidente.deEvento(e), novo: true),
      aoReceberUltimos: (lista) {
        for (final e in lista.reversed) {
          _adicionar(Acidente.deEvento(e), novo: false);
        }
      },
      aoMudarEstado: (s) {
        estado = s;
        notifyListeners();
      },
    );

    await _carregarHistorico();
    await _mqtt.conectar();
  }

  Future<void> _carregarHistorico() async {
    final falhas = <String>[];

    // cada chamada é independente: se uma falhar, as outras continuam
    try {
      resumo = await _api.resumo();
    } catch (e) {
      falhas.add('resumo ($e)');
    }

    try {
      final historico = await _api.acidentes();
      for (final a in historico.reversed) {
        _adicionar(a, novo: false, avisar: false);
      }
    } catch (e) {
      falhas.add('acidentes ($e)');
    }

    try {
      final trechos = await _api.ciclovias();
      ciclovias = [
        for (final t in trechos)
          Polyline(
            points: t.pontos,
            strokeWidth: 3,
            color: (t.ehCiclofaixa ? Colors.orange : Colors.green).withOpacity(0.8),
          )
      ];
    } catch (e) {
      falhas.add('ciclovias ($e)');
    }

    erroApi = falhas.isEmpty ? null : 'Falhou: ${falhas.join('; ')}';
    notifyListeners();
  }

  void _adicionar(Acidente a, {required bool novo, bool avisar = true}) {
    if (!_protocolos.add(a.protocolo)) return;   // já conhecido (histórico x tempo real)

    acidentes.insert(0, a);

    if (novo) {
      selecionado = a;
      _irPara(a);
      _atualizarResumo();
    }

    if (avisar) notifyListeners();
  }

  Future<void> _atualizarResumo() async {
    try {
      resumo = await _api.resumo();
      notifyListeners();
    } catch (_) {}
  }

  void selecionar(Acidente a) {
    selecionado = a;
    _irPara(a);
    notifyListeners();
  }

  void limparSelecao() {
    selecionado = null;
    notifyListeners();
  }

  void _irPara(Acidente a) {
    if (!a.temPosicao) return;

    try {
      mapController.move(a.ponto, 15);
    } catch (_) {
      // o mapa ainda não foi desenhado: a posição inicial já serve
    }
  }

  @override
  void dispose() {
    _mqtt.desconectar();
    super.dispose();
  }
}
