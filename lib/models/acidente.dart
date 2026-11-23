import 'package:bikesafe_app/models/ciclovia.dart';
import 'package:bikesafe_app/models/estacao.dart';
import 'package:bikesafe_app/util/formato_br.dart';
import 'package:latlong2/latlong.dart';

Map<String, dynamic> _mapa(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};


double? _d(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '.'));

String? _s(Object? v) => v?.toString();

/// Um acidente com ciclista, já cruzado com ciclovias e estações pelo MP.
class Acidente {
  Acidente({
    required this.protocolo,
    this.data,
    this.hora,
    this.bairro,
    this.endereco,
    this.numero,
    this.natureza,
    this.lat,
    this.lon,
    this.ciclovias = const [],
    this.estacao,
  });

  final String protocolo;
  final String? data, hora, bairro, endereco, numero, natureza;
  final double? lat, lon;
  final List<Ciclovia> ciclovias;
  final Estacao? estacao;

  bool get temPosicao => lat != null && lon != null;
  bool get naCiclovia => ciclovias.any((c) => c.naCiclovia);
  LatLng get ponto => LatLng(lat!, lon!);

  /// Para exibir: "01/06/2024", "04:06" e "01/06/2024 às 04:06".
  String? get dataBr => FormatoBr.data(data);
  String? get horaBr => FormatoBr.hora(hora);
  String? get quandoBr => FormatoBr.quando(data, hora);

  static List<Ciclovia> _ciclovias(Object? v) => v is List
      ? [for (final c in v) Ciclovia.fromJson(_mapa(c))]
      : <Ciclovia>[];

  /// Formato da API: /api/acidentes
  factory Acidente.deApi(Map<String, dynamic> j) => Acidente(
        protocolo: j['protocolo'].toString(),
        data: _s(j['data']),
        hora: _s(j['hora']),
        bairro: _s(j['bairro']),
        endereco: _s(j['endereco']),
        numero: _s(j['numero']),
        natureza: _s(j['natureza']),
        lat: _d(j['lat']),
        lon: _d(j['lon']),
        ciclovias: _ciclovias(j['ciclovias']),
        estacao: j['estacao'] is Map ? Estacao.fromJson(_mapa(j['estacao'])) : null,
      );

  /// Formato do MQTT: bikesafe/app/acidente  ->  {acidente: {...}, analise: {local, ciclovias, estacao}}
  factory Acidente.deEvento(Map<String, dynamic> e) {
    final a = _mapa(e['acidente']);
    final analise = _mapa(e['analise']);
    final local = _mapa(analise['local']);

    return Acidente(
      protocolo: a['protocolo'].toString(),
      data: _s(a['data']),
      hora: _s(a['hora']),
      bairro: _s(a['bairro']),
      endereco: _s(a['endereco']),
      numero: _s(a['numero']),
      natureza: _s(a['natureza']),
      lat: _d(local['lat']),
      lon: _d(local['lon']),
      ciclovias: _ciclovias(analise['ciclovias']),
      estacao: analise['estacao'] is Map ? Estacao.fromJson(_mapa(analise['estacao'])) : null,
    );
  }
}