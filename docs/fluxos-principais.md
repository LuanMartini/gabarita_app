# Fluxos Principais

Esta pagina explica os fluxos mais importantes do Gabarita.

## Inicializacao

```text
main()
  -> initializeDatabaseFactory()
  -> runApp(GabaritaApp)
  -> MultiProvider
  -> QuestionsProvider.initializeLocalEnemBank()
```

O app inicia o Flutter, prepara o SQLite e injeta os providers.

## Carregar banco offline

```text
QuestionsProvider
  -> EnsureLocalEnemBank
  -> QuestionRepositoryImpl
  -> EnemLocalDataSource
  -> assets/data/enem/*.json
  -> DatabaseHelper
  -> SQLite
```

Depois da importacao, as telas usam o SQLite.

## Buscar questoes

```text
QuestionsScreen
  -> QuestionsProvider.setSearchText / setExamYearFilter / setSingleSubjectFilter
  -> GetQuestionsByFilter
  -> QuestionRepositoryImpl
  -> DatabaseHelper.getFilteredQuestions
```

Os filtros podem combinar:

- texto;
- disciplina;
- ano do ENEM;
- favoritas.

## Responder questao

```text
AnswerScreen
  -> QuestionsProvider.selectAlternative
  -> QuestionsProvider.confirmSelectedAnswer
  -> SaveAttempt
  -> AttemptRepositoryImpl
  -> DatabaseHelper.insertAttempt
```

Ao salvar tentativa, o banco tambem atualiza:

- total respondido;
- total correto;
- streak;
- meta semanal;
- estatisticas por disciplina.

## Feedback

```text
AnswerScreen
  -> registra lastFeedback
  -> FeedbackScreen
```

A tela de feedback mostra:

- resposta escolhida;
- gabarito;
- acerto ou erro;
- XP;
- explicacao.

## Simulado

```text
SimuladoConfigScreen
  -> SessionProvider.startSimulado
  -> GenerateSimulado
  -> QuestionRepositoryImpl.getSimuladoQuestions
  -> DatabaseHelper.getBalancedSimuladoQuestions
```

O simulado tenta:

- respeitar quantidade escolhida;
- filtrar materias escolhidas;
- misturar anos do ENEM;
- evitar repetir questoes recentes.

## Foto de perfil

```text
ProfilePhotoScreen
  -> CameraService.captureProfilePhoto
  -> UserProvider.updateAvatar
  -> UpdateUserAvatar
  -> UserRepositoryImpl
  -> DatabaseHelper.updateUserAvatar
```

A foto e convertida para base64 e salva no banco local.

## Modo Foco

```text
AnswerScreen
  -> AccelerometerService
  -> celular virado para baixo
  -> overlay "Modo Foco Ativo"
  -> cronometro pausado
```

Esse recurso usa o acelerometro para incentivar foco durante a resolucao.

## Estatisticas

```text
StatisticsScreen
  -> StatisticsProvider.loadStatistics
  -> GetUserStatistics
  -> AttemptRepositoryImpl
  -> DatabaseHelper
```

As estatisticas usam tentativas salvas no SQLite.
