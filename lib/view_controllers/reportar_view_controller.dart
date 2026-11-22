import 'dart:async';

import 'package:bikesafe_app/api_service.dart';
import 'package:bikesafe_app/location/endereco_service.dart';
import 'package:bikesafe_app/location/location_service.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Estado e regras do formulário "Reportar acidente".
class ReportarViewController extends ChangeNotifier {
  ReportarViewController({ApiService? api, EnderecoService? enderecos})
      : _api = api ?? ApiService(),
        _enderecos = enderecos ?? EnderecoService();

  final ApiService _api;
  final EnderecoService _enderecos;

  static const tipos = {
    'colisao': 'Colisão',
    'queda': 'Queda',
    'atropelamento': 'Atropelamento',
    'quase_acidente': 'Quase acidente',
    'buraco': 'Buraco',
    'alagamento': 'Alagamento',
    'obstrucao': 'Ciclovia obstruída',
    'iluminacao': 'Falta de iluminação',
    'sinalizacao': 'Sinalização ruim',
    'outro': 'Outro',
  };

  final descricao = TextEditingController();

  final _selecionados = <String>{}; // mais de uma ocorrência pode ser marcada
  LatLng? _posicao;
  Endereco? _endereco;
  bool _localizando = false;
  bool _buscandoEndereco = false;
  bool _enviando = false;
  bool _descartado = false;
  String? _erroLocal;
  String? _erro;

  /// Tipos marcados, na mesma ordem da lista de opções.
  List<String> get selecionados => [for (final t in tipos.keys) if (_selecionados.contains(t)) t];

  bool selecionado(String t) => _selecionados.contains(t);

  LatLng? get posicao => _posicao;
  Endereco? get endereco => _endereco;
  bool get localizando => _localizando;
  bool get buscandoEndereco => _buscandoEndereco;
  bool get enviando => _enviando;
  String? get erroLocal => _erroLocal;
  String? get erro => _erro;
  bool get podeEnviar => _selecionados.isNotEmpty && _posicao != null && !_enviando;

  /// Marca ou desmarca uma ocorrência.
  void alternarTipo(String t) {
    if (!_selecionados.remove(t)) _selecionados.add(t);
    _erro = null;
    _avisar();
  }

  /// Pega a posição atual (o reporte é feito onde a pessoa está)
  /// e, em seguida, o nome da rua dessa posição.
  Future<void> localizar() async {
    if (_localizando) return;

    _localizando = true;
    _erroLocal = null;
    _endereco = null;
    _avisar();

    try {
      _posicao = await LocalizacaoService().posicaoAtual();
    } on ErroLocalizacao catch (e) {
      _erroLocal = e.mensagem;
    } on TimeoutException {
      _erroLocal = 'A localização demorou demais. Tente de novo.';
    } catch (_) {
      _erroLocal = 'Não consegui obter sua localização.';
    } finally {
      _localizando = false;
      _avisar();
    }

    if (_posicao != null) await _buscarEndereco(_posicao!);
  }

  /// Para quando a posição vier do mapa (pino arrastado).
  Future<void> definirPosicao(LatLng p) async {
    _posicao = p;
    _endereco = null;
    _avisar();
    await _buscarEndereco(p);
  }

  /// O endereço é um extra: se falhar, o reporte continua possível só com as coordenadas.
  Future<void> _buscarEndereco(LatLng p) async {
    _buscandoEndereco = true;
    _avisar();

    try {
      final e = await _enderecos.deCoordenadas(p);
      if (_posicao == p) _endereco = e; // ignora resposta atrasada de uma posição antiga
    } catch (_) {
      _endereco = null;
    } finally {
      _buscandoEndereco = false;
      _avisar();
    }
  }

  /// Envia o reporte. Devolve true se o servidor aceitou.
  /// Vários tipos vão juntos, separados por vírgula: "buraco,alagamento".
  Future<bool> enviar() async {
    if (!podeEnviar) return false;

    _enviando = true;
    _erro = null;
    _avisar();

    try {
      await _api.reportar(
        tipo: selecionados.join(','),
        lat: _posicao!.latitude,
        lon: _posicao!.longitude,
        descricao: descricao.text.trim(),
        endereco: _endereco?.resumo,
      );

      return true;
    } catch (e) {
      _erro = '$e'.replaceFirst('Exception: ', '');
      _enviando = false;
      _avisar();

      return false;
    }
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    descricao.dispose();
    super.dispose();
  }
}