import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/statistics_provider.dart';
import '../../providers/user_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final List<_PeriodOption> _periods = const [
    _PeriodOption(StatisticsPeriod.sevenDays, 'Ultimos 7 dias'),
    _PeriodOption(StatisticsPeriod.thirtyDays, 'Ultimos 30 dias'),
    _PeriodOption(StatisticsPeriod.allTime, 'Tudo'),
  ];

  final List<Color> _colors = const [
    Color(0xFF4DA3FF),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<UserProvider>().userId;
      context.read<StatisticsProvider>().loadStatistics(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, provider, _) {
        final stats = _subjectStats(provider.accuracyBySubject);
        final accuracyPercent = (provider.accuracyRate * 100).round();

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
                      DropdownButton<StatisticsPeriod>(
                        value: provider.selectedPeriod,
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
                          return DropdownMenuItem<StatisticsPeriod>(
                            value: period.value,
                            child: Text(period.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          provider.setPeriod(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Questoes',
                          value: provider.totalAnswered.toString(),
                          icon: Icons.edit_note,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Taxa acerto',
                          value: '$accuracyPercent%',
                          icon: Icons.track_changes,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Streak',
                          value: '${provider.currentStreak}d',
                          icon: Icons.local_fire_department,
                        ),
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
                            barGroups: _weeklyBars(provider.weeklyProgress),
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
                        children: stats.map((stat) {
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
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  backgroundColor: const Color(0xFF223044),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    stat.color,
                                  ),
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
      },
    );
  }

  List<BarChartGroupData> _weeklyBars(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return List.generate(7, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: 4,
              width: 22,
              color: const Color(0xFF26364A),
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        );
      });
    }

    return rows.take(7).toList().asMap().entries.map((entry) {
      final row = entry.value;
      final total = _asInt(row['total']);
      final correct = _asInt(row['correct']);
      final value = total == 0 ? 0.0 : (correct / total) * 100;

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: value.clamp(0, 100).toDouble(),
            width: 22,
            color: const Color(0xFF4DA3FF),
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();
  }

  List<_SubjectStat> _subjectStats(Map<String, double> source) {
    if (source.isEmpty) {
      return const [
        _SubjectStat(name: 'Matematica', value: 0, color: Color(0xFF4DA3FF)),
        _SubjectStat(name: 'Linguagens', value: 0, color: Color(0xFF22C55E)),
        _SubjectStat(
          name: 'Ciencias da Natureza',
          value: 0,
          color: Color(0xFFF59E0B),
        ),
        _SubjectStat(
          name: 'Ciencias Humanas',
          value: 0,
          color: Color(0xFFEF4444),
        ),
      ];
    }

    return source.entries.toList().asMap().entries.map((entry) {
      return _SubjectStat(
        name: entry.value.key,
        value: entry.value.value,
        color: _colors[entry.key % _colors.length],
      );
    }).toList();
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _PeriodOption {
  const _PeriodOption(this.value, this.label);

  final StatisticsPeriod value;
  final String label;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF4DA3FF)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF9BAABD)),
            ),
          ],
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
