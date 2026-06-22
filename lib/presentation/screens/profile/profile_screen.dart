import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 44,
                backgroundColor: Color(0xFF4DA3FF),
                child: Text(
                  'LM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Lucas Mendes',
                style: TextStyle(
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
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
                          '4h / 6h',
                          style: TextStyle(
                            color: Color(0xFF4DA3FF),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: 0.67,
                      minHeight: 8,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      backgroundColor: Color(0xFF223044),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF4DA3FF)),
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
                      const Row(
                        children: [
                          Expanded(
                            child: Chip(
                              avatar: Icon(Icons.local_fire_department),
                              label: Text('45 dias'),
                              backgroundColor: Color(0xFF142C1F),
                              labelStyle: TextStyle(
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Chip(
                              avatar: Icon(Icons.center_focus_strong),
                              label: Text('Foco'),
                              backgroundColor: Color(0xFF122D47),
                              labelStyle: TextStyle(
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
                children: const [
                  ListTile(
                    leading: Icon(
                      Icons.quiz_outlined,
                      color: Color(0xFF4DA3FF),
                    ),
                    title: Text('18 questoes respondidas'),
                    subtitle: Text('Hoje'),
                    trailing: Text('+18 XP'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.assignment_turned_in_outlined,
                      color: Color(0xFF22C55E),
                    ),
                    title: Text('Simulado ENEM finalizado'),
                    subtitle: Text('15/06/2026'),
                    trailing: Text('82%'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.bookmark_border,
                      color: Color(0xFFF59E0B),
                    ),
                    title: Text('3 questoes salvas'),
                    subtitle: Text('09/06/2026'),
                    trailing: Text('Revisar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
