import 'package:latlong2/latlong.dart';

double? _d(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '.'));

String? _s(Object? v) => v?.toString();

Map<String, dynamic> _mapa(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

class Ciclovia {
  Ciclovia({this.rede, this.rota, this.tipo, this.distM, this.naCiclovia = false});

  final String? rede, rota, tipo;
  final double? distM;
  final bool naCiclovia;

  factory Ciclovia.fromJson(Map<String, dynamic> j) => Ciclovia(
        rede: _s(j['rede']),
        rota: _s(j['rota']),
        tipo: _s(j['tipo']),
        distM: _d(j['dist_m']),
        naCiclovia: j['na_ciclovia'] == true,
      );
}

class Estacao {
  Estacao({this.codigo, this.nome, this.distM, this.noRaio = false, this.estacoesNoRaio});

  final String? codigo, nome;
  final double? distM;
  final bool noRaio;
  final int? estacoesNoRaio;

  factory Estacao.fromJson(Map<String, dynamic> j) => Estacao(
        codigo: _s(j['codigo']),
        nome: _s(j['nome']),
        distM: _d(j['dist_m']),
        noRaio: j['no_raio'] == true,
        estacoesNoRaio: (j['estacoes_no_raio'] as num?)?.toInt(),
      );
}

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

class Resumo {
  Resumo({
    this.acidentesBike = 0,
    this.geocodificados = 0,
    this.emCiclovia = 0,
    this.comEstacaoNoRaio = 0,
  });

  final int acidentesBike, geocodificados, emCiclovia, comEstacaoNoRaio;

  factory Resumo.fromJson(Map<String, dynamic> j) => Resumo(
        acidentesBike: (j['acidentes_bike'] as num?)?.toInt() ?? 0,
        geocodificados: (j['geocodificados'] as num?)?.toInt() ?? 0,
        emCiclovia: (j['em_ciclovia'] as num?)?.toInt() ?? 0,
        comEstacaoNoRaio: (j['com_estacao_no_raio'] as num?)?.toInt() ?? 0,
      );
}

/// Um trecho de ciclovia/ciclofaixa para desenhar no mapa.
class Trecho {
  Trecho({required this.pontos, this.rota, this.tipo, this.rede});

  final List<LatLng> pontos;
  final String? rota, tipo, rede;

  bool get ehCiclofaixa => (tipo ?? '').toLowerCase().contains('faixa');

  /// FeatureCollection de /api/ciclovias (LineString e MultiLineString).
  static List<Trecho> deGeoJson(Map<String, dynamic> g) {
    final saida = <Trecho>[];

    for (final f in (g['features'] as List? ?? const [])) {
      final props = _mapa(f['properties']);
      final geometria = _mapa(f['geometry']);
      final coords = geometria['coordinates'];

      if (coords is! List) continue;

      final linhas = geometria['type'] == 'MultiLineString' ? coords : [coords];

      for (final linha in linhas) {
        final pontos = [
          for (final p in (linha as List))
            LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble())
        ];

        if (pontos.length >= 2) {
          saida.add(Trecho(
            pontos: pontos,
            rota: _s(props['rota']),
            tipo: _s(props['tipo']),
            rede: _s(props['rede']),
          ));
        }
      }
    }

    return saida;
  }
}
