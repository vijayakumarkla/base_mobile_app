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
      body: Column(
        children: [
          Wrap(
            children: List.generate(members.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: chartColors[i]),
                  const SizedBox(width: 5),
                  Text(members[i].name),
                ],
              );
            }),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) =>
                          Text(dateLabel(v.toInt())),
                    ),
                  ),
                ),
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
                    color: chartColors[i],
                    isCurved: true,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
