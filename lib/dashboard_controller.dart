import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'api_service.dart';
import 'config.dart';
import 'models.dart';
import 'mqtt_service.dart';

enum Filtro { todos, emCiclovia, foraCiclovia, pertoEstacao }

class DashboardController extends ChangeNotifier {
  final _api = ApiService();
  MqttService? _mqtt;

  final mapController = MapController();

  int aba = 0; // 0 home, 1 mapa, 2 reportados, 3 configurações


  Resumo resumo = Resumo();
  List<Acidente> acidentes = [];         
  List<Polyline> polCiclovias = [];       
  List<Polyline> polCiclofaixas = [];
  List<EstacaoBike> estacoes = [];
  List<Reporte> reportes = [];
  String? erroReportes;
  Acidente? selecionado;


  bool aoVivo = false;                    
  String? detalheBroker;                
  String? erroApi;

  // ---- camadas do mapa
  Filtro filtro = Filtro.todos;
  bool mostrarAcidentes = true;
  bool mostrarEstacoes = false;
  bool mostrarCiclovias = true;
  bool mostrarCiclofaixas = true;
  double zoom = 12;

  bool _historicoCarregado = false;
  bool _atualizando = false;
  Timer? _poll;
  final _protocolos = <String>{};

  String get estado => aoVivo ? 'ao vivo' : 'offline · dados do banco';

  // =================================================================== ciclo de vida
  Future<void> iniciar() async {
    _mqtt = MqttService(
      aoAcidente: (e) => _adicionar(Acidente.deEvento(e), novo: true),
      aoReceberUltimos: (lista) {
        for (final e in lista.reversed) {
          _adicionar(Acidente.deEvento(e), novo: false);
        }
      },
      aoMudarEstado: (ok, detalhe) {
        final voltou = ok && !aoVivo;

        aoVivo = ok;
        detalheBroker = detalhe;
        _ajustarPolling();
        notifyListeners();

        if (voltou) atualizar();   
      },
    );

    _ajustarPolling();   
    _mqtt!.iniciar();   

    await atualizar();
    carregarReportes();
  }

  Future<void> reconfigurar() async {
    _mqtt?.desconectar();
    _poll?.cancel();
    _poll = null;

    aoVivo = false;
    detalheBroker = null;
    erroApi = null;
    acidentes = [];
    _protocolos.clear();
    polCiclovias = [];
    polCiclofaixas = [];
    estacoes = [];
    reportes = [];
    selecionado = null;
    _historicoCarregado = false;
    notifyListeners();

    await iniciar();
  }

  void _ajustarPolling() {
    if (aoVivo) {
      _poll?.cancel();
      _poll = null;
    } else {
      _poll ??= Timer.periodic(
        Duration(seconds: Config.intervaloOfflineSeg),
        (_) => atualizar(),
      );
    }
  }

  void reiniciarPolling() {
    _poll?.cancel();
    _poll = null;
    _ajustarPolling();
  }

  Future<void> atualizar() async {
    if (_atualizando) return;
    _atualizando = true;

    final falhas = <String>[];

    try {
      resumo = await _api.resumo();
    } catch (e) {
      falhas.add('resumo ($e)');
    }

    try {
      final lista = await _api.acidentes();

      for (final a in lista.reversed) {
        _adicionar(a, novo: _historicoCarregado, avisar: false);
      }

      _historicoCarregado = true;
    } catch (e) {
      falhas.add('acidentes ($e)');
    }

    if (polCiclovias.isEmpty && polCiclofaixas.isEmpty) {
      try {
        final trechos = await _api.ciclovias();

        polCiclovias = [
          for (final t in trechos.where((t) => !t.ehCiclofaixa)) _linha(t, Colors.green)
        ];
        polCiclofaixas = [
          for (final t in trechos.where((t) => t.ehCiclofaixa)) _linha(t, Colors.orange)
        ];
      } catch (e) {
        falhas.add('ciclovias ($e)');
      }
    }

    if (estacoes.isEmpty) {
      try {
        estacoes = await _api.estacoes();
      } catch (e) {
        falhas.add('estações ($e)');
      }
    }

    erroApi = falhas.isEmpty ? null : 'Sem resposta da API (${Config.apiUrl}): ${falhas.join('; ')}';

    _atualizando = false;
    notifyListeners();
  }

  Polyline _linha(Trecho t, Color cor) =>
      Polyline(points: t.pontos, strokeWidth: 3, color: cor.withOpacity(0.8));

  void _adicionar(Acidente a, {required bool novo, bool avisar = true}) {
    if (!_protocolos.add(a.protocolo)) return;   

    acidentes.insert(0, a);

    if (novo) {
      selecionado = a;
      _mover(a);
    }

    if (avisar) notifyListeners();

    if (novo && aoVivo) _atualizarResumo();
  }

  Future<void> _atualizarResumo() async {
    try {
      resumo = await _api.resumo();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> carregarReportes() async {
    try {
      reportes = await _api.reportes(Config.dispositivo);
      erroReportes = null;
    } catch (e) {
      erroReportes = 'Não consegui carregar seus reportes ($e)';
    }

    notifyListeners();
  }

  Future<void> enviarReporte({
    required String tipo,
    required LatLng ponto,
    String? descricao,
    String? endereco,
  }) async {
    final r = await _api.enviarReporte(
      tipo: tipo,
      ponto: ponto,
      descricao: descricao,
      endereco: endereco,
    );

    reportes.insert(0, r);
    erroReportes = null;
    notifyListeners();
  }

  void irParaAba(int i) {
    aba = i;
    notifyListeners();
  }

  void selecionarNoMapa(Acidente a) {
    selecionado = a;
    aba = 1;
    notifyListeners();
    _depoisDoQuadro(() => _mover(a));
  }

  void verNoMapa(LatLng ponto, {double nivel = 16}) {
    aba = 1;
    notifyListeners();
    _depoisDoQuadro(() => _moverPara(ponto, nivel));
  }

  void _depoisDoQuadro(VoidCallback f) => WidgetsBinding.instance.addPostFrameCallback((_) => f());

  List<Acidente> get visiveis => acidentes.where((a) {
        switch (filtro) {
          case Filtro.todos:
            return true;
          case Filtro.emCiclovia:
            return a.naCiclovia;
          case Filtro.foraCiclovia:
            return !a.naCiclovia;
          case Filtro.pertoEstacao:
            return a.estacao?.noRaio == true;
        }
      }).toList();

  bool get soNasRotas => filtro == Filtro.emCiclovia;

  void definirFiltro(Filtro f) {
    filtro = f;
    notifyListeners();
  }

  void alternarSoNasRotas() => definirFiltro(soNasRotas ? Filtro.todos : Filtro.emCiclovia);

  void alternarAcidentes() {
    mostrarAcidentes = !mostrarAcidentes;
    notifyListeners();
  }

  void alternarEstacoes() {
    mostrarEstacoes = !mostrarEstacoes;
    notifyListeners();
  }

  void alternarCiclovias() {
    mostrarCiclovias = !mostrarCiclovias;
    notifyListeners();
  }

  void alternarCiclofaixas() {
    mostrarCiclofaixas = !mostrarCiclofaixas;
    notifyListeners();
  }

  void definirZoom(double z) {
    if ((z - zoom).abs() < 0.05) return;   // ignora variações mínimas
    zoom = z;
    notifyListeners();
  }

  void selecionar(Acidente a) {
    selecionado = a;
    _mover(a);
    notifyListeners();
  }

  void limparSelecao() {
    selecionado = null;
    notifyListeners();
  }

  void centralizar() => _moverPara(const LatLng(-8.0476, -34.877), 12);

  void aproximar(LatLng ponto) => _moverPara(ponto, (zoom + 2).clamp(0, 18).toDouble());

  void _mover(Acidente a) {
    if (a.temPosicao) _moverPara(a.ponto, 15);
  }

  void _moverPara(LatLng ponto, double nivel) {
    try {
      mapController.move(ponto, nivel);
    } catch (_) {
      
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _mqtt?.desconectar();
    super.dispose();
  }
}
