# Gabarita App

Aplicativo Flutter educacional para resolver questoes, acompanhar desempenho e demonstrar uso de recursos nativos do celular.

## Entrega implementada

- SQLite local com tabelas normalizadas para `questions`, `question_alternatives`, `attempts`, `study_sessions`, `user_stats`, `study_progress`, `favorite_questions`, `study_places`, historico de simulados e `app_settings`.
- Importacao ENEM 100% offline a partir de JSONs empacotados em `assets/data/enem/`.
- Simulados misturam automaticamente questoes textuais de varios anos do ENEM.
- Limpeza do banco remove duplicadas, incompletas e questoes que dependem de imagens, graficos, tabelas ou figuras.
- Nenhuma API, Firebase, Supabase, servidor ou requisicao HTTP na execucao do app.
- Suporte ao Chrome/Web com SQLite local via WASM/IndexedDB.
- Layout responsivo validado em celular no modo retrato e paisagem.
- Acelerometro: modo foco pausa o cronometro quando o celular fica virado para baixo.
- Camera: scanner abre a camera como apoio e cadastra a questao local em formato textual.
- GPS: tentativas salvam latitude/longitude quando permitido, agrupam coordenadas proximas como Casa/Biblioteca/Campus e exibem desempenho por local.
- Notificacoes locais: lembrete de revisao e reforco espacado para questoes erradas.
- Cinco widgets Android:
  - Desafio do Dia com resposta sem abrir o app.
  - Grafico de Performance dos ultimos 7 dias desenhado via Canvas nativo.
  - Estatistica Rapida com acertos gerais e questoes feitas hoje.
  - Ultimo Topico Estudado com atalho direto para um treino da categoria.
  - Botao Scanner para abrir a camera.
- Sete widgets Flutter adicionais, diferentes dos listados no prototipo das telas:
  - `RefreshIndicator` no banco de questoes.
  - `PopupMenuButton` para acoes rapidas do banco.
  - `SegmentedButton` para periodo das estatisticas.
  - `ExpansionTile` para detalhar locais de estudo.
  - `FilledButton` para abrir o scanner sem usar botao flutuante.
  - `SwitchListTile` para alternar o filtro de favoritas.
  - `AnimatedSwitcher` para animar a contagem de questoes.

## JSONs locais do ENEM

Os arquivos ficam em `assets/data/enem/`:

- `index.json` lista os anos disponiveis.
- `enem_2009.json` ate `enem_2025.json` armazenam as questoes.

No primeiro preparo do banco, o app importa os JSONs locais para o SQLite e grava a versao importada em `app_settings`. Depois disso, as telas e os simulados usam somente o SQLite, sem reler JSONs durante a execucao normal e sem internet.

## Auditoria offline

- Nao existe chamada HTTP no codigo Dart/Kotlin do app.
- Nao existe Firebase.
- Nao existe Supabase.
- Nao existe API externa para questoes, simulados, estatisticas ou widgets.
- Todas as questoes usadas no app ficam no SQLite depois da importacao inicial local.
- Simulados usam apenas SQLite, misturam anos do ENEM e evitam repeticoes ate esgotar as questoes disponiveis.
- Favoritos, respostas, progresso, historico, estatisticas, configuracoes e ultimo estado ficam persistidos localmente.

## Comandos de validacao

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

O APK debug fica em:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

O build web fica em:

```text
build/web
```
