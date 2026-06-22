import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final List<String> _periods = const [
    'Ultimos 7 dias',
    'Ultimos 30 dias',
    'Tudo',
  ];
  final List<_SubjectStat> _subjectStats = const [
    _SubjectStat(name: 'Matematica', value: 0.82, color: Color(0xFF4DA3FF)),
    _SubjectStat(name: 'Portugues', value: 0.74, color: Color(0xFF22C55E)),
    _SubjectStat(name: 'Biologia', value: 0.68, color: Color(0xFFF59E0B)),
    _SubjectStat(name: 'Historia', value: 0.59, color: Color(0xFFEF4444)),
  ];

  String _selectedPeriod = 'Ultimos 30 dias';

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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Estatisticas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    dropdownColor: const Color(0xFF0E131B),
                    iconEnabledColor: const Color(0xFF4DA3FF),
                    underline: Container(
                      height: 1,
                      color: const Color(0xFF4DA3FF),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    items: _periods.map((period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedPeriod = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                color: const Color(0xFF0E131B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF213047)),
                ),
                child: SizedBox(
                  height: 230,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        barGroups: _subjectStats.asMap().entries.map((entry) {
                          final stat = entry.value;
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: stat.value * 100,
                                width: 22,
                                color: stat.color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
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
                    children: _subjectStats.map((stat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    stat.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(stat.value * 100).round()}%',
                                  style: const TextStyle(
                                    color: Color(0xFFB6C2D1),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: stat.value,
                              minHeight: 8,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              backgroundColor: const Color(0xFF223044),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(stat.color),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectStat {
  const _SubjectStat({
    required this.name,
    required this.value,
    required this.color,
  });

  final String name;
  final double value;
  final Color color;
}
