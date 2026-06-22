import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';
import '../../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.showBottomNavigationBar = true,
  });

  final bool showBottomNavigationBar;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, QuestionsProvider>(
      builder: (context, userProvider, questionsProvider, _) {
        final name = userProvider.user?.name ?? 'Lucas Mendes';
        final firstName = name.split(' ').first;
        final initials = _initials(name);
        final weeklyPercent = (userProvider.weeklyGoalProgress * 100).round();
        final accuracyPercent = (userProvider.accuracyRate * 100).round();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          LinearProgressIndicator(
                            value: userProvider.weeklyGoalProgress,
                            minHeight: 8,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            backgroundColor: const Color(0xFF223044),
                            valueColor: const AlwaysStoppedAnimation<Color>(
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
                      Expanded(
                        child: _MetricCard(
                          value: userProvider.totalAnswered.toString(),
                          label: 'Questoes',
                          icon: Icons.edit_note,
                          color: const Color(0xFF4DA3FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          value: '$accuracyPercent%',
                          label: 'Acertos',
                          icon: Icons.check_circle,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(width: 10),
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
    final provider = context.read<QuestionsProvider>();
    await provider.setSingleSubjectFilter(subject);
    if (!context.mounted || provider.questions.isEmpty) return;
    provider.selectQuestion(provider.questions.first);
    Navigator.of(context).pushNamed('/answer');
  }

  void _startDailyChallenge(BuildContext context) {
    final provider = context.read<QuestionsProvider>();
    provider.selectQuestion(provider.questions.first);
    Navigator.of(context).pushNamed('/answer');
  }

  BottomNavigationBar _standaloneNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      backgroundColor: Colors.black,
      selectedItemColor: const Color(0xFF4DA3FF),
      unselectedItemColor: const Color(0xFF6F7D90),
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
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
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'LM';
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }
}

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
