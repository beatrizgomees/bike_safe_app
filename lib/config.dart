import 'dart:math';

import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static const _hostCompilacao = String.fromEnvironment('HOST');

  static String? _hostSalvo;
  static String apiPorta = const String.fromEnvironment('API_PORT', defaultValue: '8000');
  static int brokerPorta = const int.fromEnvironment('MQTT_WS_PORT', defaultValue: 9001);
  static int intervaloOfflineSeg = 15;
  static String dispositivo = '';

  static final temaModo = ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Web: o mesmo endereço da página. Emulador Android: 10.0.2.2 é o seu PC.
  /// Celular de verdade: o IP do PC na rede.
  static String get hostPadrao =>
      _hostCompilacao.isNotEmpty ? _hostCompilacao : (kIsWeb ? Uri.base.host : '10.0.2.2');

  static String get host =>
      (_hostSalvo != null && _hostSalvo!.isNotEmpty) ? _hostSalvo! : hostPadrao;

  static String get apiUrl => 'http://$host:$apiPorta';

  static const topicoApp = 'bikesafe/app/#';
  static const topicoAcidente = 'bikesafe/app/acidente';
  static const topicoUltimos = 'bikesafe/app/ultimos';

  static Future<void> carregar() async {
    final p = await SharedPreferences.getInstance();

    _hostSalvo = p.getString('host');
    apiPorta = p.getString('apiPorta') ?? apiPorta;
    brokerPorta = p.getInt('brokerPorta') ?? brokerPorta;
    intervaloOfflineSeg = p.getInt('intervaloOffline') ?? intervaloOfflineSeg;
    temaModo.value = _tema(p.getString('tema'));

    var id = p.getString('dispositivo');

    if (id == null) {
      final r = Random.secure();
      id = 'ap-${List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join()}';
      await p.setString('dispositivo', id);
    }

    dispositivo = id;
  }

  static ThemeMode _tema(String? nome) => switch (nome) {
        'claro' => ThemeMode.light,
        'escuro' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String nomeDoTema(ThemeMode m) => switch (m) {
        ThemeMode.light => 'claro',
        ThemeMode.dark => 'escuro',
        _ => 'sistema',
      };

  /// host vazio = voltar ao endereço padrão.
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

  static Future<void> salvarIntervalo(int segundos) async {
    intervaloOfflineSeg = segundos;
    await (await SharedPreferences.getInstance()).setInt('intervaloOffline', segundos);
  }

  static Future<void> salvarTema(ThemeMode modo) async {
    temaModo.value = modo;
    await (await SharedPreferences.getInstance()).setString('tema', nomeDoTema(modo));
  }
}
