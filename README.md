# Bike Safe — App (Flutter)

App do Bike Safe: mapa de acidentes com ciclistas no Recife, cruzados com ciclovias, ciclofaixas e estações Bike PE. Roda no navegador (Chrome/Edge), em emulador Android e em celular. Consome a API do backend (HTTP) e recebe acidentes novos em tempo real pelo broker MQTT (WebSocket).

![Tela do mapa](docs/tela-mapa.png)

*Tela do mapa rodando no navegador: acidentes agrupados, filtros de camadas, ciclovias/ciclofaixas e lista de acidentes. O selo "offline · dados do banco" indica que o broker está fora e o app está lendo os dados da API.*

## O que o app tem

| Aba | Conteúdo |
|---|---|
| **Home** | Números gerais, % de acidentes junto a ciclovias, botão de reportar e os 5 últimos acidentes |
| **Mapa** | Mapa com acidentes (agrupados por zoom), ciclovias, ciclofaixas e estações. Filtros: *Acidentes*, *Só nas rotas*, *Estações*, *Ciclovias*, *Ciclofaixas*. Lista de acidentes em folha arrastável, com filtro Todos / Em ciclovia / Fora da ciclovia / Perto de estação |
| **Reportados** | Acidentes que você reportou neste aparelho; o botão *Reportar* marca o local no mapa e envia à API |
| **Ajustes** | Perfil, notificações, tema (sistema/claro/escuro), sobre e, em *Avançado*, a conexão com o servidor |

**Modo offline:** se o broker MQTT cai, o app não zera. Ele passa a consultar a API a cada 15 s (configurável), mostra o selo "offline · dados do banco" e volta ao tempo real sozinho quando o broker retorna.

---

## 1. Pré-requisitos

| Ferramenta | Versão | Para quê |
|---|---|---|
| Flutter SDK | 3.19 ou superior (Dart 3.3+) | Compilar e rodar o app |
| VS Code | recente | Editor, com as extensões **Flutter** e **Dart** |
| Google Chrome ou Edge | recente | Rodar o app na web (mais rápido para testar) |
| Android Studio | recente | Só se for usar emulador Android (SDK + AVD) |
| Backend do Bike Safe rodando | — | Fonte dos dados (veja o README do backend) |

Confira a instalação:

```powershell
flutter --version
flutter doctor
```

O `flutter doctor` deve mostrar visto em *Flutter*, em *Chrome* (para web) e em *Android toolchain* (para emulador). Itens de Visual Studio/Xcode só importam se você for compilar para Windows/iOS.

---

## 2. Backend primeiro

O app precisa do backend no ar. Na pasta do backend:

```powershell
py main.py
```

Confira abrindo <http://localhost:8000/api/resumo>: deve retornar JSON. O app usa:

| Serviço | Porta | Uso |
|---|---|---|
| API HTTP | 8000 | Histórico, ciclovias, estações e reportes |
| Mosquitto (WebSocket) | 9001 | Acidentes em tempo real |

> O app usa as rotas `/api/estacoes` e `/api/reportes`. Use o `api.py` mais recente do projeto.

---

## 3. Instalar e rodar

Dentro da pasta `bikesafe_app`:

```powershell
flutter pub get
```

### No navegador (Chrome ou Edge)

```powershell
flutter run -d chrome
# ou
flutter run -d edge
```

O servidor assumido é o mesmo endereço da página (`localhost`). Nada mais para configurar.

### No emulador Android

1. Abra o emulador (Android Studio → Device Manager → ▶).
2. Rode:

```powershell
flutter run
```

3. O emulador enxerga o seu PC em **`10.0.2.2`** (e não em `localhost`, que é o próprio emulador). O app já usa `10.0.2.2` por padrão no Android.
4. Em `android/app/src/main/AndroidManifest.xml`, a API usa HTTP puro, então é preciso:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:usesCleartextTraffic="true"
        ... >
```

(`INTERNET` fica antes de `<application>`; `usesCleartextTraffic` vai dentro dele.) Depois de mexer no manifest, pare o app e rode de novo (hot reload não basta).

### No celular de verdade

1. Conecte o celular e o PC **na mesma rede Wi-Fi** e ative a depuração USB no celular.
2. Descubra o IP do PC (`ipconfig`, campo IPv4, algo como `192.168.0.10`).
3. Libere as portas **8000** e **9001** no Firewall do Windows.
4. Rode apontando para o PC:

```powershell
flutter run --dart-define=HOST=192.168.0.10
```

Ou rode normalmente e altere o endereço dentro do app, em **Ajustes → Avançado → Conexão com o servidor**.

---

## 4. Configuração do servidor

Ordem de prioridade do endereço do servidor:

1. O que você salvou em **Ajustes → Avançado → Conexão com o servidor** (guardado no aparelho);
2. `--dart-define=HOST=...` na hora de rodar;
3. Padrão: web → o host da página; Android → `10.0.2.2`.

Outras opções de `--dart-define`:

| Variável | Padrão | Descrição |
|---|---|---|
| `HOST` | automático | Endereço do servidor |
| `API_PORT` | `8000` | Porta da API |
| `MQTT_WS_PORT` | `9001` | Porta WebSocket do broker |

Na tela *Conexão com o servidor* você também vê o status do broker e da API e define o intervalo de consulta quando o broker está fora (5, 15, 30 ou 60 s).

---

## 5. Estrutura do projeto

```
bikesafe_app/
├── pubspec.yaml
├── docs/tela-mapa.png
└── lib/
    ├── main.dart                  # início, tema e navegação (NavigationBar / NavigationRail)
    ├── config.dart                # servidor, perfil e preferências (shared_preferences)
    ├── models.dart                # Acidente, Trecho, EstacaoBike, Reporte, Resumo
    ├── api_service.dart           # chamadas HTTP à API
    ├── mqtt_service.dart          # cliente MQTT com reconexão automática
    ├── mqtt_factory*.dart         # MQTT por WebSocket na web, TCP/WS no celular
    ├── dashboard_controller.dart  # estado do app: dados, filtros, offline, abas
    ├── clusters.dart              # agrupamento de pontos no mapa
    ├── widgets.dart               # selo de estado, item de acidente
    └── telas/
        ├── home_tela.dart
        ├── mapa_tela.dart
        ├── reportes_tela.dart
        └── config_tela.dart
```

Principais pacotes: `flutter_map` + `latlong2` (mapa OpenStreetMap), `mqtt_client`, `http`, `shared_preferences`.

---

## 6. Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| Home com zeros e selo "offline" | API fora do ar ou endereço errado | Abra `http://localhost:8000/api/resumo` no navegador; confirme o backend e o endereço em Ajustes → Avançado |
| Emulador não conecta, mas o navegador do PC sim | App usando `localhost` ou HTTP bloqueado | Use `10.0.2.2` e configure `usesCleartextTraffic` e `INTERNET` no manifest |
| Celular não conecta | Rede diferente ou firewall | Mesma rede Wi-Fi, IP do PC no app e portas 8000 e 9001 liberadas |
| Selo "offline · dados do banco", mas a API responde | Broker (WebSocket 9001) fora | Normal: o app segue lendo o banco. Para o tempo real, suba o Mosquitto e confira `listener 9001` + `protocol websockets` |
| Mapa sem ciclovias | `/api/ciclovias` falhando | Abra a rota no navegador. Se for 404, atualize o `api.py` e reinicie a API |
| Mapa cinza, sem imagem de fundo | Sem internet (tiles do OpenStreetMap) | Verifique a conexão |
| Erro de compilação após atualizar | Dependências desatualizadas | `flutter pub get`, e se persistir `flutter clean && flutter pub get` |
| Aviso "Consider installing flutter_map_cancellable_tile_provider" no console | Sugestão de desempenho na web | Pode ignorar. É só um aviso, não um erro |
| `shared_preferences` não encontrado | `pubspec.yaml` antigo | Use o `pubspec.yaml` atual e rode `flutter pub get` |

Dica: no VS Code, com o app rodando, aperte `r` no terminal para hot reload e `R` para reiniciar.

---

## 7. Gerar o app para distribuição (opcional)

```powershell
flutter build apk --release --dart-define=HOST=SEU_SERVIDOR   # Android (build/app/outputs/flutter-apk/)
flutter build web --release                                   # Web (build/web/)
```

Para uso fora da sua rede, o backend precisa de endereço público e, de preferência, HTTPS (aí o `usesCleartextTraffic` deixa de ser necessário).
