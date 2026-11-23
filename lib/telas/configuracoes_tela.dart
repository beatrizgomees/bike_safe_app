import 'package:bikesafe_app/config.dart';
import 'package:flutter/material.dart';

/// Aba Ajustes: perfil, notificações, aparência, sobre/servidor e sair.
class ConfiguracoesTela extends StatefulWidget {
  const ConfiguracoesTela({super.key, required this.aoSair});

  final VoidCallback aoSair;

  @override
  State<ConfiguracoesTela> createState() => _ConfiguracoesTelaState();
}

class _ConfiguracoesTelaState extends State<ConfiguracoesTela> {
  String get _iniciais {
    final partes = Config.perfilNome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    final primeira = partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }

  Future<void> _notificar({bool? acidentes, bool? rota}) async {
    await Config.salvarNotificacoes(acidentes: acidentes, rota: rota);
    if (mounted) setState(() {});
  }

  void _sobre() => showAboutDialog(
        context: context,
        applicationName: 'Bike Safe',
        applicationVersion: '1.0',
        applicationIcon: const Icon(Icons.pedal_bike, size: 36),
        children: const [
          Text('Acidentes com ciclistas no Recife, cruzados com ciclovias, ciclofaixas '
              'e estações de bicicleta. Dados abertos da Prefeitura do Recife.'),
        ],
      );

  Future<void> _servidor() async {
    final host = TextEditingController(text: Config.host);
    final porta = TextEditingController(text: Config.apiPorta);

    final salvar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: host,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                helperText: 'Emulador Android: 10.0.2.2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: porta,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Porta da API', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );

    if (salvar != true) return;

    final p = int.tryParse(porta.text.trim());
    if (host.text.trim().isEmpty || p == null || p < 1 || p > 65535) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confira o endereço e a porta do servidor.')),
        );
      }
      return;
    }

    await Config.salvarServidor(host: host.text.trim(), apiPorta: '$p', brokerPorta: Config.brokerPorta);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Servidor salvo. Reabra o app para reconectar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    final nome = Config.perfilNome.isEmpty ? 'Sem nome' : Config.perfilNome;
    final linhaPerfil =
        [Config.perfilEmail, Config.perfilBairro].where((s) => s.isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Ajustes', style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Perfil
            _Caixa(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  child: Text(_iniciais, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: linhaPerfil.isEmpty ? null : Text(linhaPerfil),
                trailing: const Icon(Icons.chevron_right),
                // onTap: abra aqui a sua tela de editar perfil, se tiver
              ),
            ),

            const _Secao('Notificações'),
            _Caixa(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Acidentes novos perto de mim'),
                    value: Config.notificarAcidentes,
                    onChanged: (v) => _notificar(acidentes: v),
                  ),
                  Divider(height: 1, color: cs.outlineVariant),
                  SwitchListTile(
                    title: const Text('Acidentes na minha rota'),
                    value: Config.notificarRota,
                    onChanged: (v) => _notificar(rota: v),
                  ),
                ],
              ),
            ),

            const _Secao('Aparência'),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: Config.temaModo,
              builder: (context, modo, _) => SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
                ],
                selected: {modo},
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                onSelectionChanged: (s) => Config.salvarTema(s.first),
              ),
            ),

            const _Secao('Sobre e avançado'),
            _Caixa(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Sobre o Bike Safe'),
                    subtitle: const Text('Dados abertos da Prefeitura do Recife'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _sobre,
                  ),
                  Divider(height: 1, color: cs.outlineVariant),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sair
            OutlinedButton.icon(
              onPressed: widget.aoSair,
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 0, 8),
      child: Text(texto,
          style: tema.textTheme.labelLarge?.copyWith(
              color: tema.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
    );
  }
}

/// Fundo branco, borda fina e cantos de 16, como os cartões do design.
class _Caixa extends StatelessWidget {
  const _Caixa({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}