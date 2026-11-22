import 'package:bikesafe_app/dashboard_controller.dart';
import 'package:flutter/material.dart';

/// Cartão da Home: "Estação mais perto de você" e os acidentes ao redor dela.
class CardEstacaoProxima extends StatelessWidget {
  const CardEstacaoProxima(this.c, {super.key});

  final DashboardController c;

  String _metros(double m) => m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final p = c.perto;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pedal_bike, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Estação mais perto de você',
                    style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (c.erroLocal != null) ...[
            Text(c.erroLocal!, style: TextStyle(color: cs.error)),
            const SizedBox(height: 12),
          ],

          if (p != null) ...[
            Text(p.estacao.nome ?? p.estacao.codigo!,
                style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('A ${_metros(p.distanciaM)} de você',
                style: tema.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            Text(
              p.acidentes.isEmpty
                  ? 'Nenhum acidente registrado a até ${p.raioM.round()} m dela.'
                  : '${p.acidentes.length} acidente(s) a até ${p.raioM.round()} m dela.',
              style: tema.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            for (final a in p.acidentes.take(3))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.circle, size: 10, color: Color(0xFFC2410C)),
                title: Text(a.endereco ?? 'Endereço desconhecido',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text([a.bairro, a.dataBr].whereType<String>().join(' · ')),
                onTap: () => c.verNoMapa(a),
              ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: c.buscandoLocal ? null : c.buscarEstacaoProxima,
                  icon: c.buscandoLocal
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: Text(p == null ? 'Usar minha localização' : 'Atualizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}