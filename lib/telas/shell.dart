import 'package:bikesafe_app/dashboard_controller.dart';
import 'package:bikesafe_app/telas/configuracoes_tela.dart';
import 'package:bikesafe_app/telas/home_tela.dart';
import 'package:bikesafe_app/telas/mapa.dart';
import 'package:bikesafe_app/telas/reportados.dart';
import 'package:bikesafe_app/telas/reportar_tela.dart';
import 'package:flutter/material.dart';

/// Estrutura do app logado: AppBar + conteúdo da aba + NavigationBar.
class Shell extends StatelessWidget {
  const Shell(this.c, {super.key, required this.aoSair});

  final DashboardController c;
  final VoidCallback aoSair;

  Future<void> _reportar(BuildContext context) async {
    final enviado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ReportarTela()),
    );

    if (enviado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte enviado. Obrigado por avisar!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) => Scaffold(
          // Home, Mapa e Reportados já têm título próprio; a barra só aparece em Configurações
          appBar: c.aba == 3 ? AppBar(title: const Text('Configurações')) : null,
          // IndexedStack mantém as abas vivas (o mapa não recarrega ao trocar de aba)
          body: IndexedStack(
            index: c.aba,
            children: [
              HomeTela(c),
              Mapa(c),
              ReportadosTela(c),
              ConfiguracoesTela(aoSair: aoSair),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: c.aba,
            onDestinationSelected: c.irParaAba,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Mapa',
              ),
              NavigationDestination(
                icon: Icon(Icons.report_outlined),
                selectedIcon: Icon(Icons.report),
                label: 'Reportados',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Configurações',
              ),
            ],
          ),
        ),
      );
}
