import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/question.dart';
import '../../providers/questions_provider.dart';
import '../../providers/user_provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<UserProvider>().userId;
      context.read<QuestionsProvider>().loadReviewQuestions(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Consumer<QuestionsProvider>(
        builder: (context, provider, _) {
          return Scaffold(
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
                          Tab(text: 'Erradas'),
                          Tab(text: 'Favoritas'),
                          Tab(text: 'Recomendadas'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 560,
                      decoration: BoxDecoration(
                        color: const Color(0xFF05070A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TabBarView(
                        children: [
                          _ReviewQuestionList(
                            emptyText: 'Nenhum erro registrado ainda.',
                            questions: provider.wrongQuestions,
                            buttonLabel: 'Revisar',
                          ),
                          _ReviewQuestionList(
                            emptyText: 'Nenhuma questao favoritada ainda.',
                            questions: provider.favoriteQuestions,
                            buttonLabel: 'Abrir',
                          ),
                          _ReviewQuestionList(
                            emptyText: 'Sincronize o ENEM para gerar dicas.',
                            questions: provider.recommendedQuestions,
                            buttonLabel: 'Treinar',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewQuestionList extends StatelessWidget {
  const _ReviewQuestionList({
    required this.emptyText,
    required this.questions,
    required this.buttonLabel,
  });

  final String emptyText;
  final List<Question> questions;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9BAABD)),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.subject,
                  style: const TextStyle(
                    color: Color(0xFF9BAABD),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question.topic,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question.examSource ?? 'Banco local',
                  style: const TextStyle(color: Color(0xFF7D8FA6)),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    context.read<QuestionsProvider>().selectQuestion(question);
                    Navigator.of(context).pushNamed('/answer');
                  },
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
