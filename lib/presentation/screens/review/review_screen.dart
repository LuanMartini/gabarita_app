import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revisao inteligente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Seus pontos fracos organizados por prioridade.',
                  style: TextStyle(color: Color(0xFF9BAABD)),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E131B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF213047)),
                  ),
                  child: const TabBar(
                    indicatorColor: Color(0xFF4DA3FF),
                    labelColor: Colors.white,
                    unselectedLabelColor: Color(0xFF7D8FA6),
                    tabs: [
                      Tab(text: 'Dicas'),
                      Tab(text: 'Materias'),
                      Tab(text: 'Salvas'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 520,
                  decoration: BoxDecoration(
                    color: const Color(0xFF05070A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TabBarView(
                    children: [
                      _ReviewList(
                        title: 'Dica de estudo',
                        buttonLabel: 'Aplicar dica',
                        items: [
                          'Revise funcoes antes de probabilidade',
                          'Leia enunciados sublinhando comandos',
                          'Separe 15 minutos para citologia',
                        ],
                      ),
                      _ReviewList(
                        title: 'Materia a revisar',
                        buttonLabel: 'Treinar tema',
                        items: [
                          'Equacao do segundo grau',
                          'Figuras de linguagem',
                          'Quimica ambiental',
                        ],
                      ),
                      _ReviewList(
                        title: 'Questao salva',
                        buttonLabel: 'Abrir questao',
                        items: [
                          'Brasil Imperio',
                          'Ecologia',
                          'Funcoes organicas',
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({
    required this.title,
    required this.buttonLabel,
    required this.items,
  });

  final String title;
  final String buttonLabel;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF9BAABD),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  items[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DA3FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
