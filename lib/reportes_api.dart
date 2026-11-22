import 'dart:convert';

import 'package:bikesafe_app/config.dart';
import 'package:bikesafe_app/models/reporte.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Chamadas da API para os reportes do usuário (GET e POST /api/reportes).
/// Fica separado do ApiService para não mexer no que já funciona.
class ReportesApi {
  /// Reportes feitos por este aparelho, do mais novo ao mais antigo.
  Future<List<Reporte>> listar() async {
    final uri = Uri.parse(
        '${Config.apiUrl}/api/reportes?dispositivo=${Uri.encodeQueryComponent(Config.dispositivo)}');

    final resposta = await http.get(uri).timeout(const Duration(seconds: 30));

    if (resposta.statusCode != 200) {
      throw Exception('A API respondeu ${resposta.statusCode}.');
    }

    final lista = jsonDecode(utf8.decode(resposta.bodyBytes)) as List;

    return [for (final r in lista) Reporte.fromJson(Map<String, dynamic>.from(r))];
  }

  /// Envia um reporte. Lança Exception com a mensagem da API se ele for recusado.
  Future<Reporte> enviar({
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
          : 'A API respondeu ${resposta.statusCode}.');
    }

    return Reporte.fromJson(Map<String, dynamic>.from(corpo));
  }
}