import 'package:flutter/material.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = const [
    'Todas',
    'Matematica',
    'Portugues',
    'Biologia',
    'Historia',
    'ENEM',
    'Favoritas',
  ];
  final List<_QuestionPreview> _questions = const [
    _QuestionPreview(
      subject: 'Matematica',
      title: 'Equacao do segundo grau',
      subtitle: 'Funcoes e raizes reais',
      difficulty: 'Facil',
    ),
    _QuestionPreview(
      subject: 'Biologia',
      title: 'Organela produtora de ATP',
      subtitle: 'Citologia e metabolismo celular',
      difficulty: 'Facil',
    ),
    _QuestionPreview(
      subject: 'Portugues',
      title: 'Figura de linguagem',
      subtitle: 'Metafora em texto literario',
      difficulty: 'Media',
    ),
  ];

  String _selectedFilter = 'Todas';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              const Text(
                'Banco de questoes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar por assunto, banca ou palavra-chave',
                  hintStyle: const TextStyle(color: Color(0xFF6F7D90)),
                  filled: true,
                  fillColor: const Color(0xFF0E131B),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6F7D90),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filters.map((filter) {
                  final selected = filter == _selectedFilter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    selectedColor: const Color(0xFF4DA3FF),
                    backgroundColor: const Color(0xFF0E131B),
                    labelStyle: TextStyle(
                      color:
                          selected ? Colors.white : const Color(0xFFB6C2D1),
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF4DA3FF)
                          : const Color(0xFF26364A),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _visibleQuestions.length,
                itemBuilder: (context, index) {
                  final question = _visibleQuestions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        question.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${question.subject} - ${question.subtitle}',
                          style: const TextStyle(
                            color: Color(0xFF9BAABD),
                            height: 1.3,
                          ),
                        ),
                      ),
                      trailing: Text(
                        question.difficulty,
                        style: const TextStyle(
                          color: Color(0xFF4DA3FF),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed('/answer');
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_QuestionPreview> get _visibleQuestions {
    final query = _searchController.text.trim().toLowerCase();
    return _questions.where((question) {
      final matchesFilter = _selectedFilter == 'Todas' ||
          question.subject == _selectedFilter ||
          _selectedFilter == 'ENEM' ||
          _selectedFilter == 'Favoritas';
      final matchesQuery = query.isEmpty ||
          question.title.toLowerCase().contains(query) ||
          question.subject.toLowerCase().contains(query) ||
          question.subtitle.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }
}

class _QuestionPreview {
  const _QuestionPreview({
    required this.subject,
    required this.title,
    required this.subtitle,
    required this.difficulty,
  });

  final String subject;
  final String title;
  final String subtitle;
  final String difficulty;
}
