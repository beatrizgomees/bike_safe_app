
double? _d(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '.'));

String? _s(Object? v) => v?.toString();

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

