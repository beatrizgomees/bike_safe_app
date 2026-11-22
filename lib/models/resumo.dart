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


