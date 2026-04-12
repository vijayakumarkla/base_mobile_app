import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

////////////////////////////////////////////////////////////
/// GLOBAL COLORS
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
/// HABIT CATEGORIES (NEW)
////////////////////////////////////////////////////////////

Map<String, List<String>> habitCategories = {
  "Morning": [
    "⏰ Wake up early",
    "🛏 Make bed",
    "🪥 Brush teeth",
    "🚿 Take bath",
    "👕 Get dressed",
    "🎒 Pack school bag",
    "🍳 Eat breakfast",
  ],
  "School": [
    "📚 Homework done",
    "✏️ Carry books",
    "🧃 Pack lunch",
    "🚌 Ready for school",
  ],
  "Behaviour": [
    "🙂 Good attitude",
    "🙏 Respect elders",
    "🤝 Help others",
    "😌 Control anger",
  ],
  "Health": [
    "🏃 Play outside",
    "🚴 Cycling",
    "🤸 Exercise",
  ],
  "Food": [
    "🥗 Eat healthy",
    "🍎 Eat fruits",
    "🚫 Avoid junk food",
  ],
  "Home": [
    "🧹 Clean room",
    "🧸 Arrange toys",
  ],
  "Night": [
    "📖 Study time",
    "🛏 Sleep on time",
  ],
};

////////////////////////////////////////////////////////////
/// MODELS
////////////////////////////////////////////////////////////

class Activity {
  String name;
  String icon;
  bool done;
  bool favorite;

  Activity(this.name,
      {this.icon = "🔥", this.done = false, this.favorite = false});

  Map<String, dynamic> toJson() =>
      {"name": name, "icon": icon, "done": done, "favorite": favorite};

  static Activity fromJson(Map<String, dynamic> json) => Activity(
        json["name"],
        icon: json["icon"] ?? "🔥",
        done: json["done"] ?? false,
        favorite: json["favorite"] ?? false,
      );
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
        json["avatar"] ?? "🙂",
        (json["activities"] as List)
            .map((e) => Activity.fromJson(e))
            .toList(),
        Map<String, int>.from(json["daily"] ?? {}),
      );
}

////////////////////////////////////////////////////////////
/// APP ROOT
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
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        "members", jsonEncode(members.map((e) => e.toJson()).toList()));
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("members");

    if (data != null) {
      List decoded = jsonDecode(data);
      members = decoded.map((e) => Member.fromJson(e)).toList();
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
            child: const Text("Add"),
          )
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
      context,
      MaterialPageRoute(builder: (_) => ComparisonPage(members)),
    );
  }

  void openReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportPage(members)),
    );
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
                radius: 30,
                child: Text(m.avatar, style: const TextStyle(fontSize: 30)),
              ),
              title: Text(m.name),
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

  double calculateScore() {
    if (widget.member.activities.isEmpty) return 0;

    int done = widget.member.activities.where((a) => a.done).length;

    return (done / widget.member.activities.length) * 100;
  }

  void updateScore() {
    widget.member.dailyScore[dateKey(DateTime.now())] =
        calculateScore().round();
    widget.onSave();
  }

  List<FlSpot> getData() {
    int days = filter == "week" ? 7 : filter == "month" ? 30 : 365;

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
        title: const Text("Select Habit"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: habitCategories.entries.map((cat) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.key,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Wrap(
                    children: cat.value.map((h) {
                      return ActionChip(
                        label: Text(h),
                        onPressed: () {
                          String icon = h.split(" ")[0];
                          String name = h.substring(2);

                          setState(() {
                            widget.member.activities
                                .add(Activity(name, icon: icon));
                          });

                          updateScore();
                          widget.onSave();
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = getData();

    return Scaffold(
      appBar: AppBar(title: Text(widget.member.name)),
      floatingActionButton:
          FloatingActionButton(onPressed: addActivity, child: const Icon(Icons.add)),
      body: Column(
        children: [
          DropdownButton<String>(
            value: filter,
            items: const [
              DropdownMenuItem(value: "week", child: Text("Weekly")),
              DropdownMenuItem(value: "month", child: Text("Monthly")),
              DropdownMenuItem(value: "year", child: Text("Yearly")),
            ],
            onChanged: (v) => setState(() => filter = v!),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
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

                return GestureDetector(
                  onTap: () {
                    setState(() => a.done = !a.done);
                    updateScore();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: a.done
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(a.icon, style: const TextStyle(fontSize: 40)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(a.name)),
                        Icon(
                          a.done
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: a.done ? Colors.green : Colors.grey,
                        )
                      ],
                    ),
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

////////////////////////////////////////////////////////////
/// COMPARISON PAGE
////////////////////////////////////////////////////////////

class ComparisonPage extends StatelessWidget {
  final List<Member> members;
  const ComparisonPage(this.members, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comparison")),
      body: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineBarsData: List.generate(members.length, (i) {
            final m = members[i];

            return LineChartBarData(
              spots: List.generate(7, (j) {
                final d =
                    DateTime.now().subtract(Duration(days: 6 - j));
                return FlSpot(
                    j.toDouble(),
                    (m.dailyScore[dateKey(d)] ?? 0).toDouble());
              }),
              color: chartColors[i % chartColors.length],
              isCurved: true,
            );
          }),
        ),
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

          String insight = total > 400
              ? "Excellent 🔥"
              : total > 200
                  ? "Good 👍"
                  : "Needs improvement ⚠️";

          return ListTile(
            title: Text(m.name),
            subtitle: Text("Score: $total → $insight"),
          );
        }).toList(),
      ),
    );
  }
}
