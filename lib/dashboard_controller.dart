import 'dart:async';

import 'package:bikesafe_app/location/location_service.dart';
import 'package:bikesafe_app/models/acidente.dart';
import 'package:bikesafe_app/models/estacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'api_service.dart';
import 'models/resumo.dart';
import 'mqtt_service.dart';

/// Junta os dois caminhos do dado: histórico (API) e tempo real (MQTT).
class DashboardController extends ChangeNotifier {
  final _api = ApiService();
  late final MqttService _mqtt;

  final mapController = MapController();

  Resumo resumo = Resumo();
  List<Acidente> acidentes = [];          // mais recente primeiro
  List<Estacao> estacoes = [];            // estações de bike (com posição)
  Acidente? selecionado;
  String estado = 'conectando…';
  bool get aoVivo => estado == 'ao vivo';
  String? erroApi;
  int aba = 0; // 0 home, 1 mapa, 2 reportados, 3 configurações
  final _protocolos = <String>{};
  EstacaoProxima? perto;
  String? erroLocal;
  bool buscandoLocal = false;
  List<Polyline> linhasCiclovia = [];
  List<Polyline> linhasCiclofaixa = [];
  List<Polyline> get ciclovias => [...linhasCiclovia, ...linhasCiclofaixa]; // se outro lugar ainda usa 
  Future<bool>? _estacoesCarregando;
  bool _descartado = false;

  /// Pede a localização (o pedido de permissão aparece aqui) e acha a estação
  /// mais perto, com os acidentes ao redor. Roda sozinha ao entrar no app
  /// e de novo pelo botão do CardEstacaoProxima.
  Future<void> buscarEstacaoProxima() async {
    if (buscandoLocal) return;

    buscandoLocal = true;
    erroLocal = null;
    _avisar();

    try {
      // 1) localização primeiro, para o pedido de permissão aparecer logo
      final eu = await LocalizacaoService().posicaoAtual();

      // 2) espera as estações (ou tenta de novo, se a carga falhou antes)
      if (estacoes.isEmpty) {
        final ok = await (_estacoesCarregando ??= _carregarEstacoes());
        _estacoesCarregando = null;

        if (!ok) {
          erroLocal = 'Não consegui carregar as estações. Verifique a conexão com o servidor.';
          return;
        }
      }

      // 3) estação mais próxima e acidentes no raio dela
      perto = estacaoMaisProxima(eu, estacoes, acidentes);
      if (perto == null) erroLocal = 'Nenhuma estação de bike cadastrada.';
    } on ErroLocalizacao catch (e) {
      erroLocal = e.mensagem;
    } on TimeoutException {
      erroLocal = 'A localização demorou demais. Tente de novo em um lugar aberto.';
    } catch (_) {
      erroLocal = 'Não consegui obter sua localização.';
    } finally {
      buscandoLocal = false;
      _avisar();
    }
  }

  /// Carrega as estações da API. Devolve false se a chamada falhou.
  Future<bool> _carregarEstacoes() async {
    try {
      estacoes = await _api.estacoes();
      return true;
    } catch (_) {
      return false; // sem estações só o cartão é afetado; o resto do app segue
    }
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

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

    // estações e localização em paralelo com o resto: o pedido de
    // permissão aparece assim que o usuário entra no app
    _estacoesCarregando = _carregarEstacoes();
    unawaited(buscarEstacaoProxima());

    await _carregarHistorico();
    await _mqtt.conectar();
  }

  Future<void> _carregarHistorico() async {
    try {
      resumo = await _api.resumo();

      final trechos = await _api.ciclovias();
     linhasCiclovia = [
  for (final t in trechos)
    if (!t.ehCiclofaixa)
      Polyline(points: t.pontos, strokeWidth: 4, color: const Color(0xFF00796B)),
];
linhasCiclofaixa = [
  for (final t in trechos)
    if (t.ehCiclofaixa)
      Polyline(
        points: t.pontos,
        strokeWidth: 3,
        color: const Color(0xFF2563EB),
        pattern: StrokePattern.dashed(segments: const [10, 8]),
      ),
];

      final historico = await _api.acidentes();
      for (final a in historico.reversed) {
        _adicionar(a, novo: false, avisar: false);
      }

      erroApi = null;
    } catch (e) {
      erroApi = 'API indisponível: $e';
    }

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

  void irParaAba(int i) {
    if (i == aba) return;
    aba = i;
    notifyListeners();
  }

  /// Seleciona o acidente e abre a aba do mapa nele.
  void verNoMapa(Acidente a) {
    aba = 1;
    selecionar(a);
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
    _descartado = true;
    _mqtt.desconectar();
    super.dispose();
  }
}