import 'package:flutter/material.dart';
import '../models/member.dart';
import '../utils/helpers.dart';
import 'home_page.dart';
import 'compare_page.dart';

class DashboardPage extends StatefulWidget {
  final List<Member> members;
  final Function onRefresh;

  const DashboardPage({
    super.key,
    required this.members,
    required this.onRefresh,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  ////////////////////////////////////////////////////////////
  /// ADD MEMBER (FIX)
  ////////////////////////////////////////////////////////////

  void addMember() {
    TextEditingController c = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Member"),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: "Enter name"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (c.text.trim().isEmpty) return;

              setState(() {
                widget.members.add(
                  Member(c.text, "🙂", [], {}, {}),
                );
              });

              widget.onRefresh(); // save + reload
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// CALCULATIONS
  ////////////////////////////////////////////////////////////

  int totalScore() {
    final today = dateKey(DateTime.now());
    if (widget.members.isEmpty) return 0;

    int total = 0;
    for (var m in widget.members) {
      total += m.dailyScore[today] ?? 0;
    }
    return (total / widget.members.length).round();
  }

  int totalMissed() {
    final today = dateKey(DateTime.now());
    int total = 0;

    for (var m in widget.members) {
      total += m.missed[today] ?? 0;
    }
    return total;
  }

  ////////////////////////////////////////////////////////////
  /// NAVIGATION
  ////////////////////////////////////////////////////////////

  void openMember(Member m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(member: m, onSave: widget.onRefresh),
      ),
    );
  }

  void openCompare() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComparePage(widget.members),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  Widget buildTopCard() {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: Column(
          children: [
            const Text("Family Score",
                style: TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 10),
            Text(
              "${totalScore()}%",
              style: const TextStyle(
                  fontSize: 42, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: totalScore() / 100,
              backgroundColor: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        statCard("Members", widget.members.length.toString(), Icons.people),
        statCard("Missed", totalMissed().toString(), Icons.warning),
        statCard("Today", "${totalScore()}%", Icons.trending_up),
      ],
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget buildMembers() {
    return Expanded(
      child: ListView.builder(
        itemCount: widget.members.length,
        itemBuilder: (_, i) {
          final m = widget.members[i];

          return ListTile(
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.black,
              child: ClipOval(
                child: m.avatar.startsWith("assets/")
                    ? Image.asset(
                        m.avatar,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      )
                    : Text(m.avatar),
              ),
            ),
            title: Text(m.name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => openMember(m),
          );
        },
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// BUILD
  ////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: openCompare,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              widget.onRefresh();
              setState(() {});
            },
          ),
        ],
      ),

      // ✅ FIX: ADD BUTTON HERE
      floatingActionButton: FloatingActionButton(
        onPressed: addMember,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          buildTopCard(),
          buildStatsRow(),
          const SizedBox(height: 10),
          buildMembers(),
        ],
      ),
    );
  }
}
