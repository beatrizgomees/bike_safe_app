import 'package:flutter/material.dart';

import 'config.dart';
import 'dashboard_controller.dart';
import 'telas/config_tela.dart';
import 'telas/home_tela.dart';
import 'telas/mapa_tela.dart';
import 'telas/reportes_tela.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Config.carregar();   // servidor, tema e identificador do aparelho
  runApp(const BikeSafeApp());
}

class BikeSafeApp extends StatefulWidget {
  const BikeSafeApp({super.key});

  @override
  State<BikeSafeApp> createState() => _BikeSafeAppState();
}

class _BikeSafeAppState extends State<BikeSafeApp> {
  final c = DashboardController();

  @override
  void initState() {
    super.initState();
    c.iniciar();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: Config.temaModo,
        builder: (context, modo, _) => MaterialApp(
          title: 'Bike Safe',
          debugShowCheckedModeBanner: false,
          themeMode: modo,
          theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          home: Shell(c),
        ),
      );
}

class Shell extends StatelessWidget {
  const Shell(this.c, {super.key});
  final DashboardController c;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) => LayoutBuilder(
          builder: (context, caixa) {
            // IndexedStack mantém as telas vivas: o mapa não perde posição ao trocar de aba
            final telas = IndexedStack(
              index: c.aba,
              children: [
                HomeTela(c),
                MapaTela(c),
                ReportesTela(c),
                ConfigTela(c),
              ],
            );

            if (caixa.maxWidth >= 800) {
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: c.aba,
                      onDestinationSelected: c.irParaAba,
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.map_outlined),
                          selectedIcon: Icon(Icons.map),
                          label: Text('Mapa'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.campaign_outlined),
                          selectedIcon: Icon(Icons.campaign),
                          label: Text('Reportados'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: Text('Config.'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: telas),
                  ],
                ),
              );
            }

            return Scaffold(
              body: telas,
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
                    icon: Icon(Icons.campaign_outlined),
                    selectedIcon: Icon(Icons.campaign),
                    label: 'Reportados',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Ajustes',
                  ),
                ],
              ),
            );
          },
        ),
      );
}
