import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/datasources/local/database_helper.dart';
import '../../providers/questions_provider.dart';
import '../../providers/user_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _openLastTopic());
  }

  Future<void> _openLastTopic() async {
    final provider = context.read<QuestionsProvider>();
    final subject = await _readLastSubject();

    if (subject != null && subject.isNotEmpty) {
      await provider.setSingleSubjectFilter(subject);
    } else if (provider.questions.isEmpty) {
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

  Future<String?> _readLastSubject() async {
    try {
      final userId = context.read<UserProvider>().userId;
      final topic = await DatabaseHelper.instance.getLastStudiedTopic(userId);
      final subject = topic?['subject']?.toString();
      if (subject == null ||
          subject.isEmpty ||
          subject == 'Comece respondendo uma questao') {
        return null;
      }
      return subject;
    } catch (_) {
      return null;
    }
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
