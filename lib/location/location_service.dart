import 'package:bikesafe_app/models/estacao.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import'package:bikesafe_app/models/acidente.dart';



/// Erro com mensagem pronta para mostrar ao usuário.
class ErroLocalizacao implements Exception {
  ErroLocalizacao(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Pega a posição atual do celular, pedindo permissão quando preciso.
class LocalizacaoService {
  Future<LatLng> posicaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw ErroLocalizacao('Ative a localização do celular e tente de novo.');
    }

    var permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied) {
      throw ErroLocalizacao('Permissão de localização negada.');
    }

    if (permissao == LocationPermission.deniedForever) {
      throw ErroLocalizacao(
          'A localização foi bloqueada para o app. Libere nas configurações do celular.');
    }

    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return LatLng(p.latitude, p.longitude);
  }
}

/// Resultado: a estação mais perto de você e os acidentes ao redor dela.
class EstacaoProxima {
  EstacaoProxima({
    required this.estacao,
    required this.distanciaM,
    required this.acidentes,
    required this.raioM,
  });

  final Estacao estacao;
  final double distanciaM;          // de você até a estação
  final List<Acidente> acidentes;   // acidentes a até [raioM] da estação, do mais perto ao mais longe
  final double raioM;

  LatLng get ponto => LatLng(estacao.lat!, estacao.lon!);
}

EstacaoProxima? estacaoMaisProxima(
  LatLng eu,
  List<Estacao> estacoes,
  List<Acidente> acidentes, {
  double raioM = 300,
}) {
  if (estacoes.isEmpty) return null;

  const distancia = Distance();

  Estacao? melhor;
  var menor = double.infinity;

  for (final e in estacoes) {
    final m = distancia(eu, LatLng(e.lat!, e.lon!));

    if (m < menor) {
      menor = m;
      melhor = e;
    }
  }

  final pontoEstacao = LatLng(melhor!.lat!, melhor.lon!);

  final perto = [
    for (final a in acidentes)
      if (a.temPosicao && distancia(pontoEstacao, a.ponto) <= raioM) a,
  ]..sort((x, y) =>
      distancia(pontoEstacao, x.ponto).compareTo(distancia(pontoEstacao, y.ponto)));

  return EstacaoProxima(estacao: melhor, distanciaM: menor, acidentes: perto, raioM: raioM);
}