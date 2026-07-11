import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import 'core/database/database_initializer.dart';
import 'data/repositories/attempt_repository_impl.dart';
import 'data/repositories/question_repository_impl.dart';
import 'data/repositories/study_progress_repository_impl.dart';
import 'data/repositories/study_session_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'domain/usecases/add_question.dart';
import 'domain/usecases/generate_simulado.dart';
import 'domain/usecases/get_available_enem_exams.dart';
import 'domain/usecases/get_or_create_user.dart';
import 'domain/usecases/get_questions_by_filter.dart';
import 'domain/usecases/get_recent_simulados.dart';
import 'domain/usecases/get_study_progress.dart';
import 'domain/usecases/get_user_statistics.dart';
import 'domain/usecases/get_wrong_questions.dart';
import 'domain/usecases/save_attempt.dart';
import 'domain/usecases/save_study_session.dart';
import 'domain/usecases/set_weekly_goal.dart';
import 'domain/usecases/sync_enem_questions.dart';
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
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/questions/questions_screen.dart';
import 'presentation/screens/review/review_screen.dart';
import 'presentation/screens/scanner/scanner_screen.dart';
import 'presentation/screens/simulado/simulado_config_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/statistics/statistics_screen.dart';
import 'services/notifications/notification_service.dart';
import 'services/widgets/home_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabaseFactory();
  runApp(const GabaritaApp());
  unawaited(_initializePlatformServices());
}

Future<void> _initializePlatformServices() async {
  try {
    await NotificationService().initialize();
  } catch (_) {}

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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri?>? _homeWidgetSubscription;

  @override
  void initState() {
    super.initState();
    _homeWidgetSubscription = HomeWidget.widgetClicked.listen(
      _handleHomeWidgetLaunch,
      onError: (_, __) {},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
        _handleHomeWidgetLaunch(uri);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _homeWidgetSubscription?.cancel();
    super.dispose();
  }

  void _handleHomeWidgetLaunch(Uri? uri) {
    if (uri == null) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    switch (uri.host) {
      case 'scanner':
        navigator.pushNamed('/scanner');
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
    final questionRepository = QuestionRepositoryImpl();
    final attemptRepository = AttemptRepositoryImpl();
    final userRepository = UserRepositoryImpl();
    final studyProgressRepository = StudyProgressRepositoryImpl();
    final studySessionRepository = StudySessionRepositoryImpl();
    final saveAttempt = SaveAttempt(attemptRepository);
    final getUserStatistics = GetUserStatistics(
      userRepository,
      attemptRepository,
    );
    final getStudyProgress = GetStudyProgress(studyProgressRepository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(
            getOrCreateUser: GetOrCreateUser(userRepository),
            getUserStatistics: getUserStatistics,
            getStudyProgress: getStudyProgress,
            setWeeklyGoal: SetWeeklyGoal(studyProgressRepository),
          )..loadUser(),
        ),
        ChangeNotifierProvider<QuestionsProvider>(
          create: (_) => QuestionsProvider(
            getAvailableEnemExams: GetAvailableEnemExams(questionRepository),
            getQuestionsByFilter: GetQuestionsByFilter(questionRepository),
            getWrongQuestions: GetWrongQuestions(questionRepository),
            toggleFavoriteQuestion: ToggleFavoriteQuestion(questionRepository),
            saveAttempt: saveAttempt,
            syncEnemQuestions: SyncEnemQuestions(questionRepository),
            addQuestion: AddQuestion(questionRepository),
          )..initializeLocalEnemBank(),
        ),
        ChangeNotifierProvider<SessionProvider>(
          create: (_) => SessionProvider(
            generateSimulado: GenerateSimulado(questionRepository),
            saveAttempt: saveAttempt,
            saveStudySession: SaveStudySession(studySessionRepository),
            getRecentSimulados: GetRecentSimulados(studySessionRepository),
          )..initialize(),
        ),
        ChangeNotifierProvider<StatisticsProvider>(
          create: (_) => StatisticsProvider(
            getOrCreateUser: GetOrCreateUser(userRepository),
            getUserStatistics: getUserStatistics,
            getStudyProgress: getStudyProgress,
          )..loadStatistics(1),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
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
        routes: {
          '/main': (_) => const MainNavigationScreen(),
          '/answer': (_) => const AnswerScreen(),
          '/daily-challenge': (_) => const DailyChallengeLauncherScreen(),
          '/feedback': (_) => const FeedbackScreen(),
          '/last-topic': (_) => const LastTopicLauncherScreen(),
          '/review': (_) => const ReviewScreen(),
          '/scanner': (_) => const ScannerScreen(),
          '/statistics': (_) => const StatisticsScreen(),
        },
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
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(showBottomNavigationBar: false),
    QuestionsScreen(),
    SimuladoConfigScreen(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
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
