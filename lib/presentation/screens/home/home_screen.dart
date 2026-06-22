import 'package:flutter/material.dart';

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
      title: 'Portugues',
      subtitle: 'Interpretacao e gramatica',
      icon: Icons.menu_book_outlined,
    ),
    _QuickSubject(
      title: 'Ciencias da Natureza',
      subtitle: 'Biologia, fisica e quimica',
      icon: Icons.science_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bom dia, Lucas!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Seu dashboard de estudos esta pronto.',
                          style: TextStyle(
                            color: Color(0xFF9BAABD),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF4DA3FF),
                    child: Text(
                      'LM',
                      style: TextStyle(
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
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        '45 dias de sequencia!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
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
                      const Row(
                        children: [
                          Expanded(
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
                            '76%',
                            style: TextStyle(
                              color: Color(0xFF4DA3FF),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const LinearProgressIndicator(
                        value: 0.76,
                        minHeight: 8,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        backgroundColor: Color(0xFF223044),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF4DA3FF)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Acertos, revisoes e simulados da semana.',
                        style: TextStyle(color: Color(0xFF9BAABD)),
                      ),
                    ],
                  ),
                ),
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
                      onTap: () {},
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {},
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
      bottomNavigationBar:
          widget.showBottomNavigationBar ? _standaloneNavigationBar() : null,
    );
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
