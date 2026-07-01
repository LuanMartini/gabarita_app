# Gabarita App

Aplicativo Flutter educacional para resolver questoes, acompanhar desempenho e demonstrar uso de recursos nativos do celular.

## Entrega implementada

- SQLite local com tabelas `users`, `questions`, `attempts`, `user_stats` e `study_sessions`.
- Importacao ENEM 100% offline a partir de JSONs em `assets/data/`.
- Nenhuma chamada para API ENEM em tempo de uso.
- Acelerometro: modo foco pausa o cronometro quando o celular fica virado para baixo.
- Camera: scanner abre a camera e cadastra questao local com foto, enunciado, alternativas e gabarito.
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

Os arquivos ficam em:

- `assets/data/enem_exams.json`
- `assets/data/enem_questions_2023.json`
- `assets/data/enem_questions_2022.json`

Para adicionar uma nova prova, crie `assets/data/enem_questions_ANO.json` seguindo o mesmo formato e adicione o ano em `enem_exams.json`.

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
