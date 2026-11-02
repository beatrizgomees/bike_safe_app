import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'models.dart';

/// Um ponto do mapa: um acidente sozinho ou vários agrupados (círculo com a contagem).
class Grupo {
  Grupo(this.ponto, this.itens);

  final LatLng ponto;
  final List<Acidente> itens;

  int get total => itens.length;
  bool get unico => itens.length == 1;
}

List<Grupo> agrupar(Iterable<Acidente> acidentes, double zoom, {double celulaPx = 64}) {
  final grau = 360.0 / (256.0 * math.pow(2, zoom)) * celulaPx;
  final celulas = <String, List<Acidente>>{};

  for (final a in acidentes) {
    if (!a.temPosicao) continue;

    final chave = '${(a.lat! / grau).floor()}:${(a.lon! / grau).floor()}';
    celulas.putIfAbsent(chave, () => []).add(a);
  }

  return [
    for (final itens in celulas.values)
      Grupo(
        itens.length == 1
            ? itens.first.ponto
            : LatLng(
                itens.map((a) => a.lat!).reduce((x, y) => x + y) / itens.length,
                itens.map((a) => a.lon!).reduce((x, y) => x + y) / itens.length,
              ),
        itens,
      )
  ];
}
