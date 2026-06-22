import 'package:flutter/material.dart';

class SimuladoConfigScreen extends StatefulWidget {
  const SimuladoConfigScreen({super.key});

  @override
  State<SimuladoConfigScreen> createState() => _SimuladoConfigScreenState();
}

class _SimuladoConfigScreenState extends State<SimuladoConfigScreen> {
  final List<String> _subjects = const [
    'Matematica',
    'Portugues',
    'Natureza',
    'Historia',
    'Quimica',
    'Fisica',
  ];
  final Set<String> _selectedSubjects = <String>{'Matematica', 'Portugues'};
  double _questionCount = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
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
                          final selected = _selectedSubjects.contains(subject);
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
                              setState(() {
                                if (selected) {
                                  _selectedSubjects.remove(subject);
                                } else {
                                  _selectedSubjects.add(subject);
                                }
                              });
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
                            _questionCount.round().toString(),
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
                        value: _questionCount,
                        activeColor: const Color(0xFF4DA3FF),
                        inactiveColor: const Color(0xFF223044),
                        label: '${_questionCount.round()} questoes',
                        onChanged: (value) {
                          setState(() {
                            _questionCount = value;
                          });
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4DA3FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Criar simulado'),
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
                children: const [
                  _SimuladoHistoryCard(
                    bank: 'ENEM',
                    date: '15/06/2026',
                    accuracy: '82%',
                  ),
                  _SimuladoHistoryCard(
                    bank: 'FUVEST',
                    date: '09/06/2026',
                    accuracy: '74%',
                  ),
                  _SimuladoHistoryCard(
                    bank: 'UERJ',
                    date: '01/06/2026',
                    accuracy: '68%',
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

class _SimuladoHistoryCard extends StatelessWidget {
  const _SimuladoHistoryCard({
    required this.bank,
    required this.date,
    required this.accuracy,
  });

  final String bank;
  final String date;
  final String accuracy;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(
          Icons.assignment_turned_in_outlined,
          color: Color(0xFF4DA3FF),
        ),
        title: Text(
          bank,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          date,
          style: const TextStyle(color: Color(0xFF9BAABD)),
        ),
        trailing: Text(
          accuracy,
          style: const TextStyle(
            color: Color(0xFF22C55E),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
