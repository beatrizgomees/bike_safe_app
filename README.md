# Bike Safe — Aplicativo (versão web)

Aplicativo do **Bike Safe**, feito em Flutter e executado no navegador. Mostra onde ocorreram os acidentes com bicicleta no Recife, se eles aconteceram dentro ou fora da malha cicloviária, e permite que o usuário reporte ocorrências.

O app depende do **backend** do projeto (API, broker MQTT e banco de dados): até o login passa pela API. Por isso, o passo a passo abaixo sobe primeiro o backend e depois o app.

## Pré-requisitos

| Ferramenta | Para quê | Como conferir |
|---|---|---|
| **Git** | Clonar o projeto | `git --version` |
| **Python 3.11+** | Backend | `py --version` |
| **Docker Desktop** | Banco (PostgreSQL) e broker (Mosquitto) | `docker --version` |
| **Flutter 3.22+** | App | `flutter --version` |
| **Google Chrome** | Executar o app | `flutter devices` deve listar **Chrome** |

As portas **5432**, **1883**, **9001** e **8000** precisam estar livres.

## Passo a passo

### 1. Clonar o projeto

```powershell
git clone <url-do-repositorio>
cd bike-safe-project
```

### 2. Preparar o backend (uma vez só)

Na raiz do projeto, crie o ambiente virtual e instale as dependências:

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Se o PowerShell bloquear a ativação, rode `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` e tente de novo.

Crie o arquivo `.env` a partir do modelo:

```powershell
copy .env.example .env
```

Abra o `.env` e preencha a senha do banco, sem espaços e sem aspas:

```
POSTGRES_PASSWORD=uma_senha_qualquer
```

### 3. Subir o backend

Abra o **Docker Desktop** e espere ele iniciar. Depois, ainda na raiz do projeto e com o ambiente virtual ativado:

```powershell
python main.py
```

O `main.py` sobe o banco e o broker no Docker, aplica o schema, inicia o Módulo de Processamento e a API e dispara o Sensor Virtual. Na primeira vez demora mais, porque o Docker baixa as imagens e os endereços dos acidentes são geocodificados.

**Deixe esse terminal aberto.** Para conferir, abra <http://localhost:8000/api/resumo>: deve aparecer um JSON com os totais.

### 4. Executar o app no navegador

Abra **outro terminal**, entre na pasta do app e rode:

```powershell
cd app
flutter pub get
flutter run -d chrome
```

O Chrome abre com o app.

### 5. Configurar o servidor e entrar

Na tela de login, toque em **Servidor** e preencha:

| Campo | Valor |
|---|---|
| Endereço | `localhost` |
| Porta da API | `8000` |

Depois, toque em **Criar conta** para o primeiro acesso, ou em **Entrar** se já tiver conta.

## Conferindo

| O quê | Como deve estar |
|---|---|
| Home | Mostra os totais e os últimos acidentes |
| Etiqueta no topo | **"Ao vivo"**: o tempo real pelo broker (WebSocket, porta 9001) está funcionando |
| Mapa | Acidentes, ciclovias e ciclofaixas aparecem, com filtros por camada |
| Localização | O Chrome pede permissão ao usar "Usar minha localização" ou ao reportar |

## Encerrando

- **App:** aperte `q` no terminal do `flutter run`.
- **Backend:** aperte `Enter` ou `Ctrl+C` no terminal do `main.py`.
- **Contêineres:** para parar o banco e o broker, rode `docker compose stop` na raiz do projeto.

Da próxima vez, basta repetir os passos **3, 4 e 5**. Os passos 1 e 2 só são feitos uma vez.

## Problemas comuns

| Sintoma | Solução |
|---|---|
| `POSTGRES_PASSWORD ... missing a value` | O `.env` não existe ou está sem a senha. Refaça o passo 2 |
| `error during connect` | O Docker Desktop está fechado. Abra e espere iniciar |
| `port is already allocated` | Uma das portas está ocupada. Feche o programa que a usa, ou mude a porta no `.env` |
| `No module named 'paho'` ou `'psycopg'` | O ambiente virtual não está ativado. Rode `.\.venv\Scripts\Activate.ps1` e `python -m pip install -r requirements.txt` |
| App mostra "API indisponível" | O backend não está rodando, ou o servidor não é `localhost`. Confira <http://localhost:8000/api/resumo> |
| Etiqueta sempre "Offline" | O broker não está com WebSocket na porta 9001. O Mosquitto precisa ter `listener 9001` com `protocol websockets`, e o `compose.yaml` precisa publicar `"9001:9001"`. Confira com `docker compose ps`. Mesmo assim, o app funciona: busca os dados na API a cada 15 s |
| Localização não funciona | Libere a localização no cadeado da barra de endereço do Chrome |
| Mudança no código não aparece | Aperte `R` (maiúsculo) no terminal do `flutter run` para reiniciar o app |

## Sobre o app

**Telas:**

| Tela | O que mostra |
|---|---|
| Login | Entrar ou criar conta, e configurar o servidor |
| Home | Totais de acidentes, proporção em ciclovia, últimos acidentes e estação mais perto de você |
| Mapa | Acidentes agrupados, ciclovias, ciclofaixas e estações, com filtros e detalhe do acidente |
| Reportados | Ocorrências que você relatou |
| Reportar | Uma ou mais ocorrências (colisão, queda, buraco, alagamento…), com localização e endereço automáticos |
| Ajustes | Perfil, notificações, tema, servidor e sair |

**Tecnologias:**
- Flutter/Dart;
- `flutter_map` para o mapa (OpenStreetMap);
- `mqtt_client`, que recebe o tempo real por WebSocket;
- `http` para a API;
- `geolocator` para a localização;
- `shared_preferences` para as preferências;
- Nominatim, que converte a localização em endereço.

**Estrutura do código (`app/lib/`):**

```
main.dart                  # entrada: login ou app
config.dart                # servidor, sessão, tema e preferências
api_service.dart           # chamadas à API
reportes_api.dart          # listar e enviar reportes
mqtt_service.dart          # tempo real e modo offline
mqtt_factory*.dart         # cliente MQTT por WebSocket no navegador
dashboard_controller.dart  # estado do app
models/                    # acidente, estação, resumo, reporte
location/                  # localização e endereço
view_controllers/          # lógica das telas de login e reporte
components/                # lista, detalhe, cartões
telas/                     # home, mapa, reportados, reportar, ajustes, login
```
