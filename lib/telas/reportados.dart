import 'package:bikesafe_app/dashboard_controller.dart';
import 'package:bikesafe_app/models/reporte.dart';
import 'package:bikesafe_app/reportes_api.dart';
import 'package:bikesafe_app/telas/reportar_tela.dart';
import 'package:flutter/material.dart';

const _laranjaFundo = Color(0xFFFBE3D3);
const _laranjaTexto = Color(0xFF7A2E0A);

/// Aba Reportados: as ocorrências que o usuário relatou e o botão "Reportar acidente".
class ReportadosTela extends StatefulWidget {
  const ReportadosTela(this.c, {super.key});

  final DashboardController c; // mantido para a mesma assinatura das outras abas

  @override
  State<ReportadosTela> createState() => _ReportadosTelaState();
}

class _ReportadosTelaState extends State<ReportadosTela> {
  final _api = ReportesApi();

  List<Reporte> _reportes = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await _api.listar();
      if (!mounted) return;
      setState(() => _reportes = lista);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Não consegui carregar seus reportes. Puxe para tentar de novo.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _novoReporte() async {
    final enviado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ReportarTela()),
    );

    if (enviado != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte enviado. Obrigado!')),
    );
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _carregar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 104), // espaço para o botão flutuante
            children: [
              Text('Reportados',
                  style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Ocorrências que você relatou. Elas ficam guardadas na base do Bike Safe.',
                style: tema.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
              ),
              const SizedBox(height: 16),

              if (_carregando && _reportes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_erro != null && _reportes.isEmpty)
                _Aviso(texto: _erro!, botao: 'Tentar de novo', aoTocar: _carregar)
              else if (_reportes.isEmpty)
                const _Aviso(
                  texto: 'Você ainda não reportou nenhuma ocorrência. '
                      'Use o botão abaixo quando presenciar um acidente.',
                )
              else
                for (final r in _reportes) ...[
                  _CartaoReporte(r),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novoReporte,
        icon: const Icon(Icons.add),
        label: const Text('Reportar acidente'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
    );
  }
}

class _CartaoReporte extends StatelessWidget {
  const _CartaoReporte(this.r);

  final Reporte r;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final linha = [r.endereco, r.dataRotulo].whereType<String>().join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      child: Text(r.tipoRotulo,
                          style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(r.statusRotulo,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimaryContainer)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(linha,
                    style: tema.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                if (r.descricao != null) ...[
                  const SizedBox(height: 4),
                  Text(r.descricao!, style: tema.textTheme.bodyMedium?.copyWith(height: 1.45)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, this.botao, this.aoTocar});

  final String texto;
  final String? botao;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Text(texto,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
          if (botao != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: aoTocar, child: Text(botao!)),
          ],
        ],
      ),
    );
  }
}