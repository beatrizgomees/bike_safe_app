import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Endereços do backend. Podem ser trocados na hora de rodar:
///   flutter run --dart-define=HOST=192.168.0.10
class Config {
  static const _hostDefinido = String.fromEnvironment('HOST');

  /// Web: o mesmo endereço da página. Emulador Android: 10.0.2.2 é o seu PC.
  /// Celular de verdade: use --dart-define=HOST=<IP do PC na rede>.
  static String get host => (_hostSalvo?.isNotEmpty ?? false)
      ? _hostSalvo!
      : _hostDefinido.isNotEmpty
          ? _hostDefinido
          : (kIsWeb ? Uri.base.host : '10.0.2.2');

  static String get apiUrl => 'http://$host:$apiPorta';

  static const topicoApp = 'bikesafe/app/#';
  static const topicoAcidente = 'bikesafe/app/acidente';
  static const topicoUltimos = 'bikesafe/app/ultimos';

  static final temaModo = ValueNotifier<ThemeMode>(ThemeMode.system);

  static String? _hostSalvo;
  static String apiPorta = const String.fromEnvironment('API_PORT', defaultValue: '8000');
  static int brokerPorta = const int.fromEnvironment('MQTT_WS_PORT', defaultValue: 9001);
  static int intervaloOfflineSeg = 15;
  static String dispositivo = '';

  // sessão (login)
  static String token = '';
  static bool get logado => token.isNotEmpty;

  // perfil e preferências do usuário
  static String perfilNome = '';
  static String perfilEmail = '';
  static String perfilBairro = '';
  static String perfilPerfilCiclista = 'urbano';
  static bool notificarAcidentes = true;
  static bool notificarRota = false;


  static Future<void> carregar() async {
    final p = await SharedPreferences.getInstance();

    _hostSalvo = p.getString('host');
    apiPorta = p.getString('apiPorta') ?? apiPorta;
    brokerPorta = p.getInt('brokerPorta') ?? brokerPorta;
    intervaloOfflineSeg = p.getInt('intervaloOffline') ?? intervaloOfflineSeg;
    temaModo.value = _tema(p.getString('tema'));
    token = p.getString('token') ?? '';
    perfilNome = p.getString('perfilNome') ?? '';
    perfilEmail = p.getString('perfilEmail') ?? '';
    perfilBairro = p.getString('perfilBairro') ?? '';
    perfilPerfilCiclista = p.getString('perfilCiclista') ?? 'urbano';
    notificarAcidentes = p.getBool('notificarAcidentes') ?? true;
    notificarRota = p.getBool('notificarRota') ?? false;

    var id = p.getString('dispositivo');

    if (id == null) {
      final r = Random.secure();
      id = 'ap-${List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join()}';
      await p.setString('dispositivo', id);
    }

    dispositivo = id;
  }

  static Future<void> salvarServidor({
    required String host,
    required String apiPorta,
    required int brokerPorta,
  }) async {
    final p = await SharedPreferences.getInstance();

    _hostSalvo = host.trim();
    Config.apiPorta = apiPorta.trim();
    Config.brokerPorta = brokerPorta;

    await p.setString('host', _hostSalvo!);
    await p.setString('apiPorta', Config.apiPorta);
    await p.setInt('brokerPorta', brokerPorta);
  }


  static Future<void> salvarSessao({
    required String token,
    required String nome,
    required String email,
  }) async {
    Config.token = token;
    perfilNome = nome;
    perfilEmail = email;

    final p = await SharedPreferences.getInstance();
    await p.setString('token', token);
    await p.setString('perfilNome', nome);
    await p.setString('perfilEmail', email);
  }

  static Future<void> limparSessao() async {
    token = '';
    perfilNome = '';
    perfilEmail = '';

    final p = await SharedPreferences.getInstance();
    await p.remove('token');
    await p.remove('perfilNome');
    await p.remove('perfilEmail');
  }

  static Future<void> salvarTema(ThemeMode modo) async {
    temaModo.value = modo;

    final p = await SharedPreferences.getInstance();
    await p.setString('tema', switch (modo) {
      ThemeMode.light => 'claro',
      ThemeMode.dark => 'escuro',
      ThemeMode.system => 'sistema',
    });
  }

  static ThemeMode _tema(String? nome) => switch (nome) {
        'claro' => ThemeMode.light,
        'escuro' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

static Future<void> salvarNotificacoes({bool? acidentes, bool? rota}) async {
  final p = await SharedPreferences.getInstance();

  if (acidentes != null) {
    notificarAcidentes = acidentes;
    await p.setBool('notificarAcidentes', acidentes);
  }

  if (rota != null) {
    notificarRota = rota;
    await p.setBool('notificarRota', rota);
  }
}
}
