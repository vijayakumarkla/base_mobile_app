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

  ////////////////////////////////////////////////////////////
  /// SCORE
  ////////////////////////////////////////////////////////////

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

  ////////////////////////////////////////////////////////////
  /// CHART
  ////////////////////////////////////////////////////////////

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

  ////////////////////////////////////////////////////////////
  /// QUICK ADD (NEW)
  ////////////////////////////////////////////////////////////

  void quickAdd() {
    final Map<String, List<List<String>>> categories = {
      "Morning": [
        ["⏰", "Wake up"],
        ["🛏️", "Make bed"],
        ["🪥", "Brush teeth"],
        ["🚿", "Bathing"],
        ["👕", "Dress up"],
      ],
      "School": [
        ["🎒", "School preparation"],
        ["📚", "Study"],
        ["✏️", "Homework"],
      ],
      "Behavior": [
        ["🙂", "Good attitude"],
        ["🙏", "Respect"],
        ["🤝", "Help others"],
      ],
    };

    String selected = "Morning";

    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setModal) {
          final list = categories[selected]!;

          return Container(
            padding: const EdgeInsets.all(12),
            height: 500,
            child: Column(
              children: [
                /// CATEGORY TABS
                Row(
                  children: categories.keys.map((c) {
                    return GestureDetector(
                      onTap: () => setModal(() => selected = c),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected == c ? Colors.pink : Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(c),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 10),

                /// HABIT LIST
                Expanded(
                  child: ListView(
                    children: list.map((h) {
                      return ListTile(
                        leading: Text(h[0], style: const TextStyle(fontSize: 24)),
                        title: Text(h[1]),
                        onTap: () {
                          setState(() {
                            widget.member.activities
                                .add(Activity(h[1], h[0], false));
                          });
                          widget.onSave();
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// MANUAL ADD
  ////////////////////////////////////////////////////////////

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

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    final data = chart();

    return Scaffold(
      appBar: AppBar(title: Text(widget.member.name)),

      /// MANUAL ADD BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: addActivity,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [

          /// QUICK ADD BUTTON
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: quickAdd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
              child: const Text("⚡ Quick Add"),
            ),
          ),

          /// CHART
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

          /// ACTIVITY LIST
          Expanded(
            child: ListView.builder(
              itemCount: widget.member.activities.length,
              itemBuilder: (_, i) {
                final a = widget.member.activities[i];

                return ListTile(
                  leading: Text(a.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(a.name),
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
