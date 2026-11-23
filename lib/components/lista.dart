import 'package:bikesafe_app/dashboard_controller.dart';
import 'package:bikesafe_app/models/acidente.dart';
import 'package:flutter/material.dart';

// Mesmas cores da Home e do mapa
const _laranja = Color(0xFFC2410C);
const _laranjaFundo = Color(0xFFFBE3D3);
const _laranjaTexto = Color(0xFF7A2E0A);

/// Lista de acidentes em cartões, no visual da aba Reportados.
class Lista extends StatelessWidget {
  const Lista(this.c, {super.key, this.aoTocar, this.padding});

  final DashboardController c;
  final void Function(Acidente a)? aoTocar; // padrão: só seleciona
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (c.acidentes.isEmpty) {
      return const Center(child: Text('Aguardando acidentes…'));
    }

    return ListView.separated(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 0, 20, 96), // espaço para o botão flutuante
      itemCount: c.acidentes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final a = c.acidentes[i];

        return _CartaoAcidente(
          a,
          selecionado: identical(a, c.selecionado),
          aoTocar: () => (aoTocar ?? c.selecionar)(a),
        );
      },
    );
  }
}

class _CartaoAcidente extends StatelessWidget {
  const _CartaoAcidente(this.a, {required this.selecionado, required this.aoTocar});

  final Acidente a;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    final titulo = (a.natureza != null && a.natureza!.isNotEmpty) ? a.natureza! : 'Acidente';
    final endereco = [a.endereco, a.numero].where((s) => s != null && s.isNotEmpty).join(', ');
    final linha = [endereco.isEmpty ? null : endereco, a.dataBr]
        .where((s) => s != null && s.isNotEmpty)
        .join(' · ');
    final detalhe = [a.bairro, a.horaBr].where((s) => s != null && s.isNotEmpty).join(' · ');

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selecionado ? cs.primary : cs.outlineVariant,
          width: selecionado ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone em círculo laranja claro
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: _laranjaFundo, shape: BoxShape.circle),
                child: const Icon(Icons.campaign_outlined, color: _laranjaTexto, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        _Etiqueta(naCiclovia: a.naCiclovia, cruzado: a.ciclovias.isNotEmpty),
                      ],
                    ),
                    if (linha.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(linha,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                    if (detalhe.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(detalhe, style: tema.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Na ciclovia" em verde, "Fora da ciclovia" em laranja; nada se não foi cruzado.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.naCiclovia, required this.cruzado});

  final bool naCiclovia, cruzado;

  @override
  Widget build(BuildContext context) {
    if (!cruzado) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: naCiclovia ? cs.primaryContainer : _laranjaFundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        naCiclovia ? 'Na ciclovia' : 'Fora da ciclovia',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: naCiclovia ? cs.onPrimaryContainer : _laranjaTexto,
        ),
      ),
    );
  }
}

// Mantido para quem usa a cor do marcador em outro lugar
const corAcidente = _laranja;