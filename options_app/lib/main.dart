import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

////////////////////////////////////////////////////////////
/// COLORS
////////////////////////////////////////////////////////////

final List<Color> chartColors = [
  Colors.cyan,
  Colors.orange,
  Colors.green,
  Colors.pink,
  Colors.purple,
];

////////////////////////////////////////////////////////////
/// DATE KEY
////////////////////////////////////////////////////////////

String dateKey(DateTime d) {
  return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
}

////////////////////////////////////////////////////////////
/// STAR SYSTEM
////////////////////////////////////////////////////////////

String getStars(int score) {
  if (score >= 80) return "⭐⭐⭐";
  if (score >= 60) return "⭐⭐";
  if (score >= 40) return "⭐";
  return "";
}

////////////////////////////////////////////////////////////
/// HABITS
////////////////////////////////////////////////////////////

Map<String, List<String>> habitCategories = {
  "Morning": [
    "⏰ Wake up early",
    "🪥 Brush teeth",
    "🚿 Bath",
    "🍳 Breakfast"
  ],
  "School": [
    "📚 Homework",
    "🎒 School bag",
  ],
  "Behaviour": [
    "🙂 Good attitude",
    "🙏 Respect",
  ],
};

////////////////////////////////////////////////////////////
/// MODELS
////////////////////////////////////////////////////////////

class Activity {
  String name;
  String icon;
  bool done;

  Activity(this.name, this.icon, this.done);

  Map<String, dynamic> toJson() =>
      {"name": name, "icon": icon, "done": done};

  static Activity fromJson(Map<String, dynamic> json) =>
      Activity(json["name"], json["icon"], json["done"]);
}

class Member {
  String name;
  String avatar;
  List<Activity> activities;
  Map<String, int> dailyScore;

  Member(this.name, this.avatar, this.activities, this.dailyScore);

  Map<String, dynamic> toJson() => {
        "name": name,
        "avatar": avatar,
        "activities": activities.map((e) => e.toJson()).toList(),
        "daily": dailyScore
      };

  static Member fromJson(Map<String, dynamic> json) => Member(
        json["name"],
        json["avatar"],
        (json["activities"] as List)
            .map((e) => Activity.fromJson(e))
            .toList(),
        Map<String, int>.from(json["daily"]),
      );
}

////////////////////////////////////////////////////////////
/// APP
////////////////////////////////////////////////////////////

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const FamilyPage(),
    );
  }
}

////////////////////////////////////////////////////////////
/// FAMILY PAGE
////////////////////////////////////////////////////////////

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  List<Member> members = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    p.setString("members", jsonEncode(members.map((e) => e.toJson()).toList()));
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final data = p.getString("members");

    if (data != null) {
      members =
          (jsonDecode(data) as List).map((e) => Member.fromJson(e)).toList();
    }
    setState(() {});
  }

  void addMember() {
    TextEditingController c = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Member"),
        content: TextField(controller: c),
        actions: [
          TextButton(
              onPressed: () {
                setState(() {
                  members.add(Member(c.text, "🙂", [], {}));
                });
                save();
                Navigator.pop(context);
              },
              child: const Text("Add"))
        ],
      ),
    );
  }

  void openMember(Member m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(member: m, onSave: save),
      ),
    );
  }

  void openComparison() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ComparisonPage(members)));
  }

  void openReport() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ReportPage(members)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Happy Family"),
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart), onPressed: openComparison),
          IconButton(icon: const Icon(Icons.insights), onPressed: openReport),
        ],
      ),
      floatingActionButton:
          FloatingActionButton(onPressed: addMember, child: const Icon(Icons.add)),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (_, i) {
          final m = members[i];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: CircleAvatar(
                  radius: 28,
                  child: Text(m.avatar, style: const TextStyle(fontSize: 24))),
              title: Text(m.name),
              subtitle: Text(getStars(
                  m.dailyScore[dateKey(DateTime.now())] ?? 0)),
              onTap: () => openMember(m),
            ),
          );
        },
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// MEMBER PAGE
////////////////////////////////////////////////////////////

class HomePage extends StatefulWidget {
  final Member member;
  final Function onSave;

  const HomePage({super.key, required this.member, required this.onSave});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String filter = "week";

  double score() {
    if (widget.member.activities.isEmpty) return 0;
    int done = widget.member.activities.where((e) => e.done).length;
    return (done / widget.member.activities.length) * 100;
  }

  void updateScore() {
    widget.member.dailyScore[dateKey(DateTime.now())] = score().round();
    widget.onSave();
  }

  List<FlSpot> chartData() {
    int days = filter == "week" ? 7 : 30;

    return List.generate(days, (i) {
      final d = DateTime.now().subtract(Duration(days: days - 1 - i));
      return FlSpot(
          i.toDouble(),
          (widget.member.dailyScore[dateKey(d)] ?? 0).toDouble());
    });
  }

  void addActivity() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Habit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: habitCategories.entries.map((cat) {
            return Wrap(
              children: cat.value.map((h) {
                return ActionChip(
                  label: Text(h),
                  onPressed: () {
                    setState(() {
                      widget.member.activities
                          .add(Activity(h.substring(2), h[0], false));
                    });
                    updateScore();
                    widget.onSave();
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = chartData();

    return Scaffold(
      appBar: AppBar(title: Text(widget.member.name)),
      floatingActionButton:
          FloatingActionButton(onPressed: addActivity, child: const Icon(Icons.add)),
      body: Column(
        children: [
          Text(
              "Today: ${getStars(widget.member.dailyScore[dateKey(DateTime.now())] ?? 0)}"),

          DropdownButton(
              value: filter,
              items: const [
                DropdownMenuItem(value: "week", child: Text("Weekly")),
                DropdownMenuItem(value: "month", child: Text("Monthly")),
              ],
              onChanged: (v) => setState(() => filter = v!)),

          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((e) {
                        return LineTooltipItem(
                            "${e.y.toInt()}%", const TextStyle());
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: Colors.cyan,
                    dotData: FlDotData(show: true),
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
                  leading: Text(a.icon, style: const TextStyle(fontSize: 28)),
                  title: Text(a.name),
                  trailing: Icon(
                    a.done ? Icons.check_circle : Icons.circle_outlined,
                    color: a.done ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    setState(() => a.done = !a.done);
                    updateScore();
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// COMPARISON PAGE (FINAL)
////////////////////////////////////////////////////////////

class ComparisonPage extends StatelessWidget {
  final List<Member> members;
  const ComparisonPage(this.members, {super.key});

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
                  Container(
                      width: 10,
                      height: 10,
                      color: chartColors[i]),
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
                lineBarsData: List.generate(members.length, (i) {
                  final m = members[i];

                  return LineChartBarData(
                    spots: List.generate(7, (j) {
                      final d = DateTime.now()
                          .subtract(Duration(days: 6 - j));
                      return FlSpot(
                          j.toDouble(),
                          (m.dailyScore[dateKey(d)] ?? 0).toDouble());
                    }),
                    color: chartColors[i],
                    isCurved: true,
                  );
                }),
              ),
            ),
          )
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// REPORT PAGE
////////////////////////////////////////////////////////////

class ReportPage extends StatelessWidget {
  final List<Member> members;
  const ReportPage(this.members, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Report")),
      body: ListView(
        children: members.map((m) {
          int total = 0;

          for (int i = 0; i < 7; i++) {
            final d = DateTime.now().subtract(Duration(days: i));
            total += m.dailyScore[dateKey(d)] ?? 0;
          }

          return ListTile(
            title: Text(m.name),
            subtitle: Text("Score: $total"),
          );
        }).toList(),
      ),
    );
  }
}
