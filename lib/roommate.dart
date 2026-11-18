class Roommate {
  final String name;
  final String sleep;
  final String wake;
  final int awakeCount;
  final String deepSleepLevel;

  // 생활 패턴 필드
  final bool isSmoker;
  final Map<String, String> firstClassByDay;
  final String snoring;
  final String eatInRoom;
  final String callInRoom;
  final String sleepSensitivity;
  final int drinkingPerWeek;
  final int cleaningPerWeek;

  int score;

  Roommate({
    required this.name,
    required this.sleep,
    required this.wake,
    required this.awakeCount,
    required this.deepSleepLevel,
    required this.isSmoker,
    required this.firstClassByDay,
    required this.snoring,
    required this.eatInRoom,
    required this.callInRoom,
    required this.sleepSensitivity,
    required this.drinkingPerWeek,
    required this.cleaningPerWeek,
    this.score = 0,
  });

  factory Roommate.fromJson(Map<String, dynamic> json) {
    return Roommate(
      name: json['name'],
      sleep: json['sleep'],
      wake: json['wake'],
      awakeCount: json['awake_count'],
      deepSleepLevel: json['deep_sleep_level'],
      isSmoker: json['is_smoker'] ?? false,
      firstClassByDay: Map<String, String>.from(json['first_class_by_day'] ?? {}),
      snoring: json['snoring'] ?? '없음',
      eatInRoom: json['eat_in_room'] ?? '안 먹음',
      callInRoom: json['call_in_room'] ?? '밖에서 함',
      sleepSensitivity: json['sleep_sensitivity'] ?? '보통',
      drinkingPerWeek: json['drinking_per_week'] ?? 0,
      cleaningPerWeek: json['cleaning_per_week'] ?? 3,
    );
  }

  String get classSummary =>
      '월 ${firstClassByDay['mon']} / 화 ${firstClassByDay['tue']} / 수 ${firstClassByDay['wed']} / 목 ${firstClassByDay['thu']} / 금 ${firstClassByDay['fri']}';
}