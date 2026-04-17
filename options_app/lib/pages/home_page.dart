import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/member.dart';
import '../models/activity.dart';
import '../utils/helpers.dart';

class HomePage extends StatefulWidget {
  final Member member;
  final Function onSave;

  const HomePage({super.key, required this.member, required this.onSave});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  double calcScore() {
    if (widget.member.activities.isEmpty) return 0;
    int done = widget.member.activities.where((e) => e.done).length;
    return (done / widget.member.activities.length) * 100;
  }

  void update() {
    final today = dateKey(DateTime.now());

    widget.member.dailyScore[today] = calcScore().round();
    widget.member.missed[today] =
        widget.member.activities.where((e) => !e.done).length;

    widget.onSave();
  }

  List<FlSpot> chart() {
    return List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return FlSpot(
        i.toDouble(),
        (widget.member.dailyScore[dateKey(d)] ?? 0).toDouble(),
      );
    });
  }

  String dateLabel(int i) {
    final d = DateTime.now().subtract(Duration(days: 6 - i));
    return "${d.day}";
  }

  void addActivity() {
    TextEditingController c = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Habit"),
        content: TextField(controller: c),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.member.activities.add(Activity(c.text, "⭐", false));
              });
              widget.onSave();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = chart();

    return Scaffold(
      appBar: AppBar(title: Text(widget.member.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: addActivity,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
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
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: Colors.cyan,
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.member.activities.length,
              itemBuilder: (_, i) {
                final a = widget.member.activities[i];

                return ListTile(
                  title: Text("${a.icon} ${a.name}"),
                  trailing: Checkbox(
                    value: a.done,
                    onChanged: (v) {
                      setState(() => a.done = v!);
                      update();
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
