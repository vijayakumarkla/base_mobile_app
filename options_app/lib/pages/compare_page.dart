import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/member.dart';
import '../utils/helpers.dart';

class ComparePage extends StatelessWidget {
  final List<Member> members;
  const ComparePage(this.members, {super.key});

  String dateLabel(int i) {
    final d = DateTime.now().subtract(Duration(days: 6 - i));
    return "${d.day}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comparison")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12), // ✅ global padding
          child: Column(
            children: [
              ////////////////////////////////////////////////////////////
              /// LEGEND
              ////////////////////////////////////////////////////////////

              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: List.generate(members.length, (i) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        color: chartColors[i % chartColors.length],
                      ),
                      const SizedBox(width: 5),
                      Text(members[i].name),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 16),

              ////////////////////////////////////////////////////////////
              /// CHART
              ////////////////////////////////////////////////////////////

              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,

                    ////////////////////////////////////////////////////////////
                    /// PADDING INSIDE CHART
                    ////////////////////////////////////////////////////////////

                    gridData: FlGridData(show: true),

                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.white24),
                    ),

                    ////////////////////////////////////////////////////////////
                    /// AXIS TITLES
                    ////////////////////////////////////////////////////////////

                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40, // ✅ space for values
                          getTitlesWidget: (value, meta) {
                            return Text(
                              "${value.toInt()}",
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),

                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32, // ✅ prevents cut
                          getTitlesWidget: (v, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                dateLabel(v.toInt()),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),

                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),

                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),

                    ////////////////////////////////////////////////////////////
                    /// LINES
                    ////////////////////////////////////////////////////////////

                    lineBarsData: List.generate(members.length, (i) {
                      final m = members[i];

                      return LineChartBarData(
                        spots: List.generate(7, (j) {
                          final d = DateTime.now()
                              .subtract(Duration(days: 6 - j));

                          return FlSpot(
                            j.toDouble(),
                            (m.dailyScore[dateKey(d)] ?? 0).toDouble(),
                          );
                        }),
                        color: chartColors[i % chartColors.length],
                        isCurved: true,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      );
                    }),
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
