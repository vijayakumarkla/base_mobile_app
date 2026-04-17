import 'activity.dart';

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
