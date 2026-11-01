// Na web o MQTT usa o cliente de navegador; no Android/iOS/desktop, o cliente
// de servidor (também por WebSocket, na porta 9001 do Mosquitto).
// A importação condicional escolhe o arquivo certo em cada plataforma.
export 'mqtt_factory_stub.dart'
    if (dart.library.html) 'mqtt_factory_web.dart'
    if (dart.library.io) 'mqtt_factory_io.dart';
