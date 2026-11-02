import 'package:flutter/material.dart';

import '../dashboard_controller.dart';
import '../widgets.dart';
import 'reportes_tela.dart';

class HomeTela extends StatelessWidget {
  const HomeTela(this.c, {super.key});
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final r = c.resumo;
    final recentes = c.acidentes.take(5).toList();
    final pct = r.geocodificados == 0 ? null : (100 * r.emCiclovia / r.geocodificados).round();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: c.atualizar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bike Safe',
                          style: tema.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Acidentes com ciclistas no Recife', style: tema.textTheme.bodyMedium),
                    ],
                  ),
                ),
                SeloEstado(c),
              ],
            ),
            const SizedBox(height: 16),
            if (c.erroApi != null)
              Card(
                color: tema.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(c.erroApi!, style: TextStyle(color: tema.colorScheme.onErrorContainer)),
                ),
              ),
            Row(
              children: [
                Expanded(child: _Cartao('${r.acidentesBike}', 'acidentes com bike', Icons.pedal_bike)),
                const SizedBox(width: 12),
                Expanded(child: _Cartao('${r.geocodificados}', 'localizados no mapa', Icons.place)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Cartao('${r.emCiclovia}', 'em ciclovia', Icons.alt_route)),
                const SizedBox(width: 12),
                Expanded(
                    child: _Cartao('${r.comEstacaoNoRaio}', 'perto de estação', Icons.local_parking)),
              ],
            ),
            if (pct != null) ...[
              const SizedBox(height: 12),
              Card(
                color: tema.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '$pct% dos acidentes localizados ocorreram a até 30 m de uma ciclovia '
                    'ou ciclofaixa.',
                    style: tema.textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => abrirReporte(context, c),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Reportar um acidente'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Text('Últimos acidentes', style: tema.textTheme.titleMedium)),
                TextButton(onPressed: () => c.irParaAba(1), child: const Text('Ver no mapa')),
              ],
            ),
            if (recentes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aguardando acidentes…')),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < recentes.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ItemAcidente(c, recentes[i], c.selecionarNoMapa),
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

class _Cartao extends StatelessWidget {
  const _Cartao(this.valor, this.rotulo, this.icone);
  final String valor, rotulo;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: tema.colorScheme.primary),
            const SizedBox(height: 8),
            Text(valor, style: tema.textTheme.headlineMedium),
            Text(rotulo, style: tema.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
