import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';

// Tela auxiliar: DailyChallengeLauncherScreen.
// Ela nao e uma tela final de conteudo. Funciona como um "atalho":
// abre, escolhe uma questao para o desafio diario e redireciona para /answer.
class DailyChallengeLauncherScreen extends StatefulWidget {
  const DailyChallengeLauncherScreen({super.key});

  @override
  State<DailyChallengeLauncherScreen> createState() =>
      _DailyChallengeLauncherScreenState();
}

class _DailyChallengeLauncherScreenState
    extends State<DailyChallengeLauncherScreen> {
  @override
  void initState() {
    super.initState();
    // Depois do primeiro frame, inicia o fluxo automatico de abrir desafio.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openChallenge());
  }

  Future<void> _openChallenge() async {
    // Le o provider de questoes sem escutar rebuilds.
    final provider = context.read<QuestionsProvider>();

    // Se ainda nao ha questoes carregadas, carrega pelo menos uma.
    if (provider.questions.isEmpty) {
      await provider.loadQuestions(limit: 1);
    }
    if (!mounted) return;

    // Se mesmo assim nao existe questao, volta para a tela principal.
    if (provider.questions.isEmpty) {
      Navigator.of(context).pushReplacementNamed('/main');
      return;
    }

    // Seleciona a primeira questao carregada.
    provider.selectQuestion(provider.questions.first);

    // Troca esta tela launcher pela tela de resposta.
    Navigator.of(context).pushReplacementNamed('/answer');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        // Widget especial: CircularProgressIndicator.
        // Mostra carregamento enquanto esta tela escolhe automaticamente
        // uma questao para o desafio diario e redireciona para /answer.
        child: CircularProgressIndicator(color: Color(0xFF4DA3FF)),
      ),
    );
  }
}
