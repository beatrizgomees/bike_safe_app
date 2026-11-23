import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'config.dart';
import 'dashboard_controller.dart';
import 'firebase_options.dart';
import 'telas/login_tela.dart';
import 'telas/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Config.carregar();
  runApp(const BikeSafeApp());
}

/// Mostra o login; ao entrar, abre o app (Shell) no Mapa.
/// O controlador (MQTT, API, dados) só nasce depois do login.
class BikeSafeApp extends StatefulWidget {
  const BikeSafeApp({super.key});

  @override
  State<BikeSafeApp> createState() => _BikeSafeAppState();
}

class _BikeSafeAppState extends State<BikeSafeApp> {
  DashboardController? _c;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();

    // o Firebase guarda a sessão: se já tem usuário logado, pula o login
    final u = _auth.usuarioAtual;
    if (u != null) {
      Config.perfilNome = u.displayName ?? Config.perfilNome;
      Config.perfilEmail = u.email ?? Config.perfilEmail;
      _entrar();
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  void _entrar() {
    final c = DashboardController();

    c.aba = 1; // abre direto no mapa (0 = Home)
    c.iniciar();
    setState(() => _c = c);
  }

  Future<void> _sair() async {
    final antigo = _c;

    await _auth.sair();
    await Config.limparSessao();

    setState(() => _c = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => antigo?.dispose());
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
          home: _c == null ? LoginTela(aoEntrar: _entrar) : Shell(_c!, aoSair: _sair),
        ),
      );
}
