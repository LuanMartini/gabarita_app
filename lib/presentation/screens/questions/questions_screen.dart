import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/question.dart';
import '../../providers/questions_provider.dart';

// Bloco 1 - tela do banco de questoes.
// Ela mostra busca, filtro por ENEM, ChoiceChips de disciplina e lista de cards.
class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  // Bloco 2 - controller do campo de busca.
  // Precisa ser descartado no dispose para nao vazar memoria.
  final TextEditingController _searchController = TextEditingController();

  // Bloco 3 - anos disponiveis no filtro de prova.
  // O Provider transforma o ano escolhido em examSource, exemplo "ENEM 2023".
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

  // Bloco 4 - filtros visuais por disciplina.
  // "Todas" limpa o filtro de materia.
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

  // Bloco 5 - estado local apenas para pintar o ChoiceChip selecionado.
  // A lista real de questoes fica no QuestionsProvider.
  String _selectedFilter = 'Todas';

  @override
  void dispose() {
    // Bloco 6 - libera o controller quando a tela sai da arvore.
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bloco 7 - Consumer escuta o QuestionsProvider.
    // Quando o provider chama notifyListeners, esta parte da tela redesenha.
    return Consumer<QuestionsProvider>(
      builder: (context, provider, _) {
        // Bloco 8 - lista ja filtrada pelo provider.
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
                  // Bloco 9 - busca textual.
                  // A busca so dispara ao enviar o teclado para evitar recarregar
                  // a lista a cada letra digitada.
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
                  // Bloco 10 - filtro por ano/prova do ENEM.
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
                        // Bloco 11 - DropdownButton exigido para escolher ENEM especifico.
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
                            // Bloco 12 - valor 0 representa "Todos os ENEMs".
                            provider.setExamYearFilter(
                              value == null || value == 0 ? null : value,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Bloco 13 - ChoiceChips das disciplinas.
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
                          // Bloco 14 - atualiza a cor do chip nesta tela.
                          setState(() {
                            _selectedFilter = filter;
                          });
                          // Bloco 15 - pede ao provider para aplicar o filtro real.
                          provider.setSingleSubjectFilter(filter);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Bloco 16 - switch para mostrar apenas favoritas.
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
                        // Bloco 17 - provider alterna o filtro e recarrega a lista.
                        provider.toggleFavoritesOnly();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bloco 18 - contador animado de questoes encontradas.
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
                  // Bloco 19 - mensagem de erro amigavel, sem travar a tela.
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  // Bloco 20 - lista dentro do scroll principal.
                  // Por isso usa shrinkWrap e NeverScrollableScrollPhysics.
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
                        // Bloco 21 - favorito fica desabilitado enquanto salva.
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

// Bloco 22 - card de uma questao na lista.
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
              // Bloco 23 - botao de favorito.
              // Se isFavoriteUpdating for true, onPressed vira null para impedir
              // clique duplo e travamento.
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
          // Bloco 24 - seleciona a questao no provider antes de abrir a tela.
          context.read<QuestionsProvider>().selectQuestion(question);
          // Bloco 25 - navega para a tela de resposta.
          Navigator.of(context).pushNamed('/answer');
        },
      ),
    );
  }

  // Bloco 26 - transforma dificuldade numerica em texto.
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
