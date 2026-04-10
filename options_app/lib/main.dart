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
/// GLOBAL DATE KEY (FIXED - IMPORTANT)
////////////////////////////////////////////////////////////

String dateKey(DateTime d) {
  return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
}

////////////////////////////////////////////////////////////
/// MODELS
////////////////////////////////////////////////////////////

class Activity {
  String name;
  int mood;

  Activity(this.name, this.mood);

  Map<String, dynamic> toJson() => {"name": name, "mood": mood};

  static Activity fromJson(Map<String, dynamic> json) =>
      Activity(json["name"], json["mood"]);
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
/// APP LOCK
////////////////////////////////////////////////////////////

class LockService {
  static const key = "pin";

  static Future<String?> getPin() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(key);
  }

  static Future<void> setPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    p.setString(key, pin);
  }
}

////////////////////////////////////////////////////////////
/// APP ROOT
////////////////////////////////////////////////////////////

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool dark = true;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  void loadTheme() async {
    final p = await SharedPreferences.getInstance();
    setState(() => dark = p.getBool("theme") ?? true);
  }

  void toggleTheme() async {
    final p = await SharedPreferences.getInstance();
    setState(() => dark = !dark);
    p.setBool("theme", dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      home: FamilyPage(onToggle: toggleTheme),
    );
  }
}
////////////////////////////////////////////////////////////
/// LOCK SCREEN
////////////////////////////////////////////////////////////

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  TextEditingController pin = TextEditingController();
  String? savedPin;

  @override
  void initState() {
    super.initState();
    loadPin();
  }

  void loadPin() async {
    savedPin = await LockService.getPin();
    setState(() {});
  }

  void check() async {
    if (savedPin == null) {
      await LockService.setPin(pin.text);
      widget.onUnlock();
    } else if (savedPin == pin.text) {
      widget.onUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(savedPin == null ? "Set PIN" : "Enter PIN"),
              TextField(
                controller: pin,
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: check,
                child: const Text("Unlock"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// FAMILY PAGE (EDIT + DELETE ADDED SAFELY)
////////////////////////////////////////////////////////////

class FamilyPage extends StatefulWidget {
  final VoidCallback onToggle;
  const FamilyPage({super.key, required this.onToggle});

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
      "members",
      jsonEncode(members.map((e) => e.toJson()).toList()),
    );
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
    TextEditingController name = TextEditingController();
    String avatar = "🙂";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Member"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: avatar,
              items: [
  "🙂",
  "👨🏻", "👩🏻",
  "👨🏼", "👩🏼",
  "👨🏽", "👩🏽",
  "👨🏾", "👩🏾",
  "👨🏿", "👩🏿",
  "👦🏻", "👧🏻",
  "👦🏼", "👧🏼",
  "👶🏻",
  "🧒🏻",
  "🧓🏻"
]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => avatar = v!,
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;

              setState(() {
                members.add(Member(name.text, avatar, [], {}));
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

  void editMember(int index) {
    TextEditingController name =
        TextEditingController(text: members[index].name);

    String avatar = members[index].avatar;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Member"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: avatar,
              items: [
  "🙂",
  "👨🏻", "👩🏻",
  "👨🏼", "👩🏼",
  "👨🏽", "👩🏽",
  "👨🏾", "👩🏾",
  "👨🏿", "👩🏿",
  "👦🏻", "👧🏻",
  "👦🏼", "👧🏼",
  "👶🏻",
  "🧒🏻",
  "🧓🏻"
]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => avatar = v!),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                members[index].name = name.text;
                members[index].avatar = avatar;
              });
              save();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void deleteMember(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Member?"),
        content: Text("Are you sure you want to delete ${members[index].name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                members.removeAt(index);
              });
              save();
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void openMember(Member m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          member: members[members.indexOf(m)],
          onSave: save,
        ),
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

  void showOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit"),
            onTap: () {
              Navigator.pop(context);
              editMember(index);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete"),
            onTap: () {
              Navigator.pop(context);
              deleteMember(index);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Happy Family"),
        actions: [
          IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: widget.onToggle),
          IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: openComparison),
          IconButton(
              icon: const Icon(Icons.insights),
              onPressed: openReport),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addMember,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (_, i) {
          final m = members[i];

          return ListTile(
            leading: CircleAvatar(
  radius: 30,
  backgroundColor: Colors.blueGrey.shade700,
  child: Text(
    m.avatar,
    style: const TextStyle(fontSize: 30),
  ),
),
            title: Text(m.name),
            onTap: () => openMember(m),
            onLongPress: () => showOptions(i),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => updateScore());
  }

  void updateScore() {
    final today = dateKey(DateTime.now());

    int total = widget.member.activities.fold(0, (s, a) => s + a.mood);

    widget.member.dailyScore[today] = total;
    widget.onSave();
  }

  List<FlSpot> getData() {
    int days = filter == "week"
        ? 7
        : filter == "month"
            ? 30
            : 365;

    return List.generate(days, (i) {
      final d = DateTime.now().subtract(Duration(days: days - 1 - i));
      return FlSpot(
        i.toDouble(),
        (widget.member.dailyScore[dateKey(d)] ?? 0).toDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = getData();

    return Scaffold(
      appBar: AppBar(title: Text("${widget.member.avatar} ${widget.member.name}")),
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
          Expanded(
            child: LineChart(
              LineChartData(
                minY: -10,
                maxY: 10,
                gridData: FlGridData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: Colors.cyan,
                    barWidth: 4,
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
                  title: Text(a.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      moodBtn("😄", 2, a),
                      moodBtn("🙂", 1, a),
                      moodBtn("😐", 0, a),
                      moodBtn("🙁", -1, a),
                      moodBtn("😡", -2, a),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addActivity,
        child: const Icon(Icons.add),
      ),
    );
  }

  void addActivity() {
    TextEditingController c = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Activity"),
        content: TextField(controller: c),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.member.activities.add(Activity(c.text, 0));
              });
              widget.onSave();
              updateScore();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  Widget moodBtn(String emoji, int val, Activity a) {
    return IconButton(
      onPressed: () {
        setState(() => a.mood = val);
        updateScore();
      },
      icon: Text(emoji),
    );
  }
}

////////////////////////////////////////////////////////////
/// COMPARISON PAGE (FIXED)
////////////////////////////////////////////////////////////

class ComparisonPage extends StatelessWidget {
  final List<Member> members;
  const ComparisonPage(this.members, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Family Comparison")),
      body: Column(
        children: [
          Wrap(
            children: List.generate(members.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(backgroundColor: chartColors[i], radius: 5),
                  const SizedBox(width: 5),
                  Text(members[i].name),
                ],
              );
            }),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: -10,
                maxY: 10,
                lineBarsData: List.generate(members.length, (i) {
                  final m = members[i];

                  List<FlSpot> spots = [];

                  for (int j = 0; j < 7; j++) {
                    final d = DateTime.now().subtract(Duration(days: 6 - j));

                    double value =
                        (m.dailyScore[dateKey(d)] ?? 0).toDouble();

                    spots.add(FlSpot(j.toDouble(), value));
                  }

                  return LineChartBarData(
                    spots: spots,
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

////////////////////////////////////////////////////////////
/// REPORT PAGE (FIXED)
////////////////////////////////////////////////////////////

class ReportPage extends StatelessWidget {
  final List<Member> members;
  const ReportPage(this.members, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Insights")),
      body: ListView(
        children: members.map((m) {
          int total = 0;

          for (int i = 6; i >= 0; i--) {
            final d = DateTime.now().subtract(Duration(days: i));
            total += m.dailyScore[dateKey(d)] ?? 0;
          }

          String insight = total > 10
              ? "Great week 😊"
              : total > 0
                  ? "Balanced week 🙂"
                  : "Needs attention ⚠️";

          return ListTile(
            leading: Text(m.avatar, style: const TextStyle(fontSize: 24)),
            title: Text(m.name),
            subtitle: Text("Score: $total → $insight"),
          );
        }).toList(),
      ),
    );
  }
}