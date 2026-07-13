# Telas e Widgets Utilizados

Esta pagina resume as telas do app e os principais widgets usados em cada uma.

## Splash

Arquivo:

```text
lib/presentation/screens/splash/splash_screen.dart
```

Funcao:

- mostra tela inicial;
- espera o banco local ficar pronto;
- navega para a tela principal.

Widgets importantes:

- `SafeArea`;
- `LayoutBuilder`;
- `SingleChildScrollView`;
- `ConstrainedBox`;
- `IntrinsicHeight`;
- `Image.memory`;
- `Spacer`.

## Home

Arquivo:

```text
lib/presentation/screens/home/home_screen.dart
```

Funcao:

- mostra saudacao;
- mostra streak;
- mostra progresso semanal;
- mostra metricas gerais;
- abre atalhos por disciplina.

Widgets importantes:

- `CircleAvatar`;
- `Card`;
- `LinearProgressIndicator`;
- `ListView.builder`;
- `BottomNavigationBar`.

## Questoes

Arquivo:

```text
lib/presentation/screens/questions/questions_screen.dart
```

Funcao:

- lista questoes do banco local;
- permite busca textual;
- filtra por ano do ENEM;
- filtra por disciplina;
- mostra favoritas.

Widgets importantes:

- `TextField`;
- `DropdownButton`;
- `DropdownMenuItem`;
- `ChoiceChip`;
- `SwitchListTile`;
- `AnimatedSwitcher`;
- `ListView.builder`;
- `IconButton`.

## Responder Questao

Arquivo:

```text
lib/presentation/screens/answer/answer_screen.dart
```

Funcao:

- mostra enunciado;
- mostra alternativas;
- registra escolha;
- confirma resposta;
- ativa Modo Foco pelo acelerometro;
- salva tentativa e estatisticas.

Widgets importantes:

- `Stack`;
- `IconButton`;
- `LinearProgressIndicator`;
- `SingleChildScrollView`;
- `MarkdownBody`;
- `GestureDetector`;
- `CircleAvatar`;
- `ElevatedButton`.

## Feedback

Arquivo:

```text
lib/presentation/screens/feedback/feedback_screen.dart
```

Funcao:

- mostra se acertou ou errou;
- mostra gabarito;
- mostra XP;
- mostra explicacao;
- avanca para a proxima questao.

Widgets importantes:

- `Container` com cor dinamica;
- `MarkdownBody`;
- `ElevatedButton`;
- `OutlinedButton`.

## Simulado

Arquivo:

```text
lib/presentation/screens/simulado/simulado_config_screen.dart
```

Funcao:

- seleciona materias;
- escolhe quantidade de questoes;
- inicia simulado;
- mostra historico recente.

Widgets importantes:

- `Wrap`;
- `ChoiceChip`;
- `Slider`;
- `ListView`;
- `Card`.

## Estatisticas

Arquivo:

```text
lib/presentation/screens/statistics/statistics_screen.dart
```

Funcao:

- mostra total respondido;
- mostra taxa de acerto;
- mostra streak;
- mostra grafico semanal;
- mostra acerto por disciplina;
- mostra local de estudo.

Widgets importantes:

- `SegmentedButton`;
- `ButtonSegment`;
- `BarChart`;
- `LinearProgressIndicator`;
- `ExpansionTile`.

## Revisao Inteligente

Arquivo:

```text
lib/presentation/screens/review/review_screen.dart
```

Funcao:

- organiza revisao por abas;
- mostra erradas;
- mostra favoritas;
- mostra recomendadas.

Widgets importantes:

- `DefaultTabController`;
- `TabBar`;
- `Tab`;
- `TabBarView`;
- `ListView.builder`.

## Perfil

Arquivo:

```text
lib/presentation/screens/profile/profile_screen.dart
```

Funcao:

- mostra nome;
- mostra foto;
- permite editar nome;
- mostra meta semanal;
- mostra conquistas;
- mostra historico.

Widgets importantes:

- `CircleAvatar`;
- `Image.memory`;
- `TextButton.icon`;
- `LinearProgressIndicator`;
- `Chip`;
- `SnackBar`;
- `AlertDialog`;
- `TextFormField`.

## Foto de Perfil

Arquivo:

```text
lib/presentation/screens/profile/profile_photo_screen.dart
```

Funcao:

- abre a camera;
- mostra preview da foto;
- salva foto no perfil;
- remove foto atual.

Widgets importantes:

- `CircleAvatar`;
- `ClipOval`;
- `Image.memory`;
- `ElevatedButton.icon`;
- `OutlinedButton.icon`;
- `CircularProgressIndicator`.
