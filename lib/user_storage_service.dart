import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 익명 로그인 보장 후 현재 사용자 UID 반환
  static Future<String> _ensureSignedInUid() async {
    final current = _auth.currentUser;
    if (current != null) {
      return current.uid;
    }
    final cred = await _auth.signInAnonymously();
    return cred.user!.uid;
  }

  /// Firestore `users/{uid}`에서 내 등록 프로필 조회
  static Future<RegisteredUserProfile?> getMyProfile() async {
    final uid = await _ensureSignedInUid();
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    try {
      return RegisteredUserProfile.fromJson(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  /// Firestore `users/{uid}`에 내 프로필 저장 (클라우드 공유)
  static Future<void> saveMyProfile(RegisteredUserProfile profile) async {
    final uid = await _ensureSignedInUid();
    final data = profile.toJson()
      ..['uid'] = uid
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await _db.collection('users').doc(uid).set(data);
  }

  /// 초기화: Firestore에서 내 프로필 및 내가 보낸 신청 내역 삭제
  static Future<void> clearMyProfile() async {
    final uid = await _ensureSignedInUid();
    await _db.collection('users').doc(uid).delete();

    final myLikes =
    await _db.collection('likes').where('fromUid', isEqualTo: uid).get();
    for (final doc in myLikes.docs) {
      await doc.reference.delete();
    }
  }

  /// 내가 룸메이트 신청(좋아요)을 보낸 상대 이름 목록 조회
  static Future<Set<String>> getLikedRoommates() async {
    final uid = await _ensureSignedInUid();
    final snap =
    await _db.collection('likes').where('fromUid', isEqualTo: uid).get();

    return snap.docs
        .map((d) => d.data()['toName']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();
  }

  /// 특정 상대에게 룸메이트 신청(좋아요) 토글 후 최신 목록 반환
  static Future<Set<String>> toggleLikedRoommate(String targetName) async {
    final uid = await _ensureSignedInUid();
    final myProfile = await getMyProfile();
    final docId = '${uid}_$targetName';
    final docRef = _db.collection('likes').doc(docId);

    final snap = await docRef.get();
    if (snap.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'fromUid': uid,
        'fromName': myProfile?.name ?? '익명 사용자',
        'toName': targetName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return getLikedRoommates();
  }

  /// 기본 JSON(75명) + Firestore에 등록된 실제 사용자 전체 통합 로드
  static Future<List<Roommate>> loadAllCandidates() async {
    await _ensureSignedInUid();
    final raw = await rootBundle.loadString('assets/roommates.json');
    final baseList =
    (jsonDecode(raw) as List).map((e) => Roommate.fromJson(e)).toList();

    final snap = await _db.collection('users').get();
    final existingNames = baseList.map((e) => e.name).toSet();
    final merged = [...baseList];

    for (final doc in snap.docs) {
      final candidate = Roommate.fromJson(doc.data());
      if (candidate.name.isNotEmpty && !existingNames.contains(candidate.name)) {
        merged.add(candidate);
        existingNames.add(candidate.name);
      }
    }
    return merged;
  }
}