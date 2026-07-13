import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/user_provider.dart';

// Tela: SimuladoConfigScreen.
// Objetivo: permitir que o aluno configure um simulado antes de iniciar.
// O aluno escolhe disciplinas por ChoiceChip, quantidade por Slider e depois
// o app gera uma lista de questoes usando o SessionProvider.
class SimuladoConfigScreen extends StatelessWidget {
  const SimuladoConfigScreen({super.key});

  // Lista fixa de materias/areas exibidas como chips.
  // Como e static const, ela nao e recriada toda vez que a tela redesenha.
  static const List<String> _subjects = [
    'Matematica',
    'Linguagens',
    'Ciencias Humanas',
    'Ciencias da Natureza',
    'Portugues',
    'Fisica',
  ];

  @override
  Widget build(BuildContext context) {
    // Consumer escuta SessionProvider.
    // Sempre que o usuario muda quantidade, escolhe materia ou inicia simulado,
    // o provider chama notifyListeners e esta tela atualiza.
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            // Widget especial: SingleChildScrollView.
            // Garante que a tela de configuracao do simulado role em aparelhos
            // pequenos, evitando erro de "overflow" no Flutter.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simulados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Areas de conhecimento',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Widget especial: Wrap.
                          // Organiza os ChoiceChips em varias linhas automaticamente.
                          // Se faltar espaco na linha atual, o proximo chip desce.
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _subjects.map((subject) {
                              final selected =
                                  provider.selectedSubjects.contains(subject);
                              // Widget especial: ChoiceChip.
                              // E um botao de escolha em formato de "tag".
                              // Aqui ele permite selecionar/desselecionar materias
                              // para montar o simulado.
                              return ChoiceChip(
                                label: Text(subject),
                                selected: selected,
                                selectedColor: const Color(0xFF4DA3FF),
                                backgroundColor: const Color(0xFF141D29),
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
                                  // Ao tocar no chip, alterna a materia no provider.
                                  // Se ja estava selecionada, remove; se nao estava, adiciona.
                                  provider.toggleSubject(subject);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Quantidade de questoes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                provider.questionQuantity.toString(),
                                style: const TextStyle(
                                  color: Color(0xFF4DA3FF),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          // Widget especial: Slider.
                          // Controle de arrastar usado para escolher a quantidade
                          // de questoes. min=10, max=90 e divisions=8 faz o valor
                          // andar de 10 em 10.
                          Slider(
                            min: 10,
                            max: 90,
                            divisions: 8,
                            value: provider.questionQuantity.toDouble(),
                            activeColor: const Color(0xFF4DA3FF),
                            inactiveColor: const Color(0xFF223044),
                            label: '${provider.questionQuantity} questoes',
                            // onChanged e chamado varias vezes enquanto o usuario arrasta.
                            // O provider arredonda/ajusta o valor e notifica a tela.
                            onChanged: provider.setQuestionQuantity,
                          ),
                          if (provider.errorMessage != null) ...[
                            // Mensagem de erro do provider, por exemplo quando
                            // nao ha questoes suficientes para montar o simulado.
                            Text(
                              provider.errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          ElevatedButton(
                            onPressed: provider.canStart && !provider.isLoading
                                // So deixa iniciar quando ha estado valido e nao esta carregando.
                                ? () => _startSimulado(context, provider)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4DA3FF),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              provider.isLoading
                                  ? 'Preparando...'
                                  : 'Criar simulado',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Simulados Recentes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Widget especial: ListView dentro de SingleChildScrollView.
                  // Como a pagina ja rola, a lista fica com shrinkWrap e sem
                  // rolagem propria para nao brigar com o scroll principal.
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: provider.recentSimulados.isEmpty
                        // Caso sem historico: mostra um card informativo.
                        ? const [
                            Card(
                              child: ListTile(
                                title: Text('Nenhum simulado finalizado ainda'),
                                subtitle: Text(
                                  'Sincronize questoes ENEM e inicie seu primeiro simulado.',
                                ),
                              ),
                            ),
                          ]
                        // Caso com historico: gera um card para cada simulado recente.
                        : provider.recentSimulados.map((session) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  color: Color(0xFF4DA3FF),
                                ),
                                title: Text(
                                  session.subjects.isEmpty
                                      ? 'ENEM'
                                      : session.subjects.join(', '),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${session.totalQuestions} questoes',
                                  style: const TextStyle(
                                    color: Color(0xFF9BAABD),
                                  ),
                                ),
                                trailing: Text(
                                  '${session.scorePercentage}%',
                                  style: const TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startSimulado(
    BuildContext context,
    SessionProvider sessionProvider,
  ) async {
    // Primeiro pega o id do usuario atual.
    final userId = context.read<UserProvider>().userId;

    // Garante que o banco local do ENEM foi carregado antes de montar o simulado.
    await context.read<QuestionsProvider>().initializeLocalEnemBank();
    if (!context.mounted) return;

    // Pede ao SessionProvider para sortear as questoes e criar a sessao.
    await sessionProvider.startSimulado(userId: userId);
    if (!context.mounted || sessionProvider.sessionQuestions.isEmpty) return;

    // Entrega as questoes do simulado para o QuestionsProvider,
    // porque a AnswerScreen le a questao atual a partir dele.
    context
        .read<QuestionsProvider>()
        .replaceQuestionSet(sessionProvider.sessionQuestions);

    // Abre a tela de resposta na primeira questao do simulado.
    Navigator.of(context).pushNamed('/answer');
  }
}
