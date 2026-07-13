import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';
import '../../providers/session_provider.dart';

// Tela: FeedbackScreen.
// Objetivo: mostrar se o aluno acertou ou errou depois de confirmar resposta.
// Ela tambem mostra o gabarito, XP, explicacao e os botoes de continuar/voltar.
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer escuta QuestionsProvider porque o feedback da ultima resposta
    // fica salvo nele.
    return Consumer<QuestionsProvider>(
      builder: (context, provider, _) {
        // lastFeedback contem questao, resposta escolhida, gabarito e explicacao.
        final feedback = provider.lastFeedback;

        // SessionProvider informa se essa resposta fazia parte de um simulado.
        final sessionProvider = context.watch<SessionProvider>();

        // Se o simulado terminou, o botao principal muda para finalizar.
        final simuladoFinished =
            sessionProvider.status == SessionStatus.finished;

        // isCorrect define cor, titulo e texto de XP.
        final isCorrect = feedback?.isCorrect ?? false;
        final feedbackColor =
            isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
        final title = isCorrect ? 'Resposta correta' : 'Resposta incorreta';

        // Mensagem principal da caixa verde/vermelha.
        final message = feedback == null
            ? 'Nenhuma resposta encontrada para exibir.'
            : 'Sua resposta: ${feedback.selectedOption}  -  Gabarito: ${feedback.correctOption}\n${feedback.isCorrect ? '+${feedback.xpEarned} XP' : 'Nenhum XP concedido.'}';

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            // Widget especial: SingleChildScrollView.
            // Permite rolar a explicacao caso o feedback ou a resolucao fique grande.
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
                  // Widget especial: Container estilizado por estado.
                  // A mesma caixa muda de cor: verde para acerto e vermelha
                  // para erro, usando a variavel feedbackColor.
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
                          // Widget especial: MarkdownBody.
                          // Exibe a explicacao da questao com suporte a Markdown,
                          // por exemplo negrito, listas e trechos de codigo/formula.
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
                  // Widget especial: ElevatedButton.
                  // Botao principal da tela. Leva para a proxima questao ou
                  // finaliza o simulado, dependendo do estado.
                  ElevatedButton(
                    onPressed: feedback == null
                        ? null
                        : () {
                            // Se acabou o simulado, volta para a tela principal
                            // e recarrega a lista padrao de questoes.
                            if (simuladoFinished) {
                              provider.loadQuestions();
                              Navigator.of(context).popUntil((route) {
                                return route.settings.name == '/main' ||
                                    route.isFirst;
                              });
                              return;
                            }

                            // Caso contrario, avanca para a proxima questao
                            // e substitui a tela atual por /answer.
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
                  // Widget especial: OutlinedButton.
                  // Botao secundario com borda. Usado para voltar sem parecer
                  // a acao principal da tela.
                  OutlinedButton(
                    onPressed: () {
                      // Volta ate a tela principal sem empilhar novas rotas.
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
    // Estilo centralizado para o Markdown da explicacao.
    // Assim o texto fica consistente com o modo escuro do app.
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
