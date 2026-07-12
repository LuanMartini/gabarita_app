import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';
import '../../providers/session_provider.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuestionsProvider>(
      builder: (context, provider, _) {
        final feedback = provider.lastFeedback;
        final sessionProvider = context.watch<SessionProvider>();
        final simuladoFinished =
            sessionProvider.status == SessionStatus.finished;
        final isCorrect = feedback?.isCorrect ?? false;
        final feedbackColor =
            isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
        final title = isCorrect ? 'Resposta correta' : 'Resposta incorreta';
        final message = feedback == null
            ? 'Nenhuma resposta encontrada para exibir.'
            : 'Sua resposta: ${feedback.selectedOption}  -  Gabarito: ${feedback.correctOption}\n${feedback.isCorrect ? '+${feedback.xpEarned} XP' : 'Nenhum XP concedido.'}';

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
                      Container(
                        width: 12,
                        height: 44,
                        decoration: BoxDecoration(
                          color: feedbackColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: feedbackColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: feedbackColor),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    color: const Color(0xFF0E131B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF213047)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explicacao',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          MarkdownBody(
                            data: feedback?.explanation ??
                                'Responda uma questao para ver a explicacao.',
                            selectable: true,
                            styleSheet: _feedbackMarkdownStyle(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    color: const Color(0xFF0E131B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF213047)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Questao',
                              style: TextStyle(color: Color(0xFF9BAABD)),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              feedback?.question.topic ?? '-',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: feedback == null
                        ? null
                        : () {
                            if (simuladoFinished) {
                              provider.loadQuestions();
                              Navigator.of(context).popUntil((route) {
                                return route.settings.name == '/main' ||
                                    route.isFirst;
                              });
                              return;
                            }

                            provider.nextQuestion();
                            Navigator.of(context).pushReplacementNamed(
                              '/answer',
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DA3FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      simuladoFinished
                          ? 'Finalizar simulado (${sessionProvider.scorePercentage}%)'
                          : 'Proxima questao',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) {
                        return route.settings.name == '/main' || route.isFirst;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF334761)),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Voltar para questoes'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  MarkdownStyleSheet _feedbackMarkdownStyle(BuildContext context) {
    const baseStyle = TextStyle(
      color: Color(0xFFB6C2D1),
      fontSize: 15,
      height: 1.45,
    );

    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: baseStyle,
      strong: baseStyle.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
      code: baseStyle.copyWith(
        color: const Color(0xFFE0ECFF),
        backgroundColor: const Color(0xFF182338),
        fontFamily: 'monospace',
      ),
      blockquote: baseStyle,
      listBullet: baseStyle,
    );
  }
}
