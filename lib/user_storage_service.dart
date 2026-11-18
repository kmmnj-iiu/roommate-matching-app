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
    return RegisteredUserProfile(
      name: json['name']?.toString() ?? '',
      dorm: json['dorm']?.toString() ?? '101동',
      smoking: json['smoking']?.toString() ?? 'X',
      sleep: json['sleep']?.toString() ?? '00:00',
      wake: json['wake']?.toString() ?? '08:00',
      firstClass: json['first_class']?.toString() ?? '09:00',
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