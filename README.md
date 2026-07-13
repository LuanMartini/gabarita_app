# Gabarita App

Aplicativo educacional em Flutter para estudar questoes do ENEM de forma offline, criar simulados, acompanhar estatisticas e demonstrar recursos nativos do celular.

## Resumo

O Gabarita foi desenvolvido com uma organizacao inspirada em Clean Architecture:

- `domain`: entidades, contratos e casos de uso.
- `data`: models, SQLite, leitura dos JSONs locais e repositorios.
- `presentation`: telas e providers com `provider`.
- `services`: camera, GPS, acelerometro, notificacoes e widgets Android.
- `assets/data/enem`: banco local de questoes do ENEM em JSON.

O app nao depende de API externa para carregar questoes. Os JSONs locais sao importados para o SQLite no proprio aparelho.

## Funcionalidades

- Banco local de questoes do ENEM de 2009 a 2025, sem imagens.
- Filtro por disciplina, favoritas, busca textual e ano especifico do ENEM.
- Resolucao de questoes com correcao automatica.
- Feedback com gabarito, XP e explicacao.
- Simulados com quantidade configuravel por `Slider`.
- Historico de simulados recentes.
- Estatisticas de acerto por disciplina e desempenho semanal.
- Revisao inteligente por abas: erradas, favoritas e recomendadas.
- Perfil com nome, foto, meta semanal, conquistas e historico.
- Camera para foto de perfil.
- GPS para registrar local de estudo, quando permitido.
- Acelerometro para ativar Modo Foco quando o celular fica virado para baixo.
- Notificacoes locais para lembretes/revisao.

## Documentacao

A documentacao detalhada esta na pasta [`docs`](docs/README.md):

- [Visao geral da documentacao](docs/README.md)
- [Arquitetura do projeto](docs/arquitetura.md)
- [Como rodar o app](docs/como-rodar.md)
- [Banco offline do ENEM](docs/banco-offline.md)
- [Telas e widgets utilizados](docs/telas-e-widgets.md)
- [Fluxos principais do app](docs/fluxos-principais.md)
- [Roteiro para apresentacao](docs/roteiro-apresentacao.md)
- [Explicacao completa do codigo](docs/explicacao_codigo.md)

## Tecnologias

- Flutter
- Dart
- Provider
- SQLite com `sqflite`
- JSON local em assets
- `sensors_plus`
- `geolocator`
- `image_picker`
- `flutter_local_notifications`
- `fl_chart`
- `home_widget`

## Comandos principais

```bash
flutter pub get
dart analyze
flutter test
flutter run
```

Para gerar APK debug:

```bash
flutter build apk --debug
```

O APK fica em:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Observacao

Os arquivos Dart estao muito comentados de proposito, para facilitar a apresentacao academica. Depois da avaliacao, esses comentarios podem ser reduzidos sem alterar a regra de negocio.
