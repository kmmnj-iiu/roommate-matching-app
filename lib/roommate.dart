class Roommate {
  final String name;

  // 1순위 (필수 일치 필터)
  final String dorm;     // 101동~106동, 201동~205동
  final String smoking;  // O, X

  // 2순위 (수면 및 기숙사 거주 리듬)
  final String sleep;      // 취침 시간
  final String wake;       // 기상 시간
  final String firstClass; // 첫 수업 시간 (시간표 기준)
  final String stayInDorm; // 수업 외 시간 기숙사 체류 여부 (O, X)

  // 3순위 (6가지 세부 생활 습관)
  final int drinkingPerWeek; // 주당 음주 빈도
  final int cleaningPerWeek; // 주당 청소 빈도
  final String eatInRoom;    // 방 안 식사 (O, X, 상관없음)
  final String callInRoom;   // 방 안 통화 (O, X, 상관없음)
  final String lightSleeper; // 잠귀 예민도 (O, X)
  final String snoring;      // 코골이 여부 (O, X)

  // AI 분석 결과
  int score;
  String aiReason;

  Roommate({
    required this.name,
    required this.dorm,
    required this.smoking,
    required this.sleep,
    required this.wake,
    required this.firstClass,
    required this.stayInDorm,
    required this.drinkingPerWeek,
    required this.cleaningPerWeek,
    required this.eatInRoom,
    required this.callInRoom,
    required this.lightSleeper,
    required this.snoring,
    this.score = 0,
    this.aiReason = '',
  });

  factory Roommate.fromJson(Map<String, dynamic> json) {
    return Roommate(
      name: json['name'],
      dorm: json['dorm'],
      smoking: json['smoking'],
      sleep: json['sleep'],
      wake: json['wake'],
      firstClass: json['first_class'],
      stayInDorm: json['stay_in_dorm'],
      drinkingPerWeek: json['drinking_per_week'],
      cleaningPerWeek: json['cleaning_per_week'],
      eatInRoom: json['eat_in_room'],
      callInRoom: json['call_in_room'],
      lightSleeper: json['light_sleeper'],
      snoring: json['snoring'],
    );
  }
}