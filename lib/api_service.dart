import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'config.dart';
import 'models.dart';

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

  Future<Resumo> resumo() async =>
      Resumo.fromJson(Map<String, dynamic>.from(await _get('/api/resumo')));

  Future<List<Acidente>> acidentes({int limite = 500}) async {
    final lista = await _get('/api/acidentes?limite=$limite') as List;

    return [for (final a in lista) Acidente.deApi(Map<String, dynamic>.from(a))];
  }

  Future<List<Trecho>> ciclovias() async =>
      Trecho.deGeoJson(Map<String, dynamic>.from(await _get('/api/ciclovias')));

  Future<List<EstacaoBike>> estacoes() async {
    final lista = await _get('/api/estacoes') as List;

    return [for (final e in lista) EstacaoBike.fromJson(Map<String, dynamic>.from(e))];
  }

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
