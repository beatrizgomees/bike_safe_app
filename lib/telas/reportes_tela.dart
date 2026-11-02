import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../dashboard_controller.dart';
import '../models.dart';
import '../widgets.dart';

const _iconesTipo = {
  'colisao': Icons.car_crash,
  'queda': Icons.personal_injury,
  'atropelamento': Icons.directions_walk,
  'outro': Icons.report_problem_outlined,
};

void abrirReporte(BuildContext context, DashboardController c) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReportarTela(c)));

class ReportesTela extends StatelessWidget {
  const ReportesTela(this.c, {super.key});
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus reportados')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirReporte(context, c),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Reportar'),
      ),
      body: RefreshIndicator(
        onRefresh: c.carregarReportes,
        child: c.reportes.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.campaign_outlined, size: 64, color: tema.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Você ainda não reportou nenhum acidente.',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use o botão Reportar para marcar no mapa um acidente que você viu ou sofreu.',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium,
                  ),
                  if (c.erroReportes != null) ...[
                    const SizedBox(height: 16),
                    Text(c.erroReportes!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: tema.colorScheme.error)),
                  ],
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: c.reportes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) => _ItemReporte(c, c.reportes[i]),
              ),
      ),
    );
  }
}

class _ItemReporte extends StatelessWidget {
  const _ItemReporte(this.c, this.r);
  final DashboardController c;
  final Reporte r;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return ListTile(
      isThreeLine: true,
      leading: CircleAvatar(
        backgroundColor: tema.colorScheme.primaryContainer,
        child: Icon(_iconesTipo[r.tipo] ?? Icons.report_problem_outlined,
            color: tema.colorScheme.primary),
      ),
      title: Text(r.tipoRotulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dataHora(r.criadoEm)),
          if (r.endereco != null) Text(r.endereco!, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (r.descricao != null) Text(r.descricao!, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: Chip(
        label: Text(r.status),
        visualDensity: VisualDensity.compact,
      ),
      onTap: () => c.verNoMapa(r.ponto),
    );
  }
}

class ReportarTela extends StatefulWidget {
  const ReportarTela(this.c, {super.key});
  final DashboardController c;

  @override
  State<ReportarTela> createState() => _ReportarTelaState();
}

class _ReportarTelaState extends State<ReportarTela> {
  final _mapa = MapController();
  final _descricao = TextEditingController();
  final _endereco = TextEditingController();

  String _tipo = 'colisao';
  bool _enviando = false;
  String? _erro;

  late final LatLng _inicio = _centroAtual();

  LatLng _centroAtual() {
    try {
      return widget.c.mapController.camera.center;
    } catch (_) {
      return const LatLng(-8.0476, -34.877);
    }
  }

  @override
  void dispose() {
    _descricao.dispose();
    _endereco.dispose();
    super.dispose();
  }

  String? _texto(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _enviar() async {
    final mensagens = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      await widget.c.enviarReporte(
        tipo: _tipo,
        ponto: _mapa.camera.center,
        descricao: _texto(_descricao),
        endereco: _texto(_endereco),
      );

      widget.c.irParaAba(2);
      navegador.pop();
      mensagens.showSnackBar(const SnackBar(content: Text('Reporte enviado. Obrigado!')));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _enviando = false;
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final zoomInicial = widget.c.zoom < 13 ? 14.0 : widget.c.zoom;

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar acidente')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapa,
                  options: MapOptions(initialCenter: _inicio, initialZoom: zoomInicial),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'br.bikesafe.app',
                    ),
                  ],
                ),
                IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.location_on, size: 44, color: Colors.red.shade600),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Arraste o mapa até o local do acidente',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final e in tiposReporte.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _endereco,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Endereço ou referência (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _descricao,
                    maxLength: 500,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'O que aconteceu? (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 8),
                    Text(_erro!, style: TextStyle(color: tema.colorScheme.error)),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _enviando ? null : _enviar,
                    child: _enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar reporte'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
