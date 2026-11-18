import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'roommate.dart';
import 'config.dart';

class AiMatchingService {
  static Future<List<Roommate>> findTop5Matches({
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

    // [1순위 필터링] 기숙사 동 & 흡연 여부가 정확히 일치하는 사람만 추출
    final filtered = allCandidates
        .where((r) => r.dorm == myDorm && r.smoking == mySmoking)
        .toList();

    if (filtered.isEmpty) return [];

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
아래 [기준 사용자]와 1순위 조건(기숙사 $myDorm, 흡연 $mySmoking)을 통과한 [후보자 목록]을 비교하여, 각 후보자의 최종 궁합 점수(40~100점)와 핵심 추천 사유를 산출하라.

[채점 배점 구조]
1. 2순위 핵심 생활 리듬 유사도 (비중 55%):
   - 취침 시간($mySleep), 기상 시간($myWake), 시간표상 첫 수업 시간($myFirstClass), 수업 외 기숙사 체류 여부($myStayInDorm)의 조화도를 정밀 판별할 것.
2. 3순위 세부 생활 습관 6가지 통합 유사도 (비중 45%):
   - 비교 항목: 주당 음주($myDrinking회), 주당 청소($myCleaning회), 방 안 식사($myEatInRoom), 방 안 통화($myCallInRoom), 잠귀 예민도($myLightSleeper), 코골이($mySnoring)
   - ★ 사용자가 지정한 3순위 내부 우선순위($priorityOrderText)에서 앞순위에 있는 항목일수록 가중치를 높게 반영하여 유사도를 계산할 것. (단, 식사/통화가 '상관없음'이면 어떤 상대와도 감점 없음)

[기준 사용자 ($myName)]
- 취침/기상: $mySleep ~ $myWake / 첫 수업: $myFirstClass / 수업 외 기숙사 체류: $myStayInDorm
- 주당 음주: $myDrinking회 / 주당 청소: $myCleaning회
- 방 안 식사: $myEatInRoom / 방 안 통화: $myCallInRoom
- 잠귀 예민도: $myLightSleeper / 코골이: $mySnoring

[후보자 목록]
${jsonEncode(candidatesJson)}

반드시 아래 JSON 배열 형식으로만 응답하라:
[{"name": "이름", "score": 92, "reason": "2순위 수면·첫수업 리듬 및 3순위 상위 항목 분석 요약(2문장)"}, ...]
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

          for (var r in filtered) {
            final info = resultMap[r.name];
            if (info != null) {
              r.score = (info['score'] as num).toInt().clamp(40, 100);
              r.aiReason = info['reason']?.toString() ?? '';
            }
          }

          filtered.sort((a, b) => b.score.compareTo(a.score));
          // 점수 높은 상위 5명만 반환
          return filtered.take(5).toList();
        }
      } catch (_) {
        continue;
      }
    }

    throw Exception('AI 서버 응답 지연. 잠시 후 다시 시도해 주세요.');
  }
}