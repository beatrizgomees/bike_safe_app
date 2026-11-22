import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Endereço encontrado para uma coordenada.
class Endereco {
  Endereco({this.rua, this.numero, this.bairro, this.cidade, this.cep});

  final String? rua, numero, bairro, cidade, cep;

  /// "Av. Boa Viagem, 3200 · Boa Viagem" — o que vai no reporte e aparece na lista.
  String get resumo {
    final ruaNumero = [rua, numero].whereType<String>().join(', ');
    return [ruaNumero.isEmpty ? null : ruaNumero, bairro].whereType<String>().join(' · ');
  }

  /// "CEP 51020-000 · Recife"
  String get complemento =>
      [if (cep != null) 'CEP $cep', cidade].whereType<String>().join(' · ');

  bool get vazio => resumo.isEmpty;
}

/// Converte latitude/longitude em endereço (geocodificação reversa) pelo Nominatim,
/// o serviço de mapas do OpenStreetMap. Gratuito, sem chave.
///
/// Regras de uso do Nominatim: identificar o app no User-Agent e fazer no máximo
/// uma consulta por segundo. Aqui é uma consulta por reporte, então está dentro.
class EnderecoService {
  static const _agente = 'BikeSafe/1.0 (projeto academico)';

  Future<Endereco?> deCoordenadas(LatLng p) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': '${p.latitude}',
      'lon': '${p.longitude}',
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '18', // nível de rua/número
      'accept-language': 'pt-BR',
    });

    final resposta = await http
        .get(uri, headers: {'User-Agent': _agente})
        .timeout(const Duration(seconds: 10));

    if (resposta.statusCode != 200) return null;

    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (corpo is! Map || corpo['address'] is! Map) return null;

    final a = Map<String, dynamic>.from(corpo['address'] as Map);
    String? campo(List<String> chaves) {
      for (final k in chaves) {
        final v = a[k]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    final endereco = Endereco(
      rua: campo(['road', 'pedestrian', 'cycleway', 'footway', 'path']),
      numero: campo(['house_number']),
      bairro: campo(['suburb', 'neighbourhood', 'quarter', 'city_district']),
      cidade: campo(['city', 'town', 'municipality']),
      cep: campo(['postcode']),
    );

    return endereco.vazio ? null : endereco;
  }
}