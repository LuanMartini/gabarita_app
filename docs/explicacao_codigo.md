# Explicacao do Codigo - Gabarita

Este documento explica o projeto Gabarita para apresentacao academica. A ideia e explicar o codigo por camadas, arquivos e fluxos principais sem encher todos os arquivos `.dart` com comentarios repetitivos.

## Visao Geral

O aplicativo segue uma organizacao inspirada em Clean Architecture:

- `core`: constantes, inicializacao do banco e utilitarios compartilhados.
- `domain`: regras puras do app, entidades, contratos de repositorio e casos de uso.
- `data`: models, acesso ao SQLite, leitura dos JSONs locais e implementacoes dos repositorios.
- `presentation`: telas, widgets e providers de estado.
- `services`: recursos do aparelho, como camera, GPS, acelerometro, notificacoes e home widgets.
- `test`: testes automatizados para banco, questoes, simulados, perfil e integridade do gabarito.

O app e offline: as questoes do ENEM ficam em JSON local e sao importadas para SQLite.

## Fluxo de Inicializacao

Arquivo: `lib/main.dart`

- `WidgetsFlutterBinding.ensureInitialized()` garante que Flutter e plugins nativos estejam prontos.
- `initializeDatabaseFactory()` configura o SQLite correto para cada plataforma.
- `runApp(const GabaritaApp())` inicia o app.
- `_initializePlatformServices()` tenta iniciar notificacoes e home widgets sem travar o app se algo falhar.
- `GabaritaApp` monta os repositorios e os injeta nos Providers.
- `MultiProvider` disponibiliza `UserProvider`, `QuestionsProvider`, `SessionProvider` e `StatisticsProvider`.
- `MaterialApp` define tema escuro, rotas e tela inicial.
- `MainNavigationScreen` controla as cinco abas principais pelo `BottomNavigationBar`.

## Core

Arquivo: `lib/core/constants/db_constants.dart`

- Centraliza nomes de tabelas e colunas do SQLite.
- Evita strings repetidas espalhadas pelo projeto.
- Ajuda a manter as queries consistentes.

Arquivo: `lib/core/database/database_initializer.dart`

- Exporta a implementacao correta conforme plataforma.
- No Android/iOS usa SQLite normal.
- Em desktop/testes pode usar `sqflite_common_ffi`.

Arquivos:

- `database_initializer_io.dart`: inicializacao para plataformas nativas.
- `database_initializer_web.dart`: fallback para web.
- `database_initializer_stub.dart`: fallback neutro.

## Domain - Entidades

Arquivo: `lib/domain/entities/user.dart`

- Representa o usuario local.
- Guarda nome, avatar, streak, totais e configuracoes.
- `accuracyRate` calcula a taxa de acerto.
- `copyWith` cria uma copia alterando apenas campos especificos.

Arquivo: `lib/domain/entities/question.dart`

- Representa uma questao.
- Guarda enunciado, materia, topico, ano, fonte, alternativas e gabarito.
- `options` monta um mapa `A`, `B`, `C`, `D`, `E`.
- `normalizeOption` padroniza a alternativa.
- `isCorrectAnswer` compara a resposta selecionada com o gabarito normalizado.
- `feedback` devolve a explicacao cadastrada ou uma mensagem padrao.

Arquivo: `lib/domain/entities/attempt.dart`

- Representa uma tentativa de resposta.
- Guarda usuario, questao, alternativa escolhida, acerto, tempo e localizacao opcional.

Arquivo: `lib/domain/entities/study_session.dart`

- Representa um simulado ou sessao de estudo.
- Guarda materias, total de questoes, acertos e tempo.
- Calcula percentual de acerto e erros.

Arquivo: `lib/domain/entities/study_progress.dart`

- Representa progresso semanal e ofensiva.
- Calcula quanto falta para a meta semanal.

Arquivo: `lib/domain/entities/enem_exam.dart`

- Representa metadados de uma prova ENEM local.
- Tambem define resultados de importacao/sincronizacao local.

## Domain - Repositorios

Os arquivos em `lib/domain/repositories/` sao contratos. Eles dizem o que a camada de dominio precisa, mas nao sabem como os dados sao salvos.

- `i_user_repository.dart`: contrato para usuario.
- `i_question_repository.dart`: contrato para questoes.
- `i_attempt_repository.dart`: contrato para tentativas.
- `i_study_session_repository.dart`: contrato para simulados.
- `i_study_progress_repository.dart`: contrato para progresso e streak.

## Domain - UseCases

Cada use case representa uma acao do app.

Arquivo: `get_or_create_user.dart`

- Busca o usuario existente pelo `id`, quando informado.
- Se nao encontrar, busca o primeiro usuario local.
- Se nao existir nenhum, cria um usuario padrao.

Arquivo: `update_user_avatar.dart`

- Recebe o `userId` e a foto.
- Salva a foto no repositorio.
- Recarrega o usuario pelo `id`.
- Retorna o usuario real que ficou persistido no SQLite.

Arquivo: `update_user_name.dart`

- Atualiza apenas o nome.
- Mantem os demais dados do usuario.

Arquivo: `get_questions_by_filter.dart`

- Busca questoes aplicando filtros de materia, dificuldade, ano/fonte, favoritos e texto.

Arquivo: `ensure_local_enem_bank.dart`

- Garante que o banco local do ENEM foi importado.
- Usa JSONs locais, sem API externa.

Arquivo: `generate_simulado.dart`

- Gera uma lista de questoes para simulado.
- Usa quantidade e materias selecionadas.

Arquivo: `save_attempt.dart`

- Salva uma tentativa.
- O repositorio faz a transacao com estatisticas/progresso.

Arquivo: `get_user_statistics.dart`

- Busca dados agregados do usuario.
- Calcula totais e taxa de acerto.

Arquivo: `get_wrong_questions.dart`

- Busca questoes erradas para revisao.

Arquivo: `toggle_favorite_question.dart`

- Marca ou desmarca uma questao como favorita.

Arquivo: `save_study_session.dart`

- Salva um simulado finalizado.

Arquivo: `get_recent_simulados.dart`

- Lista simulados recentes para historico.

Arquivo: `set_weekly_goal.dart`

- Atualiza a meta semanal do estudante.

## Data - Models

Models transformam entidades em dados compativeis com SQLite/JSON.

Arquivo: `user_model.dart`

- Converte `User` para `Map`.
- Converte linha do SQLite para `UserModel`.
- Trata tipos como `int`, `bool` e `DateTime`.

Arquivo: `question_model.dart`

- Converte `Question` para `Map`.
- Le campos do SQLite.
- Mantem alternativas, gabarito, ano, origem e favorito.

Arquivo: `attempt_model.dart`

- Converte tentativas para SQLite.
- Salva `isCorrect` como inteiro.
- Converte data de resposta.

Arquivo: `study_session_model.dart`

- Persiste simulados.
- Converte lista de materias para string e de volta.

Arquivo: `enem_question_remote_model.dart`

- Le questoes vindas dos JSONs locais do ENEM.
- Filtra questoes textuais e completas.
- Transforma dados do JSON no modelo usado pelo app.

Arquivo: `enem_exam_model.dart`

- Le metadados de provas ENEM locais.

## Data - Banco Local

Arquivo: `lib/data/datasources/local/database_helper.dart`

Responsabilidades principais:

- Abrir/criar o banco SQLite.
- Criar tabelas de usuarios, questoes, tentativas, estatisticas, simulados e configuracoes.
- Inserir e atualizar usuario.
- Atualizar avatar do usuario.
- Inserir questoes e alternativas.
- Importar banco ENEM offline.
- Buscar questoes com filtros.
- Balancear a lista inicial entre anos diferentes.
- Salvar tentativa em transacao.
- Atualizar estatisticas do usuario.
- Atualizar streak e meta semanal.
- Buscar dados para estatisticas e revisao.

Pontos importantes:

- `insertAttempt` salva tentativa e atualiza dados derivados na mesma transacao.
- `getFilteredQuestions` aplica filtros de materia, dificuldade, favoritos, busca textual e ENEM especifico.
- Quando nao ha filtro de ano, a consulta tenta misturar anos para nao mostrar so ENEM 2009.
- `updateUserAvatar` altera apenas a coluna de avatar.

Arquivo: `enem_local_data_source.dart`

- Le os arquivos em `assets/data/enem/`.
- Lista provas disponiveis de 2009 a 2025.
- Carrega questoes por ano.
- Nao depende de internet.

## Data - Repositorios

Arquivo: `question_repository_impl.dart`

- Implementa `IQuestionRepository`.
- Usa `DatabaseHelper` e `EnemLocalDataSource`.
- Garante importacao do banco ENEM local.
- Filtra questoes sem imagem.
- Insere questoes textuais no SQLite.
- Busca questoes para lista, favoritos, revisao e simulados.

Arquivo: `user_repository_impl.dart`

- Implementa `IUserRepository`.
- Salva, busca e atualiza usuario.
- Atualiza nome e avatar.

Arquivo: `attempt_repository_impl.dart`

- Salva tentativas.
- Busca estatisticas por materia, semana e local.

Arquivo: `study_session_repository_impl.dart`

- Salva e busca simulados recentes.

Arquivo: `study_progress_repository_impl.dart`

- Atualiza progresso semanal e streak.

## Presentation - Providers

Providers sao a ponte entre telas e regras de negocio.

Arquivo: `user_provider.dart`

- Carrega usuario.
- Exponibiliza totais, acerto, streak e meta semanal.
- Atualiza nome.
- Atualiza foto de perfil.
- Remove foto.
- Incrementa `avatarVersion` para forcar redesenho da imagem.

Fluxo da foto:

1. Tela chama `updateAvatar`.
2. Provider chama `UpdateUserAvatar`.
3. Use case salva no SQLite.
4. Use case recarrega o usuario pelo `id`.
5. Provider recebe o usuario atualizado.
6. Provider notifica a tela.
7. Tela renderiza os bytes com `Image.memory`.

Arquivo: `questions_provider.dart`

- Carrega questoes.
- Inicializa banco ENEM offline.
- Aplica filtro de materia.
- Aplica filtro de ano ENEM.
- Aplica busca textual.
- Controla alternativa selecionada.
- Confirma resposta.
- Salva tentativa.
- Gera feedback.
- Controla favoritos sem travar a tela.

Arquivo: `session_provider.dart`

- Configura simulado.
- Escolhe quantidade pelo slider.
- Escolhe materias por chips.
- Gera questoes aleatorias.
- Salva respostas do simulado.
- Calcula acertos, erros e percentual.
- Finaliza e salva historico.

Arquivo: `statistics_provider.dart`

- Carrega estatisticas do usuario.
- Busca desempenho por periodo.
- Alimenta cards, barras e graficos.

## Presentation - Telas

Arquivo: `splash_screen.dart`

- Tela inicial.
- Mostra marca/entrada.
- Redireciona para a navegacao principal.

Arquivo: `home_screen.dart`

- Dashboard do estudante.
- Mostra saudacao, streak, progresso semanal e atalhos.
- Usa dados do `UserProvider` e `QuestionsProvider`.

Arquivo: `questions_screen.dart`

- Mostra banco de questoes.
- Campo de busca por texto.
- Dropdown de ENEM especifico.
- `ChoiceChip` para materias.
- Switch para favoritas.
- Lista questoes em cards.
- Ao tocar em uma questao, seleciona e abre a tela de resposta.

Arquivo: `answer_screen.dart`

- Exibe questao atual.
- Mostra progresso e cronometro.
- Lista alternativas clicaveis.
- Usa acelerometro para modo foco.
- Ao confirmar, salva tentativa normal ou tentativa de simulado.
- Redireciona para feedback.

Arquivo: `feedback_screen.dart`

- Mostra se acertou ou errou.
- Mostra resposta selecionada e gabarito.
- Mostra explicacao.
- Permite ir para proxima questao ou voltar.

Arquivo: `simulado_config_screen.dart`

- Configura simulado.
- Usa `ChoiceChip` para materias.
- Usa `Slider` para quantidade de questoes.
- Lista simulados recentes.
- Inicia simulado e manda questoes para `QuestionsProvider`.

Arquivo: `statistics_screen.dart`

- Mostra estatisticas.
- Usa `DropdownButton` para periodo.
- Usa `LinearProgressIndicator` para acertos por disciplina.
- Usa graficos com `fl_chart`.
- Mostra dados por local de estudo.

Arquivo: `review_screen.dart`

- Revisao inteligente.
- Usa `TabBar` para erradas, favoritas e recomendadas.
- Lista cards de revisao.

Arquivo: `profile_screen.dart`

- Mostra avatar, nome, meta semanal, conquistas e historico.
- Permite alterar nome.
- Abre a tela de foto.
- Renderiza foto de perfil por bytes (`Image.memory`).

Arquivo: `profile_photo_screen.dart`

- Abre camera.
- Captura foto.
- Converte foto para base64.
- Salva no SQLite via Provider.
- Remove foto.
- Renderiza preview por bytes.

Arquivo: `daily_challenge_launcher_screen.dart`

- Abre desafio diario vindo de widget/atalho.

Arquivo: `last_topic_launcher_screen.dart`

- Abre uma questao relacionada ao ultimo topico.

## Services

Arquivo: `accelerometer_service.dart`

- Usa sensores do celular.
- Detecta celular virado para baixo.
- Ativa modo foco.

Arquivo: `gps_service.dart`

- Usa geolocator.
- Captura latitude/longitude.
- Usado para registrar local de estudo.

Arquivo: `study_place_service.dart`

- Agrupa coordenadas proximas.
- Nomeia locais de estudo.

Arquivo: `camera_service.dart`

- Usa `image_picker`.
- Abre camera.
- Le bytes da foto.
- Cria `data:image/...;base64`.
- Nao salva mais foto de perfil como arquivo permanente.

Arquivo: `notification_service.dart`

- Configura notificacoes locais.
- Agenda lembrete diario.
- Agenda revisao de questao errada.

Arquivo: `home_widget_service.dart`

- Atualiza widgets de tela inicial.
- Responde a acoes de widget, como desafio diario.

## Testes

Arquivo: `enem_answer_key_integrity_test.dart`

- Garante que o gabarito oficial bate com a alternativa marcada como correta.

Arquivo: `enem_json_client_test.dart`

- Garante que os JSONs locais carregam.
- Testa conversao para modelo interno.

Arquivo: `enem_local_data_source_test.dart`

- Verifica provas de 2009 a 2025.
- Garante banco offline sem imagens.

Arquivo: `enem_question_remote_model_test.dart`

- Testa regras de aceitar/rejeitar questoes.
- Rejeita questoes com imagens ou alternativas incompletas.

Arquivo: `question_answer_validation_test.dart`

- Testa normalizacao de alternativa.
- Testa o caso em que resposta e gabarito iguais nao podem virar erro.

Arquivo: `question_repository_local_json_test.dart`

- Testa importacao do JSON local para SQLite.
- Testa mistura de anos na lista inicial.
- Testa filtro por ENEM especifico.

Arquivo: `simulado_question_selection_test.dart`

- Testa selecao de questoes para simulados.
- Garante mistura de anos e evita repetir questoes recentes.

Arquivo: `sqlite_crud_persistence_test.dart`

- Testa CRUD principal.
- Testa nome do perfil.
- Testa foto do perfil.
- Testa foto inline em base64.
- Testa trocar, remover e salvar nova foto.

Arquivo: `study_place_service_test.dart`

- Testa agrupamento de coordenadas.
- Testa criacao de novo local distante.

Arquivo: `widget_test.dart`

- Testa renderizacao inicial do splash.

## Fluxo: Responder Questao

1. Usuario abre `QuestionsScreen`.
2. `QuestionsProvider` carrega questoes do SQLite.
3. Usuario escolhe filtros.
4. Provider recarrega lista filtrada.
5. Usuario toca em uma questao.
6. `QuestionsProvider.selectQuestion` define questao atual.
7. App navega para `AnswerScreen`.
8. Usuario escolhe alternativa.
9. Provider guarda alternativa selecionada.
10. Usuario confirma.
11. App calcula acerto com `Question.isCorrectAnswer`.
12. `SaveAttempt` salva tentativa.
13. SQLite atualiza historico, estatisticas e progresso.
14. App mostra `FeedbackScreen`.

## Fluxo: Simulado

1. Usuario abre `SimuladoConfigScreen`.
2. Escolhe materias com `ChoiceChip`.
3. Escolhe quantidade com `Slider`.
4. `SessionProvider.startSimulado` chama `GenerateSimulado`.
5. Repositorio busca questoes no SQLite.
6. Questao atual e enviada para tela de resposta.
7. Cada resposta vira `Attempt`.
8. No fim, `StudySession` e salva.
9. Historico de simulados e atualizado.

## Fluxo: Foto de Perfil

1. Usuario abre `ProfileScreen`.
2. Toca em `Alterar foto`.
3. App abre `ProfilePhotoScreen`.
4. Usuario toca em `Tirar foto`.
5. `CameraService.captureProfilePhoto` abre a camera.
6. `image_picker` retorna um `XFile`.
7. O servico le os bytes.
8. O servico cria um `dataUri` em base64.
9. Tela chama `UserProvider.updateAvatar`.
10. Provider chama `UpdateUserAvatar`.
11. Use case salva no SQLite.
12. Use case recarrega o usuario pelo `id`.
13. Provider atualiza `_user`.
14. Provider incrementa `avatarVersion`.
15. Tela recebe `notifyListeners`.
16. Tela decodifica base64.
17. Tela exibe com `Image.memory`.

## Fluxo: Remover Foto

1. Usuario toca em `Remover foto`.
2. Tela chama `UserProvider.clearAvatar`.
3. Provider chama `UpdateUserAvatar` com `avatarPath: null`.
4. SQLite grava `null`.
5. Use case recarrega usuario.
6. Provider incrementa `avatarVersion`.
7. Tela volta a mostrar iniciais.

## Requisitos de UI Atendidos

- `LinearProgressIndicator`: Home, resposta, estatisticas e perfil.
- `Slider`: configuracao de simulado.
- `ChoiceChip`: filtros de questoes e materias do simulado.
- `DropdownButton`: filtro de periodo em estatisticas e filtro de ENEM na tela de questoes.
- `TabBar`: revisao inteligente.
- `BottomNavigationBar`: navegacao principal.
- `CircleAvatar`: perfil e alternativas.
- `Card`: listas, dashboards e blocos visuais.
- `ListView`: listas de questoes, historico, revisao e simulados.
- `SingleChildScrollView`: evita overflow em telas menores.

## Comandos de Validacao

Rodar dependencias:

```powershell
C:\Users\Felipe08\dev\flutter\bin\flutter.bat pub get
```

Analisar codigo:

```powershell
C:\Users\Felipe08\dev\flutter\bin\flutter.bat analyze --no-pub
```

Rodar testes:

```powershell
C:\Users\Felipe08\dev\flutter\bin\flutter.bat test
```

Rodar no celular:

```powershell
adb devices
adb uninstall com.example.gabarita_app
C:\Users\Felipe08\dev\flutter\bin\flutter.bat clean
C:\Users\Felipe08\dev\flutter\bin\flutter.bat pub get
C:\Users\Felipe08\dev\flutter\bin\flutter.bat run
```

## Observacao Sobre Comentarios Linha por Linha

Comentario em todas as linhas do codigo costuma piorar a legibilidade. O ideal e comentar:

- regras de negocio importantes;
- decisoes nao obvias;
- fluxos de arquitetura;
- integracoes com plugins;
- casos em que ha uma protecao contra bug.

Por isso este documento explica o projeto inteiro sem transformar cada linha do codigo em um comentario repetido.
