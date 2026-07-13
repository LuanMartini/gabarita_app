import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';
import '../../providers/user_provider.dart';

// Tela: HomeScreen.
// Objetivo: ser o dashboard inicial do estudante.
// Aqui aparecem saudacao, streak, progresso semanal, metricas gerais,
// atalhos por disciplina e botao para iniciar o desafio do dia.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.showBottomNavigationBar = true,
  });

  // Controla se esta tela deve mostrar uma BottomNavigationBar propria.
  // Quando a Home esta dentro do MainNavigationScreen, esse valor vem false,
  // porque a navegacao principal ja esta no main.dart.
  final bool showBottomNavigationBar;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// State da Home.
// Foi usado StatefulWidget porque existe um indice local da barra inferior
// quando a Home roda sozinha.
class _HomeScreenState extends State<HomeScreen> {
  // Indice visual usado apenas pela barra inferior standalone desta tela.
  int _selectedIndex = 0;

  // Lista fixa dos atalhos de disciplina exibidos em "Acesso rapido".
  // Cada item tem titulo, subtitulo e icone.
  final List<_QuickSubject> _subjects = const [
    _QuickSubject(
      title: 'Matematica',
      subtitle: 'Funcoes, algebra e geometria',
      icon: Icons.calculate_outlined,
    ),
    _QuickSubject(
      title: 'Linguagens',
      subtitle: 'Interpretacao e repertorio',
      icon: Icons.menu_book_outlined,
    ),
    _QuickSubject(
      title: 'Ciencias da Natureza',
      subtitle: 'Biologia, fisica e quimica',
      icon: Icons.science_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // addPostFrameCallback roda depois do primeiro desenho da tela.
    // Isso evita chamar Provider antes de a arvore de widgets estar pronta.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Recarrega os dados do usuario para a Home mostrar numeros atuais.
      context.read<UserProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Consumer2 escuta dois providers ao mesmo tempo:
    // - UserProvider: nome, streak, meta semanal, acertos.
    // - QuestionsProvider: quantidade de questoes carregadas.
    return Consumer2<UserProvider, QuestionsProvider>(
      builder: (context, userProvider, questionsProvider, _) {
        // Nome completo salvo no perfil.
        final name = userProvider.user?.name ?? 'Lucas Mendes';

        // Primeiro nome usado na saudacao "Bom dia".
        final firstName = name.split(' ').first;

        // Iniciais usadas no CircleAvatar da Home.
        final initials = _initials(name);

        // Converte progresso 0.0..1.0 para porcentagem inteira.
        final weeklyPercent = (userProvider.weeklyGoalProgress * 100).round();

        // Converte taxa de acerto 0.0..1.0 para porcentagem inteira.
        final accuracyPercent = (userProvider.accuracyRate * 100).round();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            // Widget SingleChildScrollView.
            // Ele deixa a tela inteira rolavel. Isso evita overflow em celulares
            // menores quando o conteudo vertical fica maior que a altura da tela.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bom dia, $firstName!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              userProvider.currentStreak == 0
                                  ? 'Responda uma questao hoje para iniciar sua sequencia.'
                                  : 'Voce esta com ${userProvider.currentStreak} dias de sequencia.',
                              style: const TextStyle(
                                color: Color(0xFF9BAABD),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Widget CircleAvatar.
                      // Mostra um avatar circular. Aqui ele exibe as iniciais do
                      // aluno enquanto nao usamos a foto nessa Home.
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF4DA3FF),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101822),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF243449)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${userProvider.currentStreak} dias de sequencia!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.local_fire_department_outlined,
                          color: Color(0xFFF59E0B),
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // alinha os elementos no início do eixo contrário ao principal.
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Progresso Semanal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '$weeklyPercent%',
                                style: const TextStyle(
                                  color: Color(0xFF4DA3FF),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Widget especial: LinearProgressIndicator.
                          // Barra horizontal de progresso usada para gamificacao.
                          // value recebe um numero de 0.0 a 1.0; por exemplo,
                          // 0.68 significa 68% da meta semanal concluida.
                          LinearProgressIndicator(
                            value: userProvider.weeklyGoalProgress,
                            minHeight: 8,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            backgroundColor: const Color(0xFF223044),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              //mantém a cor do indicador fixa, sem animação de mudança de cor.
                              Color(0xFF4DA3FF),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${userProvider.weeklyAnsweredQuestions} de ${userProvider.weeklyGoalQuestions} questoes da meta semanal.',
                            style: const TextStyle(color: Color(0xFF9BAABD)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Card pequeno de metrica: total de questoes respondidas.
                      Expanded(
                        child: _MetricCard(
                          value: userProvider.totalAnswered.toString(),
                          label: 'Questoes',
                          icon: Icons.edit_note,
                          color: const Color(0xFF4DA3FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Card pequeno de metrica: porcentagem geral de acertos.
                      Expanded(
                        child: _MetricCard(
                          value: '$accuracyPercent%',
                          label: 'Acertos',
                          icon: Icons.check_circle,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Card pequeno de metrica: quantidade de questoes carregadas no banco.
                      Expanded(
                        child: _MetricCard(
                          value: questionsProvider.questions.length.toString(),
                          label: 'No banco',
                          icon: Icons.storage,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Acesso rapido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    // Widget ListView.builder dentro de outro scroll.
                    // Por isso usamos shrinkWrap true e NeverScrollableScrollPhysics:
                    // a lista ocupa apenas o tamanho dos itens e quem rola e o
                    // SingleChildScrollView da tela.
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        return ListTile(
                          leading: Icon(
                            subject.icon,
                            color: const Color(0xFF4DA3FF),
                          ),
                          title: Text(
                            subject.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            subject.subtitle,
                            style: const TextStyle(color: Color(0xFF9BAABD)),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF6F7D90),
                          ),
                          onTap: () => _openSubject(context, subject.title),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: questionsProvider.questions.isEmpty
                        ? null
                        : () => _startDailyChallenge(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DA3FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Comecar desafio de hoje'),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: widget.showBottomNavigationBar
              ? _standaloneNavigationBar()
              : null,
        );
      },
    );
  }

  Future<void> _openSubject(BuildContext context, String subject) async {
    // Quando o usuario toca em uma disciplina do acesso rapido,
    // filtramos o banco por aquela disciplina.
    final provider = context.read<QuestionsProvider>();
    await provider.setSingleSubjectFilter(subject);

    // Se a tela saiu da arvore ou nao existe questao, nao navega.
    if (!context.mounted || provider.questions.isEmpty) return;

    // Seleciona a primeira questao encontrada e abre a tela de resposta.
    provider.selectQuestion(provider.questions.first);
    Navigator.of(context).pushNamed('/answer');
  }

  void _startDailyChallenge(BuildContext context) {
    // Fluxo simples do desafio do dia:
    // pega a primeira questao disponivel, seleciona no provider e abre /answer.
    final provider = context.read<QuestionsProvider>();
    provider.selectQuestion(provider.questions.first);
    Navigator.of(context).pushNamed('/answer');
  }

  BottomNavigationBar _standaloneNavigationBar() {
    // Widget BottomNavigationBar.
    // E a barra de navegacao inferior com abas fixas. Cada item representa
    // uma area principal do app: Home, Questoes, Simulado, Stats e Perfil.
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      backgroundColor: Colors.black,
      selectedItemColor: const Color(0xFF4DA3FF),
      unselectedItemColor: const Color(0xFF6F7D90),
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        // onTap informa qual item foi clicado. setState muda o indice visual.
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        // Widget especial: BottomNavigationBarItem.
        // Define o icone e o texto de cada aba da barra inferior.
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz_outlined),
          label: 'Questoes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle_outline),
          label: 'Simulado',
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
    );
  }

  String _initials(String name) {
    // Divide o nome por espacos para tentar pegar primeiro e ultimo nome.
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'LM';

    // Primeira letra do primeiro nome.
    final first = parts.first.substring(0, 1);

    // Primeira letra do ultimo nome, se existir.
    final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }
}

// Widget privado para os cards pequenos de metrica da Home.
// Ele recebe valor, legenda, icone e cor para ser reutilizado tres vezes.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Card cria um bloco visual com fundo, borda/elevação do tema e padding interno.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF9BAABD)),
            ),
          ],
        ),
      ),
    );
  }
}

// Modelo simples usado somente pela Home para montar atalhos por disciplina.
class _QuickSubject {
  const _QuickSubject({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
