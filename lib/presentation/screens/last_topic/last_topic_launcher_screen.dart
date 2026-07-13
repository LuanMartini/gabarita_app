import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/datasources/local/database_helper.dart';
import '../../providers/questions_provider.dart';
import '../../providers/user_provider.dart';

// Tela auxiliar: LastTopicLauncherScreen.
// Objetivo: abrir rapidamente uma questao da ultima disciplina estudada.
// Ela consulta o SQLite, aplica o filtro no QuestionsProvider e redireciona.
class LastTopicLauncherScreen extends StatefulWidget {
  const LastTopicLauncherScreen({super.key});

  @override
  State<LastTopicLauncherScreen> createState() =>
      _LastTopicLauncherScreenState();
}

class _LastTopicLauncherScreenState extends State<LastTopicLauncherScreen> {
  @override
  void initState() {
    super.initState();
    // Executa depois do primeiro frame para poder usar Provider/Navigator.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openLastTopic());
  }

  Future<void> _openLastTopic() async {
    // Provider que controla lista e questao selecionada.
    final provider = context.read<QuestionsProvider>();

    // Busca no banco a ultima disciplina estudada.
    final subject = await _readLastSubject();

    if (subject != null && subject.isNotEmpty) {
      // Se achou disciplina, filtra questoes por ela.
      await provider.setSingleSubjectFilter(subject);
    } else if (provider.questions.isEmpty) {
      // Se nao achou historico, carrega uma questao qualquer como fallback.
      await provider.loadQuestions(limit: 1);
    }
    if (!mounted) return;

    // Sem questoes para abrir, volta para a tela principal.
    if (provider.questions.isEmpty) {
      Navigator.of(context).pushReplacementNamed('/main');
      return;
    }

    // Seleciona a primeira questao filtrada e abre a tela de resposta.
    provider.selectQuestion(provider.questions.first);
    Navigator.of(context).pushReplacementNamed('/answer');
  }

  Future<String?> _readLastSubject() async {
    try {
      // Descobre o usuario local.
      final userId = context.read<UserProvider>().userId;

      // Consulta DatabaseHelper diretamente porque esta tela e um launcher simples.
      final topic = await DatabaseHelper.instance.getLastStudiedTopic(userId);
      final subject = topic?['subject']?.toString();

      // Ignora textos vazios ou placeholder.
      if (subject == null ||
          subject.isEmpty ||
          subject == 'Comece respondendo uma questao') {
        return null;
      }
      return subject;
    } catch (_) {
      // Qualquer falha de banco vira null para usar fallback.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        // Widget CircularProgressIndicator.
        // Aparece enquanto o app busca a ultima disciplina estudada no SQLite
        // e redireciona para a proxima questao daquele assunto.
        child: CircularProgressIndicator(color: Color(0xFF4DA3FF)),
      ),
    );
  }
}
