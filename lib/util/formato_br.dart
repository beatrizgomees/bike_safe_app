/// Datas e horas no padrão brasileiro: 01/06/2024 e 04:06.
///
/// Aceita o que chega da API e do MQTT:
///   data: "2024-06-01T00:00:00", "2024-06-01", "01/06/2024"
///   hora: "04:06:00", "04:06", "4:06"
/// Se não reconhecer o formato, devolve o texto original (melhor que sumir).
class FormatoBr {
  static String _2(int n) => n.toString().padLeft(2, '0');

  /// DateTime -> "01/06/2024"
  static String dataDe(DateTime d) => '${_2(d.day)}/${_2(d.month)}/${d.year}';

  /// DateTime -> "04:06"
  static String horaDe(DateTime d) => '${_2(d.hour)}:${_2(d.minute)}';

  /// Texto da API -> "01/06/2024". Null/vazio -> null.
  static String? data(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;

    // já está no padrão brasileiro
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(t)) return t;

    // ISO: só a parte da data, sem converter fuso (a API manda meia-noite "sem fuso")
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
    if (iso != null) return '${iso[3]}/${iso[2]}/${iso[1]}';

    return t;
  }

  /// Texto da API -> "04:06". Null/vazio -> null.
  static String? hora(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;

    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(t);
    if (m == null) return t;

    return '${_2(int.parse(m[1]!))}:${m[2]}';
  }

  /// "01/06/2024 às 04:06" (ou só a parte que existir).
  static String? quando(String? data, String? hora) {
    final d = FormatoBr.data(data);
    final h = FormatoBr.hora(hora);

    if (d != null && h != null) return '$d às $h';
    return d ?? h;
  }
}
