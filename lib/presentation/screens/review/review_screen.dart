import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/question.dart';
import '../../providers/questions_provider.dart';
import '../../providers/user_provider.dart';

// Tela: ReviewScreen.
// Objetivo: organizar a revisao inteligente em abas.
// Mostra questoes erradas, favoritas e recomendadas para o aluno treinar.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  void initState() {
    super.initState();
    // Depois do primeiro frame, carrega as listas de revisao do usuario.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Pega o id do perfil atual.
      final userId = context.read<UserProvider>().userId;

      // Carrega erradas, favoritas e recomendadas no QuestionsProvider.
      context.read<QuestionsProvider>().loadReviewQuestions(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Widget especial: DefaultTabController.
    // Ele cria e gerencia automaticamente o controlador das abas.
    // length: 3 porque temos tres abas: Erradas, Favoritas e Recomendadas.
    return DefaultTabController(
      length: 3,
      child: Consumer<QuestionsProvider>(
        builder: (context, provider, _) {
          // O provider entrega as tres listas usadas pelas abas.
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              // Widget  SingleChildScrollView.
              // Deixa o cabecalho e a area de abas rolarem se a tela for pequena.
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
                      // Widget  TabBar.
                      // E a barra de abas clicaveis. Ao tocar em uma aba,
                      // o TabBarView abaixo muda para o conteudo correspondente.
                      child: const TabBar(
                        indicatorColor: Color(0xFF4DA3FF),
                        labelColor: Colors.white,
                        unselectedLabelColor: Color(0xFF7D8FA6),
                        tabs: [
                          // Widget  Tab.
                          // Cada Tab representa uma aba dentro do TabBar.
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
                      // Widget TabBarView.
                      // E o corpo das abas. A primeira tela corresponde a primeira
                      // Tab, a segunda corresponde a segunda, e assim por diante.
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
    // Quando a lista esta vazia, mostra uma mensagem centralizada.
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

    // Widget  ListView.builder.
    // Cria os cards sob demanda conforme a lista cresce. E melhor que gerar
    // todos os widgets manualmente quando pode haver muitas questoes.
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        // Questao atual da lista.
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
                    // Antes de navegar, salva a questao escolhida no provider.
                    // A AnswerScreen vai ler provider.currentQuestion.
                    context.read<QuestionsProvider>().selectQuestion(question);

                    // Abre a tela de resposta para revisar/treinar essa questao.
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
