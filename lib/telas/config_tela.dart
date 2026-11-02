import 'package:flutter/material.dart';

import '../config.dart';
import '../dashboard_controller.dart';

class ConfigTela extends StatefulWidget {
  const ConfigTela(this.c, {super.key});
  final DashboardController c;

  @override
  State<ConfigTela> createState() => _ConfigTelaState();
}

class _ConfigTelaState extends State<ConfigTela> {
  late final _host = TextEditingController(text: Config.host);
  late final _api = TextEditingController(text: Config.apiPorta);
  late final _broker = TextEditingController(text: '${Config.brokerPorta}');
  String? _erro;

  @override
  void dispose() {
    _host.dispose();
    _api.dispose();
    _broker.dispose();
    super.dispose();
  }

  bool _portaValida(int? p) => p != null && p >= 1 && p <= 65535;

  Future<void> _salvar() async {
    final mensagens = ScaffoldMessenger.of(context);
    final api = int.tryParse(_api.text.trim());
    final broker = int.tryParse(_broker.text.trim());

    if (_host.text.trim().isEmpty || !_portaValida(api) || !_portaValida(broker)) {
      setState(() => _erro = 'Confira o endereço e as portas (1 a 65535).');
      return;
    }

    setState(() => _erro = null);

    await Config.salvarServidor(host: _host.text, apiPorta: '$api', brokerPorta: broker!);
    widget.c.reconfigurar();

    mensagens.showSnackBar(const SnackBar(content: Text('Servidor salvo. Reconectando…')));
  }

  Future<void> _restaurar() async {
    final mensagens = ScaffoldMessenger.of(context);

    await Config.salvarServidor(host: '', apiPorta: '8000', brokerPorta: 9001);

    setState(() {
      _erro = null;
      _host.text = Config.host;
      _api.text = Config.apiPorta;
      _broker.text = '${Config.brokerPorta}';
    });

    widget.c.reconfigurar();
    mensagens.showSnackBar(const SnackBar(content: Text('Endereço padrão restaurado.')));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Secao('Servidor'),
          TextField(
            controller: _host,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Endereço do servidor',
              helperText: 'Emulador Android: 10.0.2.2 · celular: IP do computador na rede',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _api,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Porta da API',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _broker,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Porta do broker (WebSocket)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          if (_erro != null) ...[
            const SizedBox(height: 8),
            Text(_erro!, style: TextStyle(color: tema.colorScheme.error)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(onPressed: _salvar, child: const Text('Salvar e reconectar')),
              ),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _restaurar, child: const Text('Padrão')),
            ],
          ),
          const SizedBox(height: 24),

          _Secao('Conexão'),
          ListTile(
            leading: Icon(Icons.circle, size: 14, color: c.aoVivo ? Colors.green : Colors.orange),
            title: const Text('Broker (tempo real)'),
            subtitle: Text(c.aoVivo ? 'Conectado' : (c.detalheBroker ?? 'Desconectado')),
          ),
          ListTile(
            leading: Icon(Icons.circle,
                size: 14, color: c.erroApi == null ? Colors.green : Colors.red),
            title: const Text('API (banco de dados)'),
            subtitle: Text(c.erroApi ?? 'Respondendo em ${Config.apiUrl}'),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Atualização sem broker'),
            subtitle: const Text('Com o broker fora, o app consulta o banco neste intervalo.'),
            trailing: DropdownButton<int>(
              value: const [5, 15, 30, 60].contains(Config.intervaloOfflineSeg)
                  ? Config.intervaloOfflineSeg
                  : 15,
              items: [
                for (final s in const [5, 15, 30, 60])
                  DropdownMenuItem(value: s, child: Text('$s s')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                await Config.salvarIntervalo(v);
                c.reiniciarPolling();
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 24),

          _Secao('Aparência'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
              ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
            ],
            selected: {Config.temaModo.value},
            onSelectionChanged: (s) async {
              await Config.salvarTema(s.first);
              setState(() {});
            },
          ),
          const SizedBox(height: 24),

          _Secao('Sobre'),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Identificador deste aparelho'),
            subtitle: SelectableText(Config.dispositivo),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Bike Safe 1.0'),
            subtitle: Text('Dados abertos da Prefeitura do Recife e do OpenStreetMap.'),
          ),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          titulo,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}
