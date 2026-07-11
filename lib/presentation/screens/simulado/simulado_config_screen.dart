import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/user_provider.dart';

class SimuladoConfigScreen extends StatelessWidget {
  const SimuladoConfigScreen({super.key});

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
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _subjects.map((subject) {
                              final selected =
                                  provider.selectedSubjects.contains(subject);
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
                          Slider(
                            min: 10,
                            max: 90,
                            divisions: 8,
                            value: provider.questionQuantity.toDouble(),
                            activeColor: const Color(0xFF4DA3FF),
                            inactiveColor: const Color(0xFF223044),
                            label: '${provider.questionQuantity} questoes',
                            onChanged: provider.setQuestionQuantity,
                          ),
                          if (provider.errorMessage != null) ...[
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
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: provider.recentSimulados.isEmpty
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
    final userId = context.read<UserProvider>().userId;
    await context.read<QuestionsProvider>().initializeLocalEnemBank();
    if (!context.mounted) return;

    await sessionProvider.startSimulado(userId: userId);
    if (!context.mounted || sessionProvider.sessionQuestions.isEmpty) return;

    context
        .read<QuestionsProvider>()
        .replaceQuestionSet(sessionProvider.sessionQuestions);
    Navigator.of(context).pushNamed('/answer');
  }
}
