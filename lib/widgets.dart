import 'package:flutter/material.dart';

import 'dashboard_controller.dart';
import 'models.dart';

String doisDigitos(int n) => n.toString().padLeft(2, '0');

String dataHora(DateTime d) =>
    '${doisDigitos(d.day)}/${doisDigitos(d.month)}/${d.year} '
    '${doisDigitos(d.hour)}:${doisDigitos(d.minute)}';

/// "ao vivo" (verde) ou "offline · dados do banco" (laranja).
class SeloEstado extends StatelessWidget {
  const SeloEstado(this.c, {super.key});
  final DashboardController c;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: c.detalheBroker ?? c.estado,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: c.aoVivo ? Colors.green : Colors.orange),
                const SizedBox(width: 6),
                Text(c.estado, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ),
      );
}

/// Uma linha de acidente: endereço, bairro, data, situação e distância até a ciclovia.
class ItemAcidente extends StatelessWidget {
  const ItemAcidente(this.c, this.a, this.aoEscolher, {super.key});

  final DashboardController c;
  final Acidente a;
  final void Function(Acidente) aoEscolher;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cor = a.naCiclovia ? Colors.red.shade700 : Colors.blue.shade700;

    final dist = a.ciclovias
        .where((v) => v.distM != null)
        .map((v) => v.distM!)
        .fold<double?>(null, (m, d) => m == null || d < m ? d : m);

    return ListTile(
      selected: identical(a, c.selecionado),
      isThreeLine: true,
      title: Text(
        '${a.endereco ?? 'Endereço desconhecido'}${a.numero != null ? ', ${a.numero}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${a.bairro ?? ''} · ${a.data ?? ''} ${a.hora ?? ''}'),
          if (a.natureza != null) Text(a.natureza!, maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(
            children: [
              Icon(Icons.pedal_bike, size: 14, color: cor),
              const SizedBox(width: 4),
              Text(a.naCiclovia ? 'Em ciclovia' : 'Fora da ciclovia',
                  style: tema.textTheme.bodySmall?.copyWith(color: cor)),
            ],
          ),
        ],
      ),
      trailing: dist == null
          ? null
          : Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tema.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.near_me, size: 18, color: tema.colorScheme.primary),
                  Text('${dist.round()} m', style: tema.textTheme.labelSmall),
                ],
              ),
            ),
      onTap: () => aoEscolher(a),
    );
  }
}
