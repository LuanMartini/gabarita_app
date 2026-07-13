import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/question.dart';
import '../../providers/questions_provider.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<int> _enemYears = [
    2025,
    2024,
    2023,
    2022,
    2021,
    2020,
    2019,
    2018,
    2017,
    2016,
    2015,
    2014,
    2013,
    2012,
    2011,
    2010,
    2009,
  ];

  final List<String> _filters = const [
    'Todas',
    'Matematica',
    'Linguagens',
    'Ciencias Humanas',
    'Ciencias da Natureza',
    'Portugues',
    'Fisica',
    'Quimica',
    'Biologia',
  ];

  String _selectedFilter = 'Todas';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuestionsProvider>(
      builder: (context, provider, _) {
        final questions = provider.questions;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 92),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Banco de questoes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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
                    onSubmitted: provider.setSearchText,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E131B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF26364A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_note_outlined,
                          color: Color(0xFF4DA3FF),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Prova',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        DropdownButton<int>(
                          value: provider.selectedExamYear ?? 0,
                          dropdownColor: const Color(0xFF0E131B),
                          underline: const SizedBox.shrink(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: 0,
                              child: Text('Todos os ENEMs'),
                            ),
                            ..._enemYears.map(
                              (year) => DropdownMenuItem<int>(
                                value: year,
                                child: Text('ENEM $year'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            provider.setExamYearFilter(
                              value == null || value == 0 ? null : value,
                            );
                          },
                        ),
                      ],
                    ),
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
                          provider.setSingleSubjectFilter(filter);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: SwitchListTile(
                      value: provider.favoritesOnly,
                      activeThumbColor: const Color(0xFF4DA3FF),
                      activeTrackColor: const Color(0xFF12395C),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      secondary: const Icon(
                        Icons.favorite_border,
                        color: Color(0xFF4DA3FF),
                      ),
                      title: const Text(
                        'Somente favoritas',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: const Text(
                        'Filtrar questoes marcadas para revisar depois',
                        style: TextStyle(color: Color(0xFF9BAABD)),
                      ),
                      onChanged: (_) {
                        provider.toggleFavoritesOnly();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      provider.selectedExamYear == null
                          ? '${questions.length} questoes encontradas'
                          : '${questions.length} questoes do ENEM ${provider.selectedExamYear}',
                      key: ValueKey(
                        '${provider.selectedExamYear}-${provider.favoritesOnly}-${questions.length}',
                      ),
                      style: const TextStyle(color: Color(0xFF9BAABD)),
                    ),
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return _QuestionCard(
                        question: question,
                        isFavoriteUpdating:
                            provider.isFavoriteUpdating(question.id),
                        onFavorite: () => provider.toggleFavorite(question),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.isFavoriteUpdating,
    required this.onFavorite,
  });

  final Question question;
  final bool isFavoriteUpdating;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          question.topic,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${question.examSource ?? 'Banco local'} - ${question.subject}',
            style: const TextStyle(
              color: Color(0xFF9BAABD),
              height: 1.3,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _difficultyLabel(question.difficulty),
              style: const TextStyle(
                color: Color(0xFF4DA3FF),
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              tooltip: 'Favoritar',
              onPressed: isFavoriteUpdating ? null : onFavorite,
              icon: Icon(
                question.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: question.isFavorite
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF6F7D90),
              ),
            ),
          ],
        ),
        onTap: () {
          context.read<QuestionsProvider>().selectQuestion(question);
          Navigator.of(context).pushNamed('/answer');
        },
      ),
    );
  }

  String _difficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Facil';
      case 3:
        return 'Dificil';
      default:
        return 'Medio';
    }
  }
}
