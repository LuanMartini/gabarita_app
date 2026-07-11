import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().refresh();
      context.read<SessionProvider>().loadRecentSimulados(
            userId: context.read<UserProvider>().userId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, SessionProvider>(
      builder: (context, userProvider, sessionProvider, _) {
        final user = userProvider.user;
        final name = user?.name ?? 'Lucas Mendes';
        final initials = _initials(name);
        final weeklyPercent = (userProvider.weeklyGoalProgress * 100).round();
        final accuracyPercent = (userProvider.accuracyRate * 100).round();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFF4DA3FF),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E131B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF213047)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Meta Semanal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '$weeklyPercent%',
                              style: const TextStyle(
                                color: Color(0xFF4DA3FF),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${userProvider.weeklyAnsweredQuestions} de ${userProvider.weeklyGoalQuestions} questoes - faltam ${userProvider.remainingWeeklyQuestions}',
                          style: const TextStyle(color: Color(0xFF9BAABD)),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: userProvider.weeklyGoalProgress,
                          minHeight: 8,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          backgroundColor: const Color(0xFF223044),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4DA3FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conquistas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Chip(
                                  avatar: const Icon(
                                    Icons.local_fire_department,
                                  ),
                                  label: Text(
                                    '${userProvider.currentStreak} dias',
                                  ),
                                  backgroundColor: const Color(0xFF142C1F),
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Chip(
                                  avatar: const Icon(Icons.center_focus_strong),
                                  label: Text('$accuracyPercent% acerto'),
                                  backgroundColor: const Color(0xFF122D47),
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF4DA3FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Historico do mes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.quiz_outlined,
                          color: Color(0xFF4DA3FF),
                        ),
                        title: Text(
                          '${userProvider.totalAnswered} questoes respondidas',
                        ),
                        subtitle: const Text('Total acumulado'),
                        trailing: Text('$accuracyPercent%'),
                      ),
                      ...sessionProvider.recentSimulados.take(3).map((session) {
                        return ListTile(
                          leading: const Icon(
                            Icons.assignment_turned_in_outlined,
                            color: Color(0xFF22C55E),
                          ),
                          title: const Text('Simulado ENEM finalizado'),
                          subtitle: Text('${session.totalQuestions} questoes'),
                          trailing: Text('${session.scorePercentage}%'),
                        );
                      }),
                      ListTile(
                        leading: const Icon(
                          Icons.local_fire_department_outlined,
                          color: Color(0xFFF59E0B),
                        ),
                        title: Text(
                          'Maior sequencia: ${userProvider.maxStreak} dias',
                        ),
                        subtitle: const Text('Gamificacao'),
                        trailing: const Text('Streak'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'LM';
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }
}
