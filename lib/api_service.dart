import 'dart:convert';

import 'package:bikesafe_app/models/reporte.dart' show Reporte;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'config.dart';
import 'models/acidente.dart';
import 'models/estacao.dart';
import 'models/resumo.dart';
import 'models/trecho.dart';

/// Histórico: o que já está gravado no banco (via API). Também envia os reportes do app.
class ApiService {
  Future<dynamic> _get(String caminho) async {
    final resposta = await http
        .get(Uri.parse('${Config.apiUrl}$caminho'))
        .timeout(const Duration(seconds: 30));

    if (resposta.statusCode != 200) {
      throw Exception('API respondeu ${resposta.statusCode} em $caminho');
    }

    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }

  /// Envia um reporte de acidente feito pelo usuário (POST /api/reportes).
  /// [tipo]: colisao, queda, atropelamento ou outro. A posição precisa estar no Recife.
  Future<Map<String, dynamic>> reportar({
    required String tipo,
    required double lat,
    required double lon,
    String? descricao,
    String? endereco,
  }) async {
    final http.Response resposta;

    try {
      resposta = await http
          .post(
            Uri.parse('${Config.apiUrl}/api/reportes'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'dispositivo': Config.dispositivo,
              'tipo': tipo,
              'lat': lat,
              'lon': lon,
              'endereco': endereco,
              if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception('Não consegui falar com o servidor (${Config.apiUrl}).');
    }

    dynamic dados;
    try {
      dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    } catch (_) {}

    if (resposta.statusCode != 200 && resposta.statusCode != 201) {
      throw Exception(dados is Map && dados['erro'] != null
          ? '${dados['erro']}'
          : 'O servidor respondeu ${resposta.statusCode}.');
    }

    return dados is Map ? Map<String, dynamic>.from(dados) : <String, dynamic>{};
  }

  Future<Resumo> resumo() async =>
      Resumo.fromJson(Map<String, dynamic>.from(await _get('/api/resumo')));

  Future<List<Acidente>> acidentes({int limite = 500}) async {
    final lista = await _get('/api/acidentes?limite=$limite') as List;

    return [for (final a in lista) Acidente.deApi(Map<String, dynamic>.from(a))];
  }

  /// Estações de bike com posição (as sem lat/lon ficam de fora).
  Future<List<Estacao>> estacoes() async {
    final lista = await _get('/api/estacoes') as List;

    return [
      for (final e in lista) Estacao.fromJson(Map<String, dynamic>.from(e)),
    ].where((e) => e.temPosicao).toList();
  }

  Future<List<Trecho>> ciclovias() async =>
      Trecho.deGeoJson(Map<String, dynamic>.from(await _get('/api/ciclovias')));

  Future<List<Reporte>> reportes(String dispositivo) async {
    final lista = await _get('/api/reportes?dispositivo=${Uri.encodeQueryComponent(dispositivo)}')
        as List;

    return [for (final r in lista) Reporte.fromJson(Map<String, dynamic>.from(r))];
  }

  /// Lança uma Exception com a mensagem da API quando o reporte é recusado.
  Future<Reporte> enviarReporte({
    required String tipo,
    required LatLng ponto,
    String? descricao,
    String? endereco,
  }) async {
    final resposta = await http
        .post(
          Uri.parse('${Config.apiUrl}/api/reportes'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'dispositivo': Config.dispositivo,
            'tipo': tipo,
            'descricao': descricao,
            'endereco': endereco,
            'lat': ponto.latitude,
            'lon': ponto.longitude,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));

    if (resposta.statusCode != 201) {
      throw Exception(corpo is Map && corpo['erro'] != null
          ? corpo['erro']
          : 'API respondeu ${resposta.statusCode}');
    }

    return Reporte.fromJson(Map<String, dynamic>.from(corpo));
  }
}
