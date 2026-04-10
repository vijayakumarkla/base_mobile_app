import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class Activity {
  String name;
  String type;

  Activity({required this.name, required this.type});

  Map<String, dynamic> toJson() => {"name": name, "type": type};

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(name: json['name'], type: json['type']);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Activity> activities = [];
  Map<String, int> todayData = {};
  String todayKey = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    String? act = prefs.getString("activities");
    if (act != null) {
      List list = json.decode(act);
      activities = list.map((e) => Activity.fromJson(e)).toList();
    }

    String? data = prefs.getString(todayKey);
    if (data != null) {
      todayData = Map<String, int>.from(json.decode(data));
    }

    setState(() {});
  }

  Future<void> saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("activities",
        json.encode(activities.map((e) => e.toJson()).toList()));
    prefs.setString(todayKey, json.encode(todayData));
  }

  void addActivity() {
    TextEditingController name = TextEditingController();
    String type = "good";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Activity"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name),
            DropdownButton<String>(
              value: type,
              items: ["good", "bad"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => type = v!,
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              activities.add(Activity(name: name.text, type: type));
              saveAll();
              setState(() {});
              Navigator.pop(context);
            },
            child: Text("Add"),
          )
        ],
      ),
    );
  }

  void increment(String name) {
    todayData[name] = (todayData[name] ?? 0) + 1;
    saveAll();
    setState(() {});
  }

  int score() {
    int s = 0;
    for (var a in activities) {
      int c = todayData[a.name] ?? 0;
      if (a.type == "good") s += c;
      else s -= c;
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tracker | Score: ${score()}")),
      floatingActionButton:
          FloatingActionButton(onPressed: addActivity, child: Icon(Icons.add)),
      body: ListView(
        children: activities.map((a) {
          return ListTile(
            title: Text(a.name),
            subtitle: Text("Count: ${todayData[a.name] ?? 0}"),
            trailing: IconButton(
              icon: Icon(Icons.add),
              onPressed: () => increment(a.name),
            ),
          );
        }).toList(),
      ),
    );
  }
}
