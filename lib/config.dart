import 'package:flutter/foundation.dart' show kIsWeb;

/// Endereços do backend. Podem ser trocados na hora de rodar:
///   flutter run --dart-define=HOST=192.168.0.10
class Config {
  static const _hostDefinido = String.fromEnvironment('HOST');
  static const apiPorta = String.fromEnvironment('API_PORT', defaultValue: '8000');
  static const brokerPorta = int.fromEnvironment('MQTT_WS_PORT', defaultValue: 9001);

  /// Web: o mesmo endereço da página. Emulador Android: 10.0.2.2 é o seu PC.
  /// Celular de verdade: use --dart-define=HOST=<IP do PC na rede>.
  static String get host =>
      _hostDefinido.isNotEmpty ? _hostDefinido : (kIsWeb ? Uri.base.host : '10.0.2.2');

  static String get apiUrl => 'http://$host:$apiPorta';

  static const topicoApp = 'bikesafe/app/#';
  static const topicoAcidente = 'bikesafe/app/acidente';
  static const topicoUltimos = 'bikesafe/app/ultimos';
}
