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
            child: RefreshIndicator(
              color: const Color(0xFF4DA3FF),
              backgroundColor: const Color(0xFF0E131B),
              onRefresh: () => _refreshQuestions(provider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 92),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Banco de questoes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        PopupMenuButton<_QuestionMenuAction>(
                          tooltip: 'Acoes',
                          color: const Color(0xFF0E131B),
                          iconColor: const Color(0xFF4DA3FF),
                          onSelected: (action) =>
                              _handleMenuAction(context, provider, action),
                          itemBuilder: (context) {
                            return const [
                              PopupMenuItem(
                                value: _QuestionMenuAction.importJson,
                                child: Text('Importar JSON ENEM'),
                              ),
                              PopupMenuItem(
                                value: _QuestionMenuAction.clearFilters,
                                child: Text('Limpar filtros'),
                              ),
                              PopupMenuItem(
                                value: _QuestionMenuAction.openScanner,
                                child: Text('Abrir scanner'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(
                          '/scanner',
                        ),
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('Escanear questao'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4DA3FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
                      onSubmitted: provider.setSearchText,
                    ),
                    const SizedBox(height: 14),
                    _EnemSyncCard(provider: provider),
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
                            color: selected
                                ? Colors.white
                                : const Color(0xFFB6C2D1),
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
                        provider.isLoading
                            ? 'Carregando questoes...'
                            : '${questions.length} questoes encontradas',
                        key: ValueKey(
                          '${provider.isLoading}-${provider.favoritesOnly}-${questions.length}',
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
                          onFavorite: () => provider.toggleFavorite(question),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshQuestions(QuestionsProvider provider) async {
    await Future.wait([
      provider.loadQuestions(),
      provider.loadAvailableEnemExams(),
    ]);
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    QuestionsProvider provider,
    _QuestionMenuAction action,
  ) async {
    switch (action) {
      case _QuestionMenuAction.importJson:
        await provider.syncSelectedEnemExam();
        break;
      case _QuestionMenuAction.clearFilters:
        _searchController.clear();
        setState(() {
          _selectedFilter = 'Todas';
        });
        provider.clearFilters();
        await provider.loadQuestions();
        break;
      case _QuestionMenuAction.openScanner:
        if (!context.mounted) return;
        Navigator.of(context).pushNamed('/scanner');
        break;
    }
  }
}

enum _QuestionMenuAction {
  importJson,
  clearFilters,
  openScanner,
}

class _EnemSyncCard extends StatelessWidget {
  const _EnemSyncCard({required this.provider});

  final QuestionsProvider provider;

  @override
  Widget build(BuildContext context) {
    final exams = provider.availableEnemExams;
    final selectedYear = provider.selectedEnemYear ?? 2025;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Banco local do ENEM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (exams.isEmpty
                        ? const [2025, 2024, 2023]
                        : exams.map((exam) => exam.year).take(6).toList())
                    .map((year) {
                  final selected = year == selectedYear;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(year.toString()),
                      selected: selected,
                      selectedColor: const Color(0xFF4DA3FF),
                      backgroundColor: const Color(0xFF141D29),
                      labelStyle: TextStyle(
                        color:
                            selected ? Colors.white : const Color(0xFFB6C2D1),
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) {
                        provider.setSelectedEnemYear(year);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: provider.isSyncingEnem
                  ? null
                  : () => provider.syncSelectedEnemExam(),
              icon: provider.isSyncingEnem
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(
                provider.isSyncingEnem
                    ? 'Importando...'
                    : 'Carregar ENEM $selectedYear offline',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DA3FF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (provider.syncMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                provider.syncMessage!,
                style: const TextStyle(color: Color(0xFF9BAABD)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.onFavorite,
  });

  final Question question;
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
              onPressed: onFavorite,
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
