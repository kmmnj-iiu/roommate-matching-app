import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'roommate.dart';

class RegisteredUserProfile {
  final String name;
  final String dorm;
  final String smoking;
  final String sleep;
  final String wake;
  final String firstClass;
  final List<String> dailyFirstClasses;
  final String stayInDorm;
  final int drinkingPerWeek;
  final int cleaningPerWeek;
  final String eatInRoom;
  final String callInRoom;
  final String lightSleeper;
  final String snoring;
  final List<String> rank3Priorities;

  RegisteredUserProfile({
    required this.name,
    required this.dorm,
    required this.smoking,
    required this.sleep,
    required this.wake,
    required this.firstClass,
    required this.dailyFirstClasses,
    required this.stayInDorm,
    required this.drinkingPerWeek,
    required this.cleaningPerWeek,
    required this.eatInRoom,
    required this.callInRoom,
    required this.lightSleeper,
    required this.snoring,
    required this.rank3Priorities,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'dorm': dorm,
    'smoking': smoking,
    'sleep': sleep,
    'wake': wake,
    'first_class': firstClass,
    'daily_first_classes': dailyFirstClasses,
    'stay_in_dorm': stayInDorm,
    'drinking_per_week': drinkingPerWeek,
    'cleaning_per_week': cleaningPerWeek,
    'eat_in_room': eatInRoom,
    'call_in_room': callInRoom,
    'light_sleeper': lightSleeper,
    'snoring': snoring,
    'rank3_priorities': rank3Priorities,
  };

  factory RegisteredUserProfile.fromJson(Map<String, dynamic> json) {
    final fallbackFirst = json['first_class']?.toString() ?? '09:00';
    final parsedDaily = (json['daily_first_classes'] as List?)
        ?.map((e) => e.toString())
        .toList();

    return RegisteredUserProfile(
      name: json['name']?.toString() ?? '',
      dorm: json['dorm']?.toString() ?? '101동',
      smoking: json['smoking']?.toString() ?? 'X',
      sleep: json['sleep']?.toString() ?? '00:30',
      wake: json['wake']?.toString() ?? '08:30',
      firstClass: fallbackFirst,
      dailyFirstClasses: (parsedDaily != null && parsedDaily.length == 5)
          ? parsedDaily
          : List<String>.filled(
        5,
        fallbackFirst == '오전수업 없음' ? '수업 없음' : fallbackFirst,
      ),
      stayInDorm: json['stay_in_dorm']?.toString() ?? '중간',
      drinkingPerWeek: (json['drinking_per_week'] as num?)?.toInt() ?? 1,
      cleaningPerWeek: (json['cleaning_per_week'] as num?)?.toInt() ?? 2,
      eatInRoom: json['eat_in_room']?.toString() ?? '상관없음',
      callInRoom: json['call_in_room']?.toString() ?? '상관없음',
      lightSleeper: json['light_sleeper']?.toString() ?? 'X',
      snoring: json['snoring']?.toString() ?? 'X',
      rank3Priorities: (json['rank3_priorities'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          const ['잠귀 예민도', '코골이 여부', '청소 빈도', '방 안 식사', '방 안 통화', '음주 빈도'],
    );
  }

  Roommate toRoommate() {
    return Roommate.fromJson(toJson());
  }
}

class UserStorageService {
  static const String _myProfileKey = 'roomfit_registered_user_v1';
  static const String _registeredPoolKey = 'roomfit_registered_pool_v1';
  static const String _likedRoommatesKey = 'roomfit_liked_roommates_v1';

  static Future<RegisteredUserProfile?> getMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_myProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return RegisteredUserProfile.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveMyProfile(RegisteredUserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_myProfileKey, jsonEncode(profile.toJson()));

    final poolRaw = prefs.getString(_registeredPoolKey);
    final List<dynamic> pool = [];
    if (poolRaw != null && poolRaw.isNotEmpty) {
      final decoded = jsonDecode(poolRaw) as List<dynamic>;
      pool.addAll(decoded);
    }
    pool.removeWhere((e) => (e as Map)['name'] == profile.name);
    pool.add(profile.toJson());
    await prefs.setString(_registeredPoolKey, jsonEncode(pool));
  }

  static Future<void> clearMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_myProfileKey);
    await prefs.remove(_likedRoommatesKey);
  }

  /// 내가 룸메이트 신청(좋아요)을 보낸 상대 이름 목록 조회
  static Future<Set<String>> getLikedRoommates() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_likedRoommatesKey) ?? const [];
    return list.toSet();
  }

  /// 특정 상대에게 룸메이트 신청(좋아요) 토글 후 최신 목록 반환
  static Future<Set<String>> toggleLikedRoommate(String targetName) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_likedRoommatesKey) ?? const []).toSet();
    if (current.contains(targetName)) {
      current.remove(targetName);
    } else {
      current.add(targetName);
    }
    await prefs.setStringList(_likedRoommatesKey, current.toList());
    return current;
  }

  static Future<List<Roommate>> loadAllCandidates() async {
    final raw = await rootBundle.loadString('assets/roommates.json');
    final baseList =
    (jsonDecode(raw) as List).map((e) => Roommate.fromJson(e)).toList();

    final prefs = await SharedPreferences.getInstance();
    final poolRaw = prefs.getString(_registeredPoolKey);
    if (poolRaw == null || poolRaw.isEmpty) {
      return baseList;
    }

    final savedList = (jsonDecode(poolRaw) as List)
        .map((e) => Roommate.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final existingNames = baseList.map((e) => e.name).toSet();
    final merged = [...baseList];
    for (final s in savedList) {
      if (!existingNames.contains(s.name)) {
        merged.add(s);
      }
    }
    return merged;
  }
}