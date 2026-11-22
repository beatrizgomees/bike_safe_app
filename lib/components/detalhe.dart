import 'package:bikesafe_app/models/acidente.dart';
import 'package:flutter/material.dart';

// Mesmas cores da Home para "fora da ciclovia"
const _laranjaFundo = Color(0xFFFBE3D3);
const _laranjaTexto = Color(0xFF7A2E0A);

/// Painel que sobe do rodapé do mapa com os dados do acidente selecionado.
class Detalhe extends StatelessWidget {
  const Detalhe(this.a, {super.key, required this.onFechar});

  final Acidente a;
  final VoidCallback onFechar;

  String _metros(double? m) {
    if (m == null) return '—';
    return m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    final endereco = [a.endereco, a.numero].where((s) => s != null && s.isNotEmpty).join(', ');
    final quando = a.quandoBr;
    final subtitulo = [a.bairro, quando].where((s) => s != null && s.isNotEmpty).join(' · ');

    // Ciclovia mais próxima: a de menor distância entre as que foram cruzadas
    final comDistancia = a.ciclovias.where((cv) => cv.distM != null).toList()
      ..sort((x, y) => x.distM!.compareTo(y.distM!));
    final ciclovia = comDistancia.isEmpty ? null : comDistancia.first;
    final nomeCiclovia = ciclovia?.rota ?? ciclovia?.rede ?? 'Ciclovia';

    return Material(
      color: cs.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alça
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Endereço, bairro e data, e o botão de fechar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          endereco.isEmpty ? 'Endereço desconhecido' : endereco,
                          style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (subtitulo.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(subtitulo,
                              style: tema.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'Fechar',
                    onPressed: onFechar,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Etiquetas: situação em relação à ciclovia e natureza
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (a.ciclovias.isNotEmpty)
                    _Etiqueta(
                      a.naCiclovia ? 'Na ciclovia' : 'Fora da ciclovia',
                      fundo: a.naCiclovia ? cs.primaryContainer : _laranjaFundo,
                      texto: a.naCiclovia ? cs.onPrimaryContainer : _laranjaTexto,
                    ),
                  if (a.natureza != null && a.natureza!.isNotEmpty)
                    _Etiqueta(a.natureza!, fundo: cs.surfaceContainerHighest, texto: cs.onSurface),
                ],
              ),
              const SizedBox(height: 16),

              // Linhas de detalhe
              Divider(height: 1, color: cs.outlineVariant),
              _Linha(
                'Ciclovia mais próxima',
                ciclovia == null ? '—' : '$nomeCiclovia · ${_metros(ciclovia.distM)}',
              ),
              _Linha('Estação mais próxima', _metros(a.estacao?.distM)),
              _Linha('Estações em 300 m', '${a.estacao?.estacoesNoRaio ?? '—'}'),
              _Linha('Protocolo', a.protocolo, ultima: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.rotulo, {required this.fundo, required this.texto});

  final String rotulo;
  final Color fundo, texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(8)),
      child: Text(rotulo,
          style: TextStyle(color: texto, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

/// Uma linha "rótulo .......... valor", com divisória embaixo.
class _Linha extends StatelessWidget {
  const _Linha(this.rotulo, this.valor, {this.ultima = false});

  final String rotulo, valor;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: ultima
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: tema.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: tema.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
