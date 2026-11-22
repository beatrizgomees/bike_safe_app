import 'package:bikesafe_app/location/location_service.dart';
import 'package:bikesafe_app/models/reporte.dart';
import 'package:bikesafe_app/reportes_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _laranja = Color(0xFFC2410C);

/// Formulário "Novo reporte": marca o local no mapa, escolhe o tipo e descreve.
/// Volta com `true` quando o reporte foi enviado.
class ReportarTela extends StatefulWidget {
  const ReportarTela({super.key});

  @override
  State<ReportarTela> createState() => _ReportarTelaState();
}

class _ReportarTelaState extends State<ReportarTela> {
  final _mapa = MapController();
  final _endereco = TextEditingController();
  final _descricao = TextEditingController();
  final _api = ReportesApi();

  String _tipo = tiposReporte.keys.first;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _irParaMinhaPosicao(silencioso: true);
  }

  @override
  void dispose() {
    _endereco.dispose();
    _descricao.dispose();
    super.dispose();
  }

  /// Centraliza o mapa onde o usuário está. Sem permissão, fica no centro do Recife.
  Future<void> _irParaMinhaPosicao({bool silencioso = false}) async {
    try {
      final eu = await LocalizacaoService().posicaoAtual();
      if (!mounted) return;
      _mapa.move(eu, 17);
    } on ErroLocalizacao catch (e) {
      if (!silencioso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
      }
    } catch (_) {}
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      await _api.enviar(
        tipo: _tipo,
        ponto: _mapa.camera.center, // o local é o centro do mapa, onde está o pino
        endereco: _endereco.text.trim().isEmpty ? null : _endereco.text.trim(),
        descricao: _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  InputDecoration _campo(ThemeData tema, String? dica) => InputDecoration(
        hintText: dica,
        filled: true,
        fillColor: tema.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tema.colorScheme.outline),
        ),
      );

  Widget _rotulo(ThemeData tema, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(texto,
            style: tema.textTheme.labelLarge?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
      );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLow,
        title: const Text('Novo reporte', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            // Mapa com o pino fixo no centro
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 280,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapa,
                      options: const MapOptions(
                        initialCenter: LatLng(-8.0476, -34.877), // Recife
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'br.bikesafe.app',
                        ),
                      ],
                    ),
                    // Pino: a ponta fica exatamente no centro do mapa
                    const IgnorePointer(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.location_on, size: 44, color: _laranja),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Mova o mapa para marcar o local',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: IconButton.filledTonal(
                        tooltip: 'Minha localização',
                        onPressed: () => _irParaMinhaPosicao(),
                        icon: const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _rotulo(tema, 'Tipo de ocorrência'),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: _campo(tema, null),
              items: [
                for (final t in tiposReporte.entries)
                  DropdownMenuItem(value: t.key, child: Text(t.value)),
              ],
              onChanged: _enviando ? null : (v) => setState(() => _tipo = v ?? _tipo),
            ),
            const SizedBox(height: 16),

            _rotulo(tema, 'Endereço (opcional)'),
            TextField(
              controller: _endereco,
              enabled: !_enviando,
              textCapitalization: TextCapitalization.words,
              decoration: _campo(tema, 'Ex.: Av. Agamenon Magalhães'),
            ),
            const SizedBox(height: 16),

            _rotulo(tema, 'Descrição (opcional)'),
            TextField(
              controller: _descricao,
              enabled: !_enviando,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: _campo(tema, 'O que aconteceu?'),
            ),
            const SizedBox(height: 4),

            Text(
              'O reporte vai direto para a base, mesmo sem conexão em tempo real, '
              'e aparece na aba Reportados.',
              style: tema.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
            ),

            if (_erro != null) ...[
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                color: cs.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_erro!, style: TextStyle(color: cs.onErrorContainer)),
                ),
              ),
            ],
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _enviando ? null : _enviar,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                textStyle: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : const Text('Enviar reporte'),
            ),
          ],
        ),
      ),
    );
  }
}