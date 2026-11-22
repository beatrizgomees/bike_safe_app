import 'package:latlong2/latlong.dart';

Map<String, dynamic> _mapa(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

String? _s(Object? v) => v?.toString();

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