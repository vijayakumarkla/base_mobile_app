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

  // 🔁 keep rest EXACT same (sync, UI, buttons)
}
