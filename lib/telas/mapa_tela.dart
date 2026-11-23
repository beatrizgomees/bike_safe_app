import 'dart:math' as math;

import 'package:bikesafe_app/components/detalhe.dart';
import 'package:bikesafe_app/dashboard_controller.dart';
import 'package:bikesafe_app/models/acidente.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Cores do layout (as mesmas da legenda)
const _corAcidente = Color(0xFFC2410C);   // laranja
const _corCiclovia = Color(0xFF00796B);   // verde-azulado
const _corCiclofaixa = Color(0xFF2563EB); // azul (tracejado)
const _corEstacao = Color(0xFF2563EB);    // anel azul

/// Aba do mapa: título, filtros de camada, mapa com acidentes agrupados e legenda.
class Mapa extends StatefulWidget {
  const Mapa(this.c, {super.key});

  final DashboardController c;

  @override
  State<Mapa> createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  // Camadas ligadas (como no layout: acidentes, ciclovias e ciclofaixas ligadas)
  bool _acidentes = true;
  bool _ciclovias = true;
  bool _ciclofaixas = true;
  bool _estacoes = false;
  bool _soRotas = false; // só acidentes junto a ciclovia/ciclofaixa

  double _zoom = 12;

  DashboardController get c => widget.c;

  /// Guarda o zoom arredondado para reagrupar os acidentes quando ele muda.
  void _aoMoverMapa(MapCamera camera, bool _) {
    final z = camera.zoom.roundToDouble();

    if (z == _zoom) return;

    _zoom = z;
    Future.microtask(() {
      if (mounted) setState(() {});
    });
  }

  bool _selecionado(_Grupo g) => g.itens.length == 1 && identical(g.itens.first, c.selecionado);

  void _tocarGrupo(_Grupo g) {
    if (g.itens.length == 1) {
      c.selecionar(g.itens.first);
    } else {
      c.mapController.move(g.centro, math.min(_zoom + 2, 18));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    final visiveis = c.acidentes.where((a) => a.temPosicao && (!_soRotas || a.naCiclovia));
    final grupos = _acidentes ? _agrupar(visiveis, _zoom) : const <_Grupo>[];

    return ColoredBox(
      color: tema.colorScheme.surfaceContainerLow,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Título e estado da conexão
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Mapa',
                          style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    // _ChipConexao(aoVivo: c.aoVivo),
                  ],
                ),
              ),
            ),

            // Filtros de camada
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                children: [
                  _Filtro('Acidentes', _acidentes, (v) => setState(() => _acidentes = v)),
                  _Filtro('Ciclovias', _ciclovias, (v) => setState(() => _ciclovias = v)),
                  _Filtro('Ciclofaixas', _ciclofaixas, (v) => setState(() => _ciclofaixas = v)),
                  _Filtro('Estações', _estacoes, (v) => setState(() => _estacoes = v)),
                  _Filtro('Só em rotas cicloviárias', _soRotas, (v) => setState(() => _soRotas = v)),
                ],
              ),
            ),

            // Mapa
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: c.mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(-8.0476, -34.877), // Recife
                      initialZoom: 12,
                      onPositionChanged: _aoMoverMapa,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'br.bikesafe.app',
                      ),
                      if (_ciclofaixas) PolylineLayer(polylines: c.linhasCiclofaixa),
                      if (_ciclovias) PolylineLayer(polylines: c.linhasCiclovia),

                      if (_estacoes)
                        MarkerLayer(markers: [
                          for (final e in c.estacoes)
                            if (e.lat != null && e.lon != null)
                              Marker(
                                point: LatLng(e.lat!, e.lon!),
                                width: 18,
                                height: 18,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: _corEstacao, width: 3),
                                  ),
                                ),
                              ),
                        ]),

                      MarkerLayer(markers: [
                        for (final g in grupos)
                          Marker(
                            point: g.centro,
                            // o selecionado ganha espaço para o halo em volta
                            width: _selecionado(g) ? 56 : g.tamanho,
                            height: _selecionado(g) ? 56 : g.tamanho,
                            child: GestureDetector(
                              onTap: () => _tocarGrupo(g),
                              child: _MarcadorAcidente(
                                quantidade: g.itens.length,
                                selecionado: _selecionado(g),
                              ),
                            ),
                          ),
                      ]),

                      const RichAttributionWidget(
                        attributions: [TextSourceAttribution('© OpenStreetMap')],
                      ),
                    ],
                  ),

                  // Legenda (some quando o detalhe está aberto)
                  if (c.selecionado == null)
                    const Positioned(left: 16, bottom: 16, child: _Legenda()),

                  // Acidente selecionado: escurece o mapa e sobe o painel do rodapé
                  if (c.selecionado != null) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: c.limparSelecao, // tocar fora fecha
                        child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Detalhe(c.selecionado!, onFechar: c.limparSelecao),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Acidentes próximos na tela viram um só marcador com a contagem.
class _Grupo {
  _Grupo(this.centro, this.itens);

  final LatLng centro;
  final List<Acidente> itens;

  double get tamanho => itens.length == 1 ? 22 : (itens.length < 10 ? 34 : 42);
}

/// Agrupa por uma grade de ~56 px na tela: quanto maior o zoom, menor a célula.
List<_Grupo> _agrupar(Iterable<Acidente> lista, double zoom) {
  final celula = 56 * 360 / (256 * math.pow(2, zoom));
  final celulas = <String, List<Acidente>>{};

  for (final a in lista) {
    final chave = '${(a.ponto.latitude / celula).floor()}:${(a.ponto.longitude / celula).floor()}';
    (celulas[chave] ??= []).add(a);
  }

  return [
    for (final itens in celulas.values)
      _Grupo(
        LatLng(
          itens.map((a) => a.ponto.latitude).reduce((x, y) => x + y) / itens.length,
          itens.map((a) => a.ponto.longitude).reduce((x, y) => x + y) / itens.length,
        ),
        itens,
      ),
  ];
}

class _MarcadorAcidente extends StatelessWidget {
  const _MarcadorAcidente({required this.quantidade, required this.selecionado});

  final int quantidade;
  final bool selecionado;

  @override
  Widget build(BuildContext context) {
    // Selecionado: bolinha laranja com um halo claro em volta, como no layout
    if (selecionado) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _corAcidente.withValues(alpha: 0.22),
        ),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _corAcidente,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _corAcidente,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: quantidade > 1
          ? Text('$quantidade',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))
          : null,
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro(this.rotulo, this.ligado, this.aoMudar);

  final String rotulo;
  final bool ligado;
  final ValueChanged<bool> aoMudar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(rotulo),
        selected: ligado,
        onSelected: aoMudar,
        showCheckmark: true,
        selectedColor: cs.primaryContainer,
        checkmarkColor: cs.onPrimaryContainer,
        backgroundColor: cs.surface,
        side: BorderSide(color: ligado ? cs.primaryContainer : cs.outline),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: ligado ? cs.onPrimaryContainer : cs.onSurface,
          fontWeight: ligado ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();

  Widget _linha(Widget simbolo, String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 20, child: Center(child: simbolo)),
            const SizedBox(width: 8),
            Text(texto, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _linha(
            Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(color: _corAcidente, shape: BoxShape.circle)),
            'Acidente (número = agrupados)',
          ),
          _linha(Container(width: 18, height: 4, color: _corCiclovia), 'Ciclovia'),
          _linha(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 3, color: _corCiclofaixa),
                const SizedBox(width: 3),
                Container(width: 6, height: 3, color: _corCiclofaixa),
              ],
            ),
            'Ciclofaixa',
          ),
          _linha(
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: _corEstacao, width: 3),
              ),
            ),
            'Estação de bicicleta',
          ),
        ],
      ),
    );
  }
}

/// "Ao vivo" quando conectado ao broker; "Offline" quando lendo do banco.
class _ChipConexao extends StatelessWidget {
  const _ChipConexao({required this.aoVivo});

  final bool aoVivo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: aoVivo ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: aoVivo ? cs.primary : cs.outline,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(aoVivo ? 'Ao vivo' : 'Offline',
              style: TextStyle(
                color: aoVivo ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}