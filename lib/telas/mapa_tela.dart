import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../clusters.dart';
import '../dashboard_controller.dart';
import '../models.dart';
import '../widgets.dart';


class MapaTela extends StatelessWidget {
  const MapaTela(this.c, {super.key});
  final DashboardController c;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, caixa) => caixa.maxWidth >= 800 ? _TelaLarga(c) : _TelaCelular(c),
      );
}


class _TelaCelular extends StatefulWidget {
  const _TelaCelular(this.c);
  final DashboardController c;

  @override
  State<_TelaCelular> createState() => _TelaCelularState();
}

class _TelaCelularState extends State<_TelaCelular> {
  static const _minimo = 0.14, _inicial = 0.38, _maximo = 0.92;
  final _folha = DraggableScrollableController();

  void _recolher() => _folha.animateTo(
        _minimo,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  void _escolher(Acidente a) {
    widget.c.selecionar(a);

    if (_folha.isAttached && _folha.size > _inicial) {
      _folha.animateTo(
        _inicial,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final topo = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _Mapa(c)),
          Positioned(top: topo + 12, left: 12, right: 72, child: _FaixaCamadas(c)),
          Positioned(top: topo + 12, right: 12, child: _BotoesFlutuantes(c)),
          Positioned(top: topo + 64, left: 12, child: SeloEstado(c)),
          if (c.selecionado != null)
            Positioned(
              top: topo + 108,
              left: 12,
              right: 72,
              child: _Detalhe(c.selecionado!, onFechar: c.limparSelecao),
            ),
          DraggableScrollableSheet(
            controller: _folha,
            initialChildSize: _inicial,
            minChildSize: _minimo,
            maxChildSize: _maximo,
            snap: true,
            snapSizes: const [_minimo, _inicial, _maximo],
            builder: (context, rolagem) => _Folha(
              c,
              rolagem,
              aoFechar: _recolher,
              aoEscolher: _escolher,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaixaCamadas extends StatelessWidget {
  const _FaixaCamadas(this.c);
  final DashboardController c;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _chip(context, 'Acidentes', Colors.red.shade600, c.mostrarAcidentes, c.alternarAcidentes),
            _chip(context, 'Só nas rotas', null, c.soNasRotas,
                c.mostrarAcidentes ? c.alternarSoNasRotas : null,
                icone: Icons.alt_route),
            _chip(context, 'Estações', Colors.indigo.shade600, c.mostrarEstacoes, c.alternarEstacoes),
            _chip(context, 'Ciclovias', Colors.green.shade600, c.mostrarCiclovias, c.alternarCiclovias),
            _chip(context, 'Ciclofaixas', Colors.orange.shade700, c.mostrarCiclofaixas,
                c.alternarCiclofaixas),
          ],
        ),
      );

  Widget _chip(
    BuildContext context,
    String rotulo,
    Color? cor,
    bool ativo,
    VoidCallback? aoTocar, {
    IconData? icone,
  }) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: icone != null
            ? Icon(icone, size: 16)
            : CircleAvatar(radius: 6, backgroundColor: cor),
        label: Text(rotulo),
        selected: ativo,
        showCheckmark: false,
        elevation: 2,
        pressElevation: 4,
        backgroundColor: tema.colorScheme.surface,
        selectedColor: tema.colorScheme.primaryContainer,
        onSelected: aoTocar == null ? null : (_) => aoTocar(),
      ),
    );
  }
}

class _BotoesFlutuantes extends StatelessWidget {
  const _BotoesFlutuantes(this.c);
  final DashboardController c;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Atualizar do banco',
              icon: const Icon(Icons.refresh),
              onPressed: c.atualizar,
            ),
            const SizedBox(width: 40, child: Divider(height: 1)),
            IconButton(
              tooltip: 'Centralizar no Recife',
              icon: const Icon(Icons.near_me_outlined),
              onPressed: c.centralizar,
            ),
          ],
        ),
      );
}

class _Folha extends StatelessWidget {
  const _Folha(this.c, this.rolagem, {required this.aoFechar, required this.aoEscolher});

  final DashboardController c;
  final ScrollController rolagem;
  final VoidCallback aoFechar;
  final void Function(Acidente) aoEscolher;

  @override
  Widget build(BuildContext context) {
    final lista = c.visiveis;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
      ),
      child: CustomScrollView(
        controller: rolagem,
        slivers: [
          SliverPersistentHeader(pinned: true, delegate: _Cabecalho(c, aoFechar)),
          if (lista.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Nenhum acidente neste filtro')),
            )
          else
            SliverList.separated(
              itemCount: lista.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => ItemAcidente(c, lista[i], aoEscolher),
            ),
        ],
      ),
    );
  }
}

const _rotulosFiltro = {
  Filtro.todos: 'Todos',
  Filtro.emCiclovia: 'Em ciclovia',
  Filtro.foraCiclovia: 'Fora da ciclovia',
  Filtro.pertoEstacao: 'Perto de estação',
};

class _Cabecalho extends SliverPersistentHeaderDelegate {
  _Cabecalho(this.c, this.aoFechar);

  final DashboardController c;
  final VoidCallback aoFechar;

  @override
  double get minExtent => 136;

  @override
  double get maxExtent => 136;

  @override
  bool shouldRebuild(covariant _Cabecalho antigo) => true;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final tema = Theme.of(context);
    final total = c.visiveis.length;

    return Material(
      color: tema.colorScheme.surface,
      child: Column(
        children: [
          // alça para arrastar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: tema.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: tema.colorScheme.primaryContainer,
                    child: Icon(Icons.pedal_bike, size: 20, color: tema.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Acidentes com bike',
                            style: tema.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            Text('$total encontrados', style: tema.textTheme.bodySmall),
                            if (c.filtro != Filtro.todos) ...[
                              Text(' · ', style: tema.textTheme.bodySmall),
                              GestureDetector(
                                onTap: () => c.definirFiltro(Filtro.todos),
                                child: Text('Limpar filtro',
                                    style: tema.textTheme.bodySmall
                                        ?.copyWith(color: tema.colorScheme.primary)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: aoFechar),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                for (final f in Filtro.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_rotulosFiltro[f]!),
                      selected: c.filtro == f,
                      onSelected: (_) => c.definirFiltro(f),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _TelaLarga extends StatelessWidget {
  const _TelaLarga(this.c);
  final DashboardController c;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            if (c.erroApi != null)
              MaterialBanner(content: Text(c.erroApi!), actions: const [SizedBox.shrink()]),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: _Mapa(c)),
                        Positioned(top: 12, left: 12, right: 72, child: _FaixaCamadas(c)),
                        Positioned(top: 12, right: 12, child: _BotoesFlutuantes(c)),
                        Positioned(top: 64, left: 12, child: SeloEstado(c)),
                        if (c.selecionado != null)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: _Detalhe(c.selecionado!, onFechar: c.limparSelecao),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 360, child: _PainelLista(c)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PainelLista extends StatelessWidget {
  const _PainelLista(this.c);
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    final lista = c.visiveis;
    final tema = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Acidentes com bike · ${lista.length} encontrados',
                  style: tema.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in Filtro.values)
                    ChoiceChip(
                      label: Text(_rotulosFiltro[f]!),
                      selected: c.filtro == f,
                      onSelected: (_) => c.definirFiltro(f),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: lista.isEmpty
              ? const Center(child: Text('Nenhum acidente neste filtro'))
              : ListView.separated(
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => ItemAcidente(c, lista[i], c.selecionar),
                ),
        ),
      ],
    );
  }
}


class _Mapa extends StatelessWidget {
  const _Mapa(this.c);
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    final grupos = c.mostrarAcidentes ? agrupar(c.visiveis, c.zoom) : const <Grupo>[];

    return FlutterMap(
      mapController: c.mapController,
      options: MapOptions(
        initialCenter: const LatLng(-8.0476, -34.877),   // Recife
        initialZoom: 12,
        // o zoom decide como os acidentes se agrupam; atualiza depois do quadro
        onPositionChanged: (camera, _) => WidgetsBinding.instance
            .addPostFrameCallback((_) => c.definirZoom(camera.zoom)),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.bikesafe.app',
        ),
        if (c.mostrarCiclovias) PolylineLayer(polylines: c.polCiclovias),
        if (c.mostrarCiclofaixas) PolylineLayer(polylines: c.polCiclofaixas),
        if (c.mostrarEstacoes)
          MarkerLayer(markers: [for (final e in c.estacoes) _estacao(context, e)]),
        MarkerLayer(markers: [
          for (final g in grupos) g.unico ? _pino(g.itens.first) : _cluster(g),
        ]),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [TextSourceAttribution('© OpenStreetMap')],
        ),
      ],
    );
  }

  Marker _estacao(BuildContext context, EstacaoBike e) => Marker(
        point: e.ponto,
        width: 28,
        height: 28,
        child: GestureDetector(
          onTap: () => _mostrarEstacao(context, e),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.indigo.shade600,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black38)],
            ),
            child: const Icon(Icons.local_parking, size: 16, color: Colors.white),
          ),
        ),
      );

  void _mostrarEstacao(BuildContext context, EstacaoBike e) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(e.nome ?? 'Estação ${e.codigo}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (e.localizacao != null) Text(e.localizacao!),
              if (e.bairro != null) Text(e.bairro!),
              if (e.capacidade != null) Text('Capacidade: ${e.capacidade!.round()} bicicletas'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
          ],
        ),
      );

  Marker _pino(Acidente a) {
    final selecionado = identical(a, c.selecionado);

    return Marker(
      point: a.ponto,
      width: 30,
      height: 30,
      child: GestureDetector(
        onTap: () => c.selecionar(a),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: a.naCiclovia ? Colors.red.shade600 : Colors.blue.shade600,
            border: Border.all(color: Colors.white, width: selecionado ? 3 : 2),
            boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black38)],
          ),
          child: const Icon(Icons.pedal_bike, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  Marker _cluster(Grupo g) {
    // quanto mais acidentes, maior o círculo
    final tamanho = 34.0 + (g.total.clamp(1, 50) / 50) * 18;

    return Marker(
      point: g.ponto,
      width: tamanho,
      height: tamanho,
      child: GestureDetector(
        onTap: () => c.aproximar(g.ponto),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal.shade600,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black38)],
          ),
          child: Text(
            '${g.total}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _Detalhe extends StatelessWidget {
  const _Detalhe(this.a, {required this.onFechar});
  final Acidente a;
  final VoidCallback onFechar;

  @override
  Widget build(BuildContext context) {
    final linhas = <String>[
      '${a.bairro ?? ''} · ${a.data ?? ''} ${a.hora ?? ''}',
      if (a.natureza != null) a.natureza!,
      for (final v in a.ciclovias.where((v) => v.distM != null))
        'Rede ${v.rede}: ${v.rota ?? '?'} a ${v.distM!.round()} m'
            '${v.naCiclovia ? ' (na ciclovia)' : ''}',
      if (a.estacao?.distM != null)
        'Estação ${a.estacao!.nome} a ${a.estacao!.distM!.round()} m',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${a.endereco ?? 'Endereço desconhecido'}'
                    '${a.numero != null ? ', ${a.numero}' : ''}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final l in linhas) Text(l, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: onFechar),
          ],
        ),
      ),
    );
  }
}
