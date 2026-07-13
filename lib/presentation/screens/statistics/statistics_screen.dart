import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/statistics_provider.dart';
import '../../providers/user_provider.dart';

// Tela: StatisticsScreen.
// Objetivo: mostrar o desempenho do aluno em numeros, graficos e barras.
// Ela consome StatisticsProvider, que calcula os dados com base nas tentativas
// salvas no SQLite.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Periodos disponiveis para filtrar as estatisticas.
  // Cada item junta o valor usado pelo provider e o texto mostrado na UI.
  final List<_PeriodOption> _periods = const [
    _PeriodOption(StatisticsPeriod.sevenDays, 'Ultimos 7 dias'),
    _PeriodOption(StatisticsPeriod.thirtyDays, 'Ultimos 30 dias'),
    _PeriodOption(StatisticsPeriod.allTime, 'Tudo'),
  ];

  // Paleta usada nas barras por disciplina.
  // Quando existem mais disciplinas que cores, o codigo reaproveita as cores.
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
    // Carrega estatisticas depois do primeiro frame para poder usar context.read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Busca o usuario atual e pede ao provider para carregar os dados dele.
      final userId = context.read<UserProvider>().userId;
      context.read<StatisticsProvider>().loadStatistics(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Consumer escuta mudancas do StatisticsProvider.
    // Periodo, progresso semanal, taxa de acerto e locais vem desse provider.
    return Consumer<StatisticsProvider>(
      builder: (context, provider, _) {
        // Converte o Map de acerto por disciplina em uma lista preparada para UI.
        final stats = _subjectStats(provider.accuracyBySubject);

        // Taxa geral convertida para percentual inteiro.
        final accuracyPercent = (provider.accuracyRate * 100).round();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            // Widget especial: SingleChildScrollView.
            // Permite que a tela de estatisticas role quando tiver muitos cards
            // ou quando o aparelho tiver pouca altura.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estatisticas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Widget especial: SingleChildScrollView horizontal.
                  // Aqui ele permite que os botoes de periodo caibam mesmo em
                  // telas estreitas, rolando para o lado se necessario.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    // Widget especial: SegmentedButton.
                    // E um controle de selecao entre opcoes mutuamente exclusivas.
                    // Neste caso escolhe o periodo das estatisticas.
                    child: SegmentedButton<StatisticsPeriod>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF12395C);
                          }
                          return const Color(0xFF0E131B);
                        }),
                        foregroundColor:
                            WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return const Color(0xFFB6C2D1);
                        }),
                        side: WidgetStateProperty.resolveWith<BorderSide>(
                          (states) => BorderSide(
                            color: states.contains(WidgetState.selected)
                                ? const Color(0xFF4DA3FF)
                                : const Color(0xFF26364A),
                          ),
                        ),
                      ),
                      segments: _periods.map((period) {
                        return ButtonSegment<StatisticsPeriod>(
                          // Widget especial: ButtonSegment.
                          // Cada segmento e uma opcao clicavel dentro do
                          // SegmentedButton.
                          value: period.value,
                          label: Text(period.label),
                        );
                      }).toList(),
                      selected: {provider.selectedPeriod},
                      onSelectionChanged: (selection) {
                        // O SegmentedButton sempre devolve um Set.
                        // Como so aceitamos uma selecao, usamos selection.first.
                        if (selection.isEmpty) return;
                        provider.setPeriod(selection.first);
                      },
                    ),
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
                        // Widget especial: BarChart, do pacote fl_chart.
                        // Desenha um grafico de barras com o desempenho semanal.
                        // O Flutter puro nao tem esse grafico pronto, por isso
                        // usamos o pacote externo fl_chart.
                        child: BarChart(
                          BarChartData(
                            // BarChartData configura alinhamento, escala, grade,
                            // bordas, titulos e os grupos de barras.
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
                                // Widget especial: LinearProgressIndicator.
                                // Aqui cada barra representa a taxa de acerto
                                // de uma disciplina especifica.
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
                  const SizedBox(height: 18),
                  _LocationPerformanceCard(
                    locations: provider.topStudyLocations,
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
    // Helper do grafico semanal.
    // Recebe linhas vindas do banco, cada uma com total e correct do dia.
    if (rows.isEmpty) {
      // Se ainda nao existe historico, mostra barras baixas/cinzas como placeholder.
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

    // Com dados reais, transforma cada dia em uma barra de 0 a 100.
    return rows.take(7).toList().asMap().entries.map((entry) {
      final row = entry.value;

      // total = quantas questoes respondeu naquele dia.
      final total = _asInt(row['total']);

      // correct = quantas acertou naquele dia.
      final correct = _asInt(row['correct']);

      // value e a porcentagem de acerto daquele dia.
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
    // Prepara os dados das barras por disciplina.
    if (source.isEmpty) {
      // Sem dados reais, mostra disciplinas padrao com 0%.
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

    // Com dados reais, converte cada entrada do Map em _SubjectStat.
    return source.entries.toList().asMap().entries.map((entry) {
      return _SubjectStat(
        name: entry.value.key,
        value: entry.value.value,
        color: _colors[entry.key % _colors.length],
      );
    }).toList();
  }

  int _asInt(Object? value) {
    // Conversao defensiva porque dados vindos de SQL podem ser int, num ou String.
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// Card expansivel que mostra desempenho por local de estudo.
// Ele usa dados gerados pelo GPS quando o aluno responde questoes.
class _LocationPerformanceCard extends StatelessWidget {
  const _LocationPerformanceCard({required this.locations});

  final List<Map<String, dynamic>> locations;

  @override
  Widget build(BuildContext context) {
    // Melhor local e o primeiro da lista, porque o provider ja ordena por desempenho.
    final best = locations.isEmpty ? null : locations.first;

    // Segundo local serve para comparar diferenca de acerto.
    final second = locations.length > 1 ? locations[1] : null;

    // Converte accuracy 0.0..1.0.
    final bestAccuracy = _asDouble(best?['accuracy']);
    final secondAccuracy = _asDouble(second?['accuracy']);

    // Diferenca entre melhor e segundo melhor local.
    final delta = bestAccuracy - secondAccuracy;

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        // Widget especial: ExpansionTile.
        // Card expansivel: fechado mostra um resumo do melhor local de estudo;
        // aberto mostra a lista detalhada de locais.
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          iconColor: const Color(0xFF4DA3FF),
          collapsedIconColor: const Color(0xFF6F7D90),
          leading: const Icon(
            Icons.location_on_outlined,
            color: Color(0xFF4DA3FF),
          ),
          title: const Text(
            'Local de estudo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            best == null
                ? 'Permita GPS para comparar desempenho.'
                : second == null
                    ? '${best['location']} lidera com ${(bestAccuracy * 100).round()}% de acertos.'
                    : '${best['location']} esta ${(delta * 100).round()} pontos acima de ${second['location']}.',
            style: const TextStyle(color: Color(0xFF9BAABD), height: 1.35),
          ),
          children: [
            if (best == null)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Responda questoes com o GPS permitido para criar locais como Casa, Biblioteca e Campus.',
                  style: TextStyle(color: Color(0xFF9BAABD), height: 1.35),
                ),
              )
            else
              ...locations.take(5).map((location) {
                // Para cada local, mostra porcentagem e acertos/total.
                final accuracy =
                    (_asDouble(location['accuracy']) * 100).round();
                final total = _asInt(location['total']);
                final correct = _asInt(location['correct']);
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          location['location']?.toString() ??
                              'Local registrado',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '$accuracy%  ($correct/$total)',
                        style: const TextStyle(
                          color: Color(0xFFB6C2D1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  double _asDouble(Object? value) {
    // Conversao defensiva para valores de SQL.
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _asInt(Object? value) {
    // Conversao defensiva para inteiros vindos do banco.
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

// Modelo simples para cada opcao de periodo do filtro.
class _PeriodOption {
  const _PeriodOption(this.value, this.label);

  final StatisticsPeriod value;
  final String label;
}

// Card pequeno usado no topo das estatisticas.
// Exibe numero grande, label e icone.
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
    // Card reaproveitavel para Questoes, Taxa de acerto e Streak.
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

// Modelo de UI para uma barra de acerto por disciplina.
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
