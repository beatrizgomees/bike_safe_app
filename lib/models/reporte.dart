import 'package:bikesafe_app/util/formato_br.dart';
import 'package:latlong2/latlong.dart';

const tiposReporte = {
  'colisao': 'Colisão',
  'queda': 'Queda',
  'atropelamento': 'Atropelamento',
  'quase_acidente': 'Quase acidente',
  'buraco': 'Buraco',
  'alagamento': 'Alagamento',
  'obstrucao': 'Ciclovia obstruída',
  'iluminacao': 'Falta de iluminação',
  'sinalizacao': 'Sinalização ruim',
  'outro': 'Outro',
};

/// Acidente reportado pelo próprio usuário, pelo app.
class Reporte {
  Reporte({
    required this.id,
    required this.tipo,
    required this.lat,
    required this.lon,
    required this.criadoEm,
    this.descricao,
    this.endereco,
    this.status = 'recebido',
  });

  final int id;
  final String tipo, status;
  final String? descricao, endereco;
  final double lat, lon;
  final DateTime criadoEm;

  LatLng get ponto => LatLng(lat, lon);
  String get tipoRotulo => tiposReporte[tipo] ?? tipo;

  /// "recebido" -> "Recebido"
  String get statusRotulo =>
      status.isEmpty ? status : status[0].toUpperCase() + status.substring(1);

  /// 15/11/2026
  String get dataRotulo => FormatoBr.dataDe(criadoEm);

  /// 15/11/2026 às 14:32
  String get quandoRotulo => '${FormatoBr.dataDe(criadoEm)} às ${FormatoBr.horaDe(criadoEm)}';

  factory Reporte.fromJson(Map<String, dynamic> j) => Reporte(
        id: (j['id'] as num).toInt(),
        tipo: j['tipo'].toString(),
        descricao: _texto(j['descricao']),
        endereco: _texto(j['endereco']),
        lat: _numero(j['lat']) ?? 0,
        lon: _numero(j['lon']) ?? 0,
        status: _texto(j['status']) ?? 'recebido',
        criadoEm: DateTime.tryParse('${j['criado_em']}')?.toLocal() ?? DateTime.now(),
      );
}

String? _texto(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

double? _numero(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '.'));