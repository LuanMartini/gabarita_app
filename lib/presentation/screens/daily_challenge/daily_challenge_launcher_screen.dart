import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _openChallenge());
  }

  Future<void> _openChallenge() async {
    final provider = context.read<QuestionsProvider>();
    if (provider.questions.isEmpty) {
      await provider.loadQuestions(limit: 1);
    }
    if (!mounted) return;

    if (provider.questions.isEmpty) {
      Navigator.of(context).pushReplacementNamed('/main');
      return;
    }

    provider.selectQuestion(provider.questions.first);
    Navigator.of(context).pushReplacementNamed('/answer');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF4DA3FF)),
      ),
    );
  }
}
