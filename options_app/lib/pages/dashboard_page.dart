import 'package:flutter/material.dart';
import '../models/member.dart';
import '../utils/helpers.dart';
import 'home_page.dart';
import 'compare_page.dart';
import 'family_page.dart'; // ✅ NEW

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

  // ✅ NEW: Add Member Flow
  void openAddMember() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FamilyPage(),
      ),
    );

    // 🔥 Refresh after returning
    widget.onRefresh();
    setState(() {});
  }

  ////////////////////////////////////////////////////////////
  /// UI WIDGETS
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

          return FadeTransition(
            opacity: _anim,
            child: ListTile(
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
              subtitle: const Text("Tap to open"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => openMember(m),
            ),
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

      // ✅ FAB for adding members anytime
      floatingActionButton: FloatingActionButton(
        onPressed: openAddMember,
        child: const Icon(Icons.add),
      ),

      // ✅ EMPTY STATE + NORMAL UI
      body: widget.members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group,
                      size: 80, color: Colors.white30),
                  const SizedBox(height: 20),
                  const Text(
                    "No Members Yet",
                    style:
                        TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: openAddMember,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Member"),
                  ),
                ],
              ),
            )
          : Column(
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
