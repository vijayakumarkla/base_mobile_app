import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/member.dart';
import '../utils/helpers.dart';
import 'home_page.dart';
import 'compare_page.dart';

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

  ////////////////////////////////////////////////////////////
  /// AVATAR LOGIC (NEW)
  ////////////////////////////////////////////////////////////

  String getAvatar(String name) {
    final n = name.toLowerCase();

    if (n.contains("mom")) return "assets/images/mom.png";
    if (n.contains("dad")) return "assets/images/dad.png";
    if (n.contains("grandpa")) return "assets/images/grandpa.png";
    if (n.contains("grandma")) return "assets/images/grandma.png";
    if (n.contains("girl1")) return "assets/images/SecondGirl.png";

    return "assets/images/First Girl.png";
  }

  ////////////////////////////////////////////////////////////
  /// STORAGE
  ////////////////////////////////////////////////////////////

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
                members.add(
                  Member(c.text, getAvatar(c.text), [], {}, {}),
                );
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
            leading: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.black,
                child: ClipOval(
                  child: m.avatar.startsWith("assets/")
                      ? Image.asset(
                          m.avatar,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            m.avatar,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                ),
              ),
            ),
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
