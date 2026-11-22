import 'package:latlong2/latlong.dart';

double? _d(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '.'));

String? _s(Object? v) => v?.toString();

/// Estação mais próxima de um acidente (vem dentro de cada acidente).
class Estacao {
  Estacao({
    this.codigo,
    this.nome,
    this.distM,
    this.noRaio = false,
    this.estacoesNoRaio,
    this.lat,
    this.lon,
  });

  final String? codigo, nome;
  final double? distM;
  final bool noRaio;
  final int? estacoesNoRaio;
  final double? lat, lon; // podem faltar: a API de acidentes ainda não manda

  bool get temPosicao => lat != null && lon != null;
  LatLng get ponto => LatLng(lat!, lon!);

  factory Estacao.fromJson(Map<String, dynamic> j) => Estacao(
        codigo: _s(j['codigo']),
        nome: _s(j['nome']),
        distM: _d(j['dist_m']),
        noRaio: j['no_raio'] == true,
        estacoesNoRaio: (j['estacoes_no_raio'] as num?)?.toInt(),
        lat: _d(j['lat']),
        lon: _d(j['lon'] ?? j['lng']),
      );
}
