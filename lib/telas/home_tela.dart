<<<<<<< HEAD
import 'package:flutter/material.dart';

import '../dashboard_controller.dart';
import '../widgets.dart';
import 'reportes_tela.dart';

class HomeTela extends StatelessWidget {
  const HomeTela(this.c, {super.key});
=======
import 'package:bikesafe_app/components/card_estacao_proxima.dart';
import 'package:bikesafe_app/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:bikesafe_app/models/acidente.dart';

const _laranja = Color(0xFFC2410C);
const _laranjaFundo = Color(0xFFFBE3D3);
const _laranjaTexto = Color(0xFF7A2E0A);

class HomeTela extends StatelessWidget {
  const HomeTela(this.c, {super.key});

>>>>>>> feat/screen-features
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final r = c.resumo;
<<<<<<< HEAD
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
=======
    final ultimos = c.acidentes.take(3).toList();
    final proporcao = r.geocodificados == 0 ? 0.0 : r.emCiclovia / r.geocodificados;

    return Scaffold(
      backgroundColor: tema.colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Título e estado da conexão
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: Text('Bike Safe',
                        style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  // _ChipConexao(aoVivo: c.aoVivo),
                ],
              ),
            ),

            if (c.erroApi != null) ...[
              Card(
                margin: EdgeInsets.zero,
>>>>>>> feat/screen-features
                color: tema.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(c.erroApi!, style: TextStyle(color: tema.colorScheme.onErrorContainer)),
                ),
              ),
<<<<<<< HEAD
            Row(
              children: [
                Expanded(child: _Cartao('${r.acidentesBike}', 'acidentes com bike', Icons.pedal_bike)),
                const SizedBox(width: 12),
                Expanded(child: _Cartao('${r.geocodificados}', 'localizados no mapa', Icons.place)),
=======
              const SizedBox(height: 14),
            ],

            _TituloSecao('Resumo dos acidentes'),
            const SizedBox(height: 12),

            // Quatro números
            Row(
              children: [
                Expanded(child: _CardNumero(rotulo: 'Com bicicleta', valor: r.acidentesBike)),
                const SizedBox(width: 12),
                Expanded(child: _CardNumero(rotulo: 'Localizados', valor: r.geocodificados)),
>>>>>>> feat/screen-features
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
<<<<<<< HEAD
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
=======
                Expanded(
                  child: _CardNumero(rotulo: 'Junto a ciclovia', valor: r.emCiclovia, destaque: true),
                ),
                const SizedBox(width: 12),
                Expanded(child: _CardNumero(rotulo: 'Estação a 300 m', valor: r.comEstacaoNoRaio)),
              ],
            ),
            const SizedBox(height: 14),

            // Estação mais perto (usa a localização)
            CardEstacaoProxima(c),
            const SizedBox(height: 14),

            // Proporção em ciclovia
            _Caixa(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Acidentes em ciclovia',
                            style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Text('${(proporcao * 100).round()}%',
                          style: tema.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold, color: tema.colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: proporcao,
                      minHeight: 10,
                      backgroundColor: tema.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${r.emCiclovia} de ${r.geocodificados} acidentes localizados ocorreram '
                    'a até 30 m de uma ciclovia ou ciclofaixa.',
                    style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Últimos acidentes
            Row(
              children: [
                Expanded(child: _TituloSecao('Últimos acidentes')),
                TextButton(
                  onPressed: () => c.irParaAba(1),
                  child: const Text('Ver no mapa'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _Caixa(
              child: ultimos.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aguardando acidentes…'),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < ultimos.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: tema.colorScheme.outlineVariant),
                          _ItemAcidente(ultimos[i], aoTocar: () => c.verNoMapa(ultimos[i])),
                        ],
                      ],
                    ),
            ),
>>>>>>> feat/screen-features
          ],
        ),
      ),
    );
  }
}

<<<<<<< HEAD
class _Cartao extends StatelessWidget {
  const _Cartao(this.valor, this.rotulo, this.icone);
  final String valor, rotulo;
  final IconData icone;
=======
class _ChipConexao extends StatelessWidget {
  const _ChipConexao({required this.aoVivo});

  final bool aoVivo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fundo = aoVivo ? cs.primaryContainer : cs.surfaceContainerHighest;
    final texto = aoVivo ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(14)),
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
              style: TextStyle(color: texto, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;
>>>>>>> feat/screen-features

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

<<<<<<< HEAD
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
=======
    return Text(texto,
        style: tema.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600, color: tema.colorScheme.onSurfaceVariant));
  }
}

/// Fundo branco, borda fina e cantos de 16, como os cartões do design.
class _Caixa extends StatelessWidget {
  const _Caixa({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class _CardNumero extends StatelessWidget {
  const _CardNumero({required this.rotulo, required this.valor, this.destaque = false});

  final String rotulo;
  final int valor;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return _Caixa(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo,
              style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('$valor',
              style: tema.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: destaque ? tema.colorScheme.primary : null,
              )),
        ],
      ),
    );
  }
}

class _ItemAcidente extends StatelessWidget {
  const _ItemAcidente(this.a, {required this.aoTocar});

  final Acidente a;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final endereco = [a.endereco, a.numero].where((s) => s != null && s.isNotEmpty).join(', ');
    final detalhes = [a.bairro, a.quandoBr, a.natureza].where((s) => s != null && s.isNotEmpty).join(' · ');

    // Distância até a ciclovia mais próxima, quando o acidente foi cruzado com a malha
    final distancias = [for (final cv in a.ciclovias) if (cv.distM != null) cv.distM!];
    final menor = distancias.isEmpty ? null : distancias.reduce((x, y) => x < y ? x : y);

    return InkWell(
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 6, right: 12),
              decoration: const BoxDecoration(color: _laranja, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(endereco.isEmpty ? 'Endereço desconhecido' : endereco,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  if (detalhes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(detalhes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodySmall
                            ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
                  ],
                  if (menor != null) ...[
                    const SizedBox(height: 6),
                    _Etiqueta(
                      a.naCiclovia
                          ? 'Na ciclovia · ${menor.round()} m'
                          : 'Fora da ciclovia · ${menor.round()} m',
                      naCiclovia: a.naCiclovia,
                    ),
                  ],
                ],
              ),
            ),
>>>>>>> feat/screen-features
          ],
        ),
      ),
    );
  }
}
<<<<<<< HEAD
=======

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, {required this.naCiclovia});

  final String texto;
  final bool naCiclovia;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: naCiclovia ? cs.primaryContainer : _laranjaFundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: naCiclovia ? cs.onPrimaryContainer : _laranjaTexto,
        ),
      ),
    );
  }
}
>>>>>>> feat/screen-features
