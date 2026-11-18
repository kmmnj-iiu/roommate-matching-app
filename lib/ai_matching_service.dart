import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'roommate.dart';
import 'config.dart';

class AiRecommendation {
  final Roommate profile;
  final double totalScore;
  final double patternScore; // 2순위 생활패턴 점수
  final double habitScore;   // 3순위 생활습관 점수
  final String reason;
  final List<String> warnings;

  AiRecommendation({
    required this.profile,
    required this.totalScore,
    required this.patternScore,
    required this.habitScore,
    required this.reason,
    required this.warnings,
  });
}

class AiMatchResponse {
  final int eligibleCount;
  final List<AiRecommendation> recommendations;

  AiMatchResponse({
    required this.eligibleCount,
    required this.recommendations,
  });
}

class AiMatchingService {
  static Future<AiMatchResponse> findTop5Matches({
    required String myName,
    required String myDorm,
    required String mySmoking,
    required String mySleep,
    required String myWake,
    required String myFirstClass,
    required String myStayInDorm,
    required int myDrinking,
    required int myCleaning,
    required String myEatInRoom,
    required String myCallInRoom,
    required String myLightSleeper,
    required String mySnoring,
    required List<String> rank3Priorities,
  }) async {
    final raw = await rootBundle.loadString('assets/roommates.json');
    final allCandidates =
    (jsonDecode(raw) as List).map((e) => Roommate.fromJson(e)).toList();

    // [1순위 필터링] 기숙사 동 & 흡연 여부 일치
    final filtered = allCandidates
        .where((r) => r.dorm == myDorm && r.smoking == mySmoking)
        .toList();

    if (filtered.isEmpty) {
      return AiMatchResponse(eligibleCount: 0, recommendations: []);
    }

    final candidatesJson = filtered
        .map((r) => {
      'name': r.name,
      'sleep': r.sleep,
      'wake': r.wake,
      'first_class': r.firstClass,
      'stay_in_dorm': r.stayInDorm,
      'drinking_per_week': r.drinkingPerWeek,
      'cleaning_per_week': r.cleaningPerWeek,
      'eat_in_room': r.eatInRoom,
      'call_in_room': r.callInRoom,
      'light_sleeper': r.lightSleeper,
      'snoring': r.snoring,
    })
        .toList();

    final priorityOrderText = rank3Priorities
        .asMap()
        .entries
        .map((e) => '${e.key + 1}위: ${e.value}')
        .join(' > ');

    final prompt = '''
너는 대학교 기숙사 룸메이트 AI 매칭 분석관이다.
아래 [기준 사용자]와 1순위 조건($myDorm, 흡연 $mySmoking)을 통과한 [후보자 목록]을 비교하여, 각 후보자의 점수를 산출하라.

[채점 기준]
1. pattern_score (2순위 생활패턴 점수, 40~100점): 취침($mySleep), 기상($myWake), 첫 수업($myFirstClass), 기숙사 체류($myStayInDorm)의 조화도.
2. habit_score (3순위 생활습관 점수, 40~100점): 음주($myDrinking회), 청소($myCleaning회), 식사($myEatInRoom), 통화($myCallInRoom), 잠귀예민($myLightSleeper), 코골이($mySnoring)를 사용자 우선순위($priorityOrderText) 가중치에 따라 평가. (식사/통화가 '상관없음'이면 감점 없음)
3. total_score: pattern_score 70% + habit_score 30% 비중으로 반영한 최종 점수(소수점 1자리).
4. warnings: 잠귀가 밝은데 상대 코골이가 있거나, 생활 패턴 차이가 큰 경우 주의사항 1줄 배열(없으면 빈 배열 []).

[기준 사용자 ($myName)]
- 취침/기상: $mySleep ~ $myWake / 첫 수업: $myFirstClass / 체류: $myStayInDorm
- 음주 주 $myDrinking회 / 청소 주 $myCleaning회 / 식사 $myEatInRoom / 통화 $myCallInRoom / 잠귀예민 $myLightSleeper / 코골이 $mySnoring

[후보자 목록]
${jsonEncode(candidatesJson)}

반드시 아래 JSON 배열 형식으로만 응답하라:
[{"name": "이름", "total_score": 91.5, "pattern_score": 93.0, "habit_score": 88.0, "reason": "핵심 궁합 평가(2문장)", "warnings": ["주의할 점(없으면 빈 배열)"]}, ...]
''';

    final listRes = await http
        .get(Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'))
        .timeout(const Duration(seconds: 10));

    if (listRes.statusCode != 200) {
      throw Exception('모델 목록 조회 실패 (${listRes.statusCode})');
    }

    final models = (jsonDecode(listRes.body)['models'] as List);
    final candidateModels = models
        .where((m) {
      final name = m['name'].toString().toLowerCase();
      final methods = (m['supportedGenerationMethods'] as List);
      return methods.contains('generateContent') &&
          name.contains('gemini') &&
          !name.contains('image') &&
          !name.contains('audio') &&
          !name.contains('tts') &&
          !name.contains('embedding');
    })
        .toList()
        .reversed
        .toList();

    candidateModels.sort((a, b) {
      final aStd = (a['name'].toString().contains('flash') &&
          !a['name'].toString().contains('lite'))
          ? 0
          : 1;
      final bStd = (b['name'].toString().contains('flash') &&
          !b['name'].toString().contains('lite'))
          ? 0
          : 1;
      return aStd.compareTo(bStd);
    });

    for (var m in candidateModels) {
      final modelName = m['name'];
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/$modelName:generateContent?key=$apiKey',
        );

        final res = await http
            .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'temperature': 0.2,
            },
          }),
        )
            .timeout(const Duration(seconds: 25));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final parts = data['candidates'][0]['content']['parts'] as List;
          final textPart = parts.firstWhere((p) => p['text'] != null);
          final List<dynamic> resultList = jsonDecode(textPart['text']);

          final resultMap = {
            for (var item in resultList) item['name'].toString(): item
          };

          final List<AiRecommendation> recs = [];
          for (var r in filtered) {
            final info = resultMap[r.name];
            if (info != null) {
              final total = (info['total_score'] as num).toDouble().clamp(40.0, 100.0);
              final pattern = (info['pattern_score'] as num).toDouble().clamp(40.0, 100.0);
              final habit = (info['habit_score'] as num).toDouble().clamp(40.0, 100.0);
              final reason = info['reason']?.toString() ?? '';
              final warns = (info['warnings'] as List?)
                  ?.map((w) => w.toString())
                  .where((w) => w.isNotEmpty)
                  .toList() ??
                  [];

              r.score = total.round();
              r.aiReason = reason;

              recs.add(AiRecommendation(
                profile: r,
                totalScore: total,
                patternScore: pattern,
                habitScore: habit,
                reason: reason,
                warnings: warns,
              ));
            }
          }

          recs.sort((a, b) => b.totalScore.compareTo(a.totalScore));
          return AiMatchResponse(
            eligibleCount: filtered.length,
            recommendations: recs.take(5).toList(),
          );
        }
      } catch (_) {
        continue;
      }
    }

    throw Exception('AI 서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.');
  }
}