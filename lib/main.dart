import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'dashboard_controller.dart';
import 'models.dart';

void main() => runApp(const BikeSafeApp());

class BikeSafeApp extends StatelessWidget {
  const BikeSafeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bike Safe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const DashboardPage(),
      );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final c = DashboardController();

  @override
  void initState() {
    super.initState();
    c.iniciar();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Bike Safe'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  avatar: Icon(Icons.circle, size: 12,
                      color: c.estado == 'ao vivo' ? Colors.green : Colors.orange),
                  label: Text(c.estado),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _BarraResumo(c.resumo),
              if (c.erroApi != null)
                MaterialBanner(
                  content: Text(c.erroApi!),
                  actions: const [SizedBox.shrink()],
                ),
              Expanded(
                child: LayoutBuilder(builder: (context, caixa) {
                  final mapa = _Mapa(c);
                  final lista = _Lista(c);

                  // telas largas: mapa ao lado da lista; estreitas (celular): uma sobre a outra
                  return caixa.maxWidth >= 800
                      ? Row(children: [
                          Expanded(child: mapa),
                          SizedBox(width: 360, child: lista),
                        ])
                      : Column(children: [
                          Expanded(flex: 3, child: mapa),
                          Expanded(flex: 2, child: lista),
                        ]);
                }),
              ),
            ],
          ),
        ),
      );
}

class _BarraResumo extends StatelessWidget {
  const _BarraResumo(this.r);
  final Resumo r;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Wrap(
          spacing: 28,
          runSpacing: 6,
          children: [
            _Numero('${r.acidentesBike}', 'acidentes com bike'),
            _Numero('${r.geocodificados}', 'localizados no mapa'),
            _Numero('${r.emCiclovia}', 'em ciclovia'),
            _Numero('${r.comEstacaoNoRaio}', 'perto de estação'),
          ],
        ),
      );
}

class _Numero extends StatelessWidget {
  const _Numero(this.valor, this.rotulo);
  final String valor, rotulo;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valor, style: Theme.of(context).textTheme.titleLarge),
          Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _Mapa extends StatelessWidget {
  const _Mapa(this.c);
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    final comPosicao = c.acidentes.where((a) => a.temPosicao);

    return Stack(
      children: [
        FlutterMap(
          mapController: c.mapController,
          options: const MapOptions(
            initialCenter: LatLng(-8.0476, -34.877),   // Recife
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.bikesafe.app',
            ),
            PolylineLayer(polylines: c.ciclovias),
            MarkerLayer(markers: [
              for (final a in comPosicao)
                Marker(
                  point: a.ponto,
                  width: 24,
                  height: 24,
                  child: GestureDetector(
                    onTap: () => c.selecionar(a),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (a.naCiclovia ? Colors.red : Colors.blue).withOpacity(0.8),
                        border: Border.all(
                          color: Colors.white,
                          width: identical(a, c.selecionado) ? 3 : 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
            const RichAttributionWidget(
              attributions: [TextSourceAttribution('© OpenStreetMap')],
            ),
          ],
        ),
        if (c.selecionado != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _Detalhe(c.selecionado!, onFechar: c.limparSelecao),
          ),
      ],
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

class _Lista extends StatelessWidget {
  const _Lista(this.c);
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    if (c.acidentes.isEmpty) {
      return const Center(child: Text('Aguardando acidentes…'));
    }

    return ListView.separated(
      itemCount: c.acidentes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final a = c.acidentes[i];

        return ListTile(
          selected: identical(a, c.selecionado),
          leading: Icon(Icons.pedal_bike, color: a.naCiclovia ? Colors.red : Colors.blue),
          title: Text(a.endereco ?? 'Endereço desconhecido', maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text('${a.bairro ?? ''} · ${a.data ?? ''} ${a.hora ?? ''}'),
          trailing: Text(a.naCiclovia ? 'em ciclovia' : 'fora',
              style: Theme.of(context).textTheme.labelSmall),
          onTap: () => c.selecionar(a),
        );
      },
    );
  }
}
