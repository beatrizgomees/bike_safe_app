import 'package:bikesafe_app/view_controllers/reportar_view_controller.dart';
import 'package:flutter/material.dart';

/// Formulário "Reportar acidente". Fecha com `true` quando o reporte é enviado.
class ReportarTela extends StatefulWidget {
  const ReportarTela({super.key});

  @override
  State<ReportarTela> createState() => _ReportarTelaState();
}

class _ReportarTelaState extends State<ReportarTela> {
  final _c = ReportarViewController();

  @override
  void initState() {
    super.initState();
    _c.localizar(); // já começa pegando a posição (e o endereço)
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();

    if (await _c.enviar() && mounted) Navigator.of(context).pop(true);
  }

  /// Texto do quadro "Onde?": endereço quando houver; senão, as coordenadas.
  Widget _textoLocal(ThemeData tema) {
    final cs = tema.colorScheme;

    if (_c.localizando) return const Text('Obtendo sua localização…');

    if (_c.posicao == null) {
      return Text(_c.erroLocal ?? 'Localização não obtida.',
          style: TextStyle(color: _c.erroLocal != null ? cs.error : null));
    }

    final coordenadas = '${_c.posicao!.latitude.toStringAsFixed(5)}, '
        '${_c.posicao!.longitude.toStringAsFixed(5)}';
    final e = _c.endereco;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          e != null ? e.resumo : 'Sua localização atual',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          _c.buscandoEndereco
              ? 'Buscando o endereço…'
              : (e != null && e.complemento.isNotEmpty ? e.complemento : coordenadas),
          style: tema.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar acidente')),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('O que aconteceu?', style: tema.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('Marque tudo o que se aplica.',
                style: tema.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ReportarViewController.tipos.entries)
                  FilterChip(
                    label: Text(t.value),
                    selected: _c.selecionado(t.key),
                    onSelected: _c.enviando ? null : (_) => _c.alternarTipo(t.key),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            Text('Onde?', style: tema.textTheme.titleSmall),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location, color: _c.posicao != null ? cs.primary : cs.outline),
                  const SizedBox(width: 12),
                  Expanded(child: _textoLocal(tema)),
                  if (_c.localizando)
                    const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    IconButton(
                      tooltip: 'Atualizar localização',
                      icon: const Icon(Icons.refresh),
                      onPressed: _c.enviando ? null : _c.localizar,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _c.descricao,
              enabled: !_c.enviando,
              maxLines: 3,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Detalhes (opcional)',
                hintText: 'Ex.: carro saiu da garagem sem olhar',
                border: OutlineInputBorder(),
              ),
            ),

            if (_c.erro != null) ...[
              const SizedBox(height: 8),
              Card(
                color: cs.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_c.erro!, style: TextStyle(color: cs.onErrorContainer)),
                ),
              ),
            ],
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _c.podeEnviar ? _enviar : null,
              icon: _c.enviando
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Enviar reporte'),
            ),
            if (_c.selecionados.isEmpty || _c.posicao == null) ...[
              const SizedBox(height: 8),
              Text(
                _c.selecionados.isEmpty
                    ? 'Marque pelo menos uma ocorrência.'
                    : 'Aguardando a localização.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}