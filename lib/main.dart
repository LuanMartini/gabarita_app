import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import 'core/database/database_initializer.dart';
import 'data/datasources/local/database_helper.dart';
import 'data/repositories/attempt_repository_impl.dart';
import 'data/repositories/question_repository_impl.dart';
import 'data/repositories/study_progress_repository_impl.dart';
import 'data/repositories/study_session_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'domain/usecases/ensure_local_enem_bank.dart';
import 'domain/usecases/generate_simulado.dart';
import 'domain/usecases/get_or_create_user.dart';
import 'domain/usecases/get_questions_by_filter.dart';
import 'domain/usecases/get_recent_simulados.dart';
import 'domain/usecases/get_study_progress.dart';
import 'domain/usecases/get_user_statistics.dart';
import 'domain/usecases/update_user_name.dart';
import 'domain/usecases/get_wrong_questions.dart';
import 'domain/usecases/save_attempt.dart';
import 'domain/usecases/save_study_session.dart';
import 'domain/usecases/set_weekly_goal.dart';
import 'domain/usecases/update_user_avatar.dart';
import 'domain/usecases/toggle_favorite_question.dart';
import 'presentation/providers/questions_provider.dart';
import 'presentation/providers/session_provider.dart';
import 'presentation/providers/statistics_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/screens/answer/answer_screen.dart';
import 'presentation/screens/daily_challenge/daily_challenge_launcher_screen.dart';
import 'presentation/screens/feedback/feedback_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/last_topic/last_topic_launcher_screen.dart';
import 'presentation/screens/profile/profile_photo_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/questions/questions_screen.dart';
import 'presentation/screens/review/review_screen.dart';
import 'presentation/screens/simulado/simulado_config_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/statistics/statistics_screen.dart';
import 'services/notifications/notification_service.dart';
import 'services/widgets/home_widget_service.dart';

Future<void> main() async {
  // Bloco 1 - prepara o Flutter antes de usar plugins nativos.
  // Sem isso, chamadas como SQLite, notificacoes e widgets nativos podem falhar
  // porque o motor do Flutter ainda nao terminou de inicializar.
  WidgetsFlutterBinding.ensureInitialized();

  // Bloco 2 - configura a fabrica do SQLite conforme a plataforma.
  // No Android usa SQLite normal; em testes/desktop usa a configuracao adequada.
  await initializeDatabaseFactory();

  // Bloco 3 - coloca o widget raiz na tela.
  // A partir daqui o Flutter comeca a montar a interface.
  runApp(const GabaritaApp());

  // Bloco 4 - inicializa servicos extras sem bloquear a abertura do app.
  // O unawaited deixa notificacoes e widgets carregarem em segundo plano.
  unawaited(_initializePlatformServices());
}

Future<void> _initializePlatformServices() async {
  // Bloco 1 - tenta configurar notificacoes locais.
  // O try/catch impede que uma falha de permissao/notificacao derrube o app.
  try {
    await NotificationService().initialize();
  } catch (_) {}

  // Bloco 2 - tenta configurar os widgets da tela inicial do Android.
  // Tambem fica protegido para nao travar o app caso o recurso nao exista.
  try {
    await HomeWidgetService.initialize();
  } catch (_) {}
}

class GabaritaApp extends StatefulWidget {
  const GabaritaApp({super.key});

  @override
  State<GabaritaApp> createState() => _GabaritaAppState();
}

class _GabaritaAppState extends State<GabaritaApp> {
  // Bloco 1 - chave global usada para navegar mesmo fora de uma tela especifica.
  // Ela permite que cliques em home widgets abram rotas do app.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Bloco 2 - assinatura do stream que avisa quando um home widget foi tocado.
  // Guardamos a assinatura para cancelar no dispose e evitar vazamento.
  StreamSubscription<Uri?>? _homeWidgetSubscription;

  @override
  void initState() {
    super.initState();

    // Bloco 3 - escuta cliques em widgets enquanto o app esta aberto.
    // Quando o usuario toca num widget, recebemos uma URI com a acao.
    _homeWidgetSubscription = HomeWidget.widgetClicked.listen(
      _handleHomeWidgetLaunch,
      onError: (_, __) {},
    );

    // Bloco 4 - verifica se o app foi aberto diretamente por um widget.
    // Esse trecho roda depois do primeiro frame para garantir navegador pronto.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
        _handleHomeWidgetLaunch(uri);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    // Bloco 5 - cancela a escuta dos home widgets ao destruir o app.
    // Isso evita listener ativo depois que a tela deixou de existir.
    _homeWidgetSubscription?.cancel();
    super.dispose();
  }

  void _handleHomeWidgetLaunch(Uri? uri) {
    // Bloco 6 - se nao veio nenhuma acao, nao ha nada para abrir.
    if (uri == null) return;

    // Bloco 7 - recupera o navegador global.
    // Se ele ainda nao existe, a navegacao e ignorada com seguranca.
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    // Bloco 8 - decide qual tela abrir com base no host da URI.
    // Exemplo: gabarita://stats abre a tela de estatisticas.
    switch (uri.host) {
      case 'scanner':
        navigator.pushNamed('/profile-photo');
        break;
      case 'stats':
        navigator.pushNamed('/statistics');
        break;
      case 'review':
        navigator.pushNamed('/review');
        break;
      case 'daily-challenge':
        navigator.pushNamed('/daily-challenge');
        break;
      case 'last-topic':
        navigator.pushNamed('/last-topic');
        break;
      default:
        navigator.pushNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bloco 1 - cria as implementacoes de repositorio.
    // Repositorios sao a camada que conversa com banco local e fontes de dados.
    final questionRepository = QuestionRepositoryImpl();
    final attemptRepository = AttemptRepositoryImpl();
    final userRepository = UserRepositoryImpl();
    final studyProgressRepository = StudyProgressRepositoryImpl();
    final studySessionRepository = StudySessionRepositoryImpl();

    // Bloco 2 - cria use cases compartilhados por mais de um Provider.
    // Assim a regra de salvar tentativa/estatisticas fica centralizada.
    final saveAttempt = SaveAttempt(attemptRepository);
    final getUserStatistics = GetUserStatistics(
      userRepository,
      attemptRepository,
    );
    final getStudyProgress = GetStudyProgress(studyProgressRepository);

    // Bloco 3 - injeta Providers no app inteiro.
    // Qualquer tela abaixo do MaterialApp consegue acessar esses Providers.
    return MultiProvider(
      providers: [
        // Bloco 4 - Provider do usuario, perfil, avatar, streak e meta semanal.
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(
            getOrCreateUser: GetOrCreateUser(userRepository),
            getUserStatistics: getUserStatistics,
            getStudyProgress: getStudyProgress,
            setWeeklyGoal: SetWeeklyGoal(studyProgressRepository),
            updateUserAvatar: UpdateUserAvatar(userRepository),
            updateUserName: UpdateUserName(userRepository),
          )..loadUser(),
        ),
        // Bloco 5 - Provider das questoes, filtros, favoritos e respostas.
        ChangeNotifierProvider<QuestionsProvider>(
          create: (_) => QuestionsProvider(
            ensureLocalEnemBank: EnsureLocalEnemBank(questionRepository),
            getQuestionsByFilter: GetQuestionsByFilter(questionRepository),
            getWrongQuestions: GetWrongQuestions(questionRepository),
            toggleFavoriteQuestion: ToggleFavoriteQuestion(questionRepository),
            saveAttempt: saveAttempt,
          )..initializeLocalEnemBank(),
        ),
        // Bloco 6 - Provider dos simulados: configuracao, andamento e historico.
        ChangeNotifierProvider<SessionProvider>(
          create: (_) => SessionProvider(
            generateSimulado: GenerateSimulado(questionRepository),
            saveAttempt: saveAttempt,
            saveStudySession: SaveStudySession(studySessionRepository),
            getRecentSimulados: GetRecentSimulados(studySessionRepository),
          )..initialize(),
        ),
        // Bloco 7 - Provider das estatisticas exibidas na tela de desempenho.
        ChangeNotifierProvider<StatisticsProvider>(
          create: (_) => StatisticsProvider(
            getOrCreateUser: GetOrCreateUser(userRepository),
            getUserStatistics: getUserStatistics,
            getStudyProgress: getStudyProgress,
          )..loadStatistics(1),
        ),
      ],
      child: MaterialApp(
        // Bloco 8 - usa a chave global para permitir navegacao via home widgets.
        navigatorKey: _navigatorKey,

        // Bloco 9 - configuracao visual geral do app.
        // Aqui fica o tema escuro, cores e estilo padrao de cards/bottom nav.
        title: 'Gabarita',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4DA3FF),
            brightness: Brightness.dark,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF0E131B),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF213047)),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Color(0xFF4DA3FF),
            unselectedItemColor: Color(0xFF6F7D90),
            type: BottomNavigationBarType.fixed,
          ),
        ),
        // Bloco 10 - rotas nomeadas.
        // Cada string representa um caminho usado por Navigator.pushNamed.
        routes: {
          '/main': (_) => const MainNavigationScreen(),
          '/answer': (_) => const AnswerScreen(),
          '/daily-challenge': (_) => const DailyChallengeLauncherScreen(),
          '/feedback': (_) => const FeedbackScreen(),
          '/last-topic': (_) => const LastTopicLauncherScreen(),
          '/profile-photo': (_) => const ProfilePhotoScreen(),
          '/review': (_) => const ReviewScreen(),
          '/statistics': (_) => const StatisticsScreen(),
        },
        // Bloco 11 - primeira tela carregada ao abrir o aplicativo.
        home: const SplashScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Bloco 1 - chave usada para lembrar qual aba ficou selecionada.
  // Ela e salva nas configuracoes locais do SQLite.
  static const String _lastTabSettingKey = 'last_selected_tab';

  // Bloco 2 - indice da aba atualmente selecionada no BottomNavigationBar.
  int _selectedIndex = 0;

  // Bloco 3 - lista das telas fixas da navegacao principal.
  // O indice dessa lista precisa bater com a ordem dos itens do bottom nav.
  static const List<Widget> _screens = [
    HomeScreen(showBottomNavigationBar: false),
    QuestionsScreen(),
    SimuladoConfigScreen(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Bloco 4 - tenta restaurar a ultima aba usada.
    // unawaited porque a tela pode aparecer antes da leitura terminar.
    unawaited(_restoreLastTab());
  }

  Future<void> _restoreLastTab() async {
    // Bloco 5 - le o indice salvo no banco local.
    final rawIndex =
        await DatabaseHelper.instance.getAppSetting(_lastTabSettingKey);
    final index = int.tryParse(rawIndex ?? '');

    // Bloco 6 - valida se o indice ainda existe na lista de telas.
    // Isso evita erro se a lista de abas mudar no futuro.
    if (!mounted || index == null || index < 0 || index >= _screens.length) {
      return;
    }

    // Bloco 7 - atualiza a aba visivel.
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectTab(int index) {
    // Bloco 8 - troca a aba visualmente.
    setState(() {
      _selectedIndex = index;
    });

    // Bloco 9 - salva a aba escolhida para restaurar depois.
    // Nao esperamos a gravacao porque ela nao precisa bloquear a UI.
    unawaited(
      DatabaseHelper.instance.setAppSetting(_lastTabSettingKey, '$index'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // Bloco 10 - IndexedStack mantem as telas vivas.
      // Isso evita perder estado quando o usuario troca de aba.
      // Widget especial: IndexedStack.
      // Ele guarda todas as telas montadas, mas mostra apenas a tela do indice
      // atual. Diferente de trocar o body diretamente, ele preserva estado,
      // scroll e providers internos de cada aba.
      body: IndexedStack(index: _selectedIndex, children: _screens),

      // Bloco 11 - barra de navegacao principal com cinco telas.
      // Widget especial: BottomNavigationBar.
      // E o menu fixo inferior do app. currentIndex define qual aba esta azul,
      // e onTap recebe o indice clicado para trocar de tela.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
        items: const [
          // Widget especial: BottomNavigationBarItem.
          // Cada item configura o icone e o texto de uma aba.
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            label: 'Questoes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Simulados',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
