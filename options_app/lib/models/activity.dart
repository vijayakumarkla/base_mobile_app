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
