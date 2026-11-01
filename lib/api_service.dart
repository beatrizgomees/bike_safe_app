import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

/// Histórico: o que já está gravado no banco (via API).
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
}
