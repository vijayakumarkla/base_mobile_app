// FULL FINAL FILE WITH SPLASH + ALL FEATURES

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

////////////////////////////////////////////////////////////
/// GLOBALS
////////////////////////////////////////////////////////////

String dateKey(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

final List<Color> chartColors = [
  Colors.cyan,
  Colors.orange,
  Colors.green,
  Colors.pink,
  Colors.purple,
];

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

  static Activity fromJson(Map<String, dynamic> j) =>
      Activity(j["name"], j["icon"], j["done"]);
}

class Member {
  String name;
  String avatar;
  List<Activity> activities;
  Map<String, int> dailyScore;
  Map<String, int> missed;

  Member(this.name, this.avatar, this.activities, this.dailyScore, this.missed);

  Map<String, dynamic> toJson() => {
        "name": name,
        "avatar": avatar,
        "activities": activities.map((e) => e.toJson()).toList(),
        "daily": dailyScore,
        "missed": missed,
      };

  static Member fromJson(Map<String, dynamic> j) => Member(
        j["name"],
        j["avatar"],
        (j["activities"] as List)
            .map((e) => Activity.fromJson(e))
            .toList(),
        Map<String, int>.from(j["daily"] ?? {}),
        Map<String, int>.from(j["missed"] ?? {}),
      );
}

////////////////////////////////////////////////////////////
/// SPLASH SCREEN
////////////////////////////////////////////////////////////

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double opacity = 0;

  @override
  void initState() {
    super.initState();

    // Fade animation
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => opacity = 1);
    });

    // Navigate
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FamilyPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Image(
                image: AssetImage("assets/logo.png"),
                width: 130,
              ),
              SizedBox(height: 20),
              Text(
                "Happy Family",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text("Build better habits together ❤️"),
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// APP
////////////////////////////////////////////////////////////

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SplashScreen(),
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

  HttpServer? server;
  RawDatagramSocket? sender;
  RawDatagramSocket? receiver;
  List<String> devices = [];
  Timer? autoSync;

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

  ////////////////////////////////////////////////////////////
  /// SYNC
  ////////////////////////////////////////////////////////////

  Future<void> startServer() async {
    final ip = await _getIp();

    server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    startBroadcast(ip);

    server!.listen((req) async {
      final data = jsonEncode(members.map((e) => e.toJson()).toList());
      req.response
        ..headers.contentType = ContentType.json
        ..write(data)
        ..close();
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Sharing: $ip")));
  }

  Future<String> _getIp() async {
    for (var i in await NetworkInterface.list()) {
      for (var addr in i.addresses) {
        if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }
    return "0.0.0.0";
  }

  void startBroadcast(String ip) async {
    sender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    sender!.broadcastEnabled = true;

    Timer.periodic(const Duration(seconds: 2), (_) {
      sender!.send(
          utf8.encode("HF::$ip"), InternetAddress("255.255.255.255"), 8888);
    });
  }

  void startListening() async {
    devices.clear();

    receiver =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8888);

    receiver!.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = receiver!.receive();
        if (dg != null) {
          final msg = utf8.decode(dg.data);
          if (msg.startsWith("HF::")) {
            final ip = msg.split("::")[1];
            if (!devices.contains(ip)) {
              setState(() => devices.add(ip));
            }
          }
        }
      }
    });

    showDevices();
  }

  void showDevices() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: devices.map((ip) {
          return ListTile(
            title: Text(ip),
            onTap: () {
              startAutoSync(ip);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void startAutoSync(String ip) {
    autoSync?.cancel();

    autoSync = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final client = HttpClient();
        final req = await client.getUrl(Uri.parse("http://$ip:8080"));
        final res = await req.close();
        final body = await res.transform(utf8.decoder).join();

        List decoded = jsonDecode(body);

        setState(() {
          members = decoded.map((e) => Member.fromJson(e)).toList();
        });

        save();
      } catch (_) {}
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Live Sync ON")));
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

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
                members.add(Member(c.text, "🙂", [], {}, {}));
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

  void open(Member m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(member: m, onSave: save),
      ),
    );
  }

  void openCompare() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ComparePage(members)));
  }

  @override
  Widget build(BuildContext context) {
    final today = dateKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Happy Family"),
        actions: [
          IconButton(icon: const Icon(Icons.wifi), onPressed: startServer),
          IconButton(icon: const Icon(Icons.search), onPressed: startListening),
          IconButton(icon: const Icon(Icons.bar_chart), onPressed: openCompare),
        ],
      ),
      floatingActionButton:
          FloatingActionButton(onPressed: addMember, child: const Icon(Icons.add)),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (_, i) {
          final m = members[i];

          return ListTile(
            leading: CircleAvatar(child: Text(m.avatar)),
            title: Text(m.name),
            subtitle: Text(
                "Score: ${m.dailyScore[today] ?? 0}% | Missed: ${m.missed[today] ?? 0}"),
            onTap: () => open(m),
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

////////////////////////////////////////////////////////////
/// COMPARISON PAGE
////////////////////////////////////////////////////////////

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
