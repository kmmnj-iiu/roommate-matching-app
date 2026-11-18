import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'roommate.dart';
import 'config.dart';
import 'user_storage_service.dart';

class AiRecommendation {
  final Roommate profile;
  final double totalScore;
  final double patternScore;
  final double habitScore;
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
  static List<String>? _availableModels;

  static Future<List<String>> _fetchModels(IOClient client) async {
    if (_availableModels != null && _availableModels!.isNotEmpty) {
      return _availableModels!;
    }

    final res = await client
        .get(Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('[${res.statusCode}] 모델 목록 조회 실패');
    }

    final models = (jsonDecode(res.body)['models'] as List);
    final valid = models
        .where((m) {
      final name = m['name'].toString().toLowerCase();
      final methods = (m['supportedGenerationMethods'] as List);
      return methods.contains('generateContent') &&
          (name.contains('gemini') || name.contains('gemma')) &&
          !name.contains('image') &&
          !name.contains('audio') &&
          !name.contains('tts') &&
          !name.contains('embedding') &&
          !name.contains('vision');
    })
        .map((m) => m['name'].toString().replaceFirst('models/', ''))
        .toList()
        .reversed
        .toList();

    valid.sort((a, b) {
      int rank(String s) {
        if (s.contains('flash')) return 0;
        if (s.contains('pro')) return 1;
        return 2;
      }

      return rank(a).compareTo(rank(b));
    });

    _availableModels = valid;
    return valid;
  }

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
    // ★ 기본 75명 + 로컬 등록 사용자 목록 통합 로드
    final allCandidates = await UserStorageService.loadAllCandidates();

    // ★ 1순위 조건 필터링 + 본인(myName) 제외
    final filtered = allCandidates
        .where((r) =>
    r.dorm == myDorm &&
        r.smoking == mySmoking &&
        r.name.trim() != myName.trim())
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
      'stay': r.stayInDorm,
      'drink': r.drinkingPerWeek,
      'clean': r.cleaningPerWeek,
      'eat': r.eatInRoom,
      'call': r.callInRoom,
      'light_sleeper': r.lightSleeper,
      'snoring': r.snoring,
    })
        .toList();

    final priorityOrderText = rank3Priorities
        .asMap()
        .entries
        .map((e) => '${e.key + 1}위:${e.value}')
        .join('>');

    final prompt = '''
기숙사 룸메이트 매칭 평가관으로서 기준 사용자와 후보자들을 비교해 점수와 추천 사유를 산출하라.
- pattern_score(40~100): 취침($mySleep), 기상($myWake), 첫수업($myFirstClass), 체류($myStayInDorm) 조화도
- habit_score(40~100): 음주($myDrinking회), 청소($myCleaning회), 식사($myEatInRoom), 통화($myCallInRoom), 잠귀예민($myLightSleeper), 코골이($mySnoring)를 우선순위($priorityOrderText) 가중치로 평가('상관없음'은 감점 없음)
- total_score: pattern_score 70% + habit_score 30% (소수점 1자리)
- warnings: 잠귀예민 O인데 상대 코골이 O이거나 생활 차이가 큰 경우 주의사항 1줄(없으면 [])

기준 사용자: 취침 $mySleep, 기상 $myWake, 첫수업 $myFirstClass, 체류 $myStayInDorm, 음주 $myDrinking, 청소 $myCleaning, 식사 $myEatInRoom, 통화 $myCallInRoom, 잠귀예민 $myLightSleeper, 코골이 $mySnoring
후보자: ${jsonEncode(candidatesJson)}

다른 설명 없이 순수 JSON 배열만 출력:
[{"name":"이름","total_score":91.5,"pattern_score":93.0,"habit_score":88.0,"reason":"핵심 평가 2문장","warnings":[]}]
''';

    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    final client = IOClient(httpClient);

    String lastError = '';

    try {
      final models = await _fetchModels(client);

      for (final model in models) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final genConfig = <String, dynamic>{
          'temperature': 0.2,
        };
        if (model.contains('gemini')) {
          genConfig['responseMimeType'] = 'application/json';
          genConfig['thinkingConfig'] = {'thinkingBudget': 0};
        }

        try {
          final res = await client
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
              'generationConfig': genConfig,
            }),
          )
              .timeout(const Duration(seconds: 25));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final parts = data['candidates'][0]['content']['parts'] as List;
            final textPart = parts.firstWhere((p) => p['text'] != null);
            String rawText = textPart['text'].toString().trim();

            if (rawText.startsWith('```')) {
              rawText = rawText
                  .replaceAll(RegExp(r'^```(json)?\s*'), '')
                  .replaceAll(RegExp(r'\s*```$'), '');
            }

            final List<dynamic> resultList = jsonDecode(rawText);

            final resultMap = {
              for (var item in resultList) item['name'].toString(): item
            };

            final List<AiRecommendation> recs = [];
            for (var r in filtered) {
              final info = resultMap[r.name];
              if (info != null) {
                final total =
                (info['total_score'] as num).toDouble().clamp(40.0, 100.0);
                final pattern = (info['pattern_score'] as num)
                    .toDouble()
                    .clamp(40.0, 100.0);
                final habit =
                (info['habit_score'] as num).toDouble().clamp(40.0, 100.0);
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

          try {
            final errJson = jsonDecode(res.body);
            lastError =
            '[$model / ${res.statusCode}] ${errJson['error']['message']}';
          } catch (_) {
            lastError = '[$model / ${res.statusCode}] ${res.body}';
          }
        } catch (e) {
          lastError = '[$model] $e';
          continue;
        }
      }
    } finally {
      client.close();
    }

    throw Exception(lastError);
  }
}