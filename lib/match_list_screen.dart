import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'roommate.dart';
import 'detail_screen.dart';
import 'config.dart';

class MatchListScreen extends StatefulWidget {
  final String myName, mySleep, myWake;
  final bool myIsSmoker;
  final Map<String, String> myFirstClass;
  final String mySnoring, myEatInRoom, myCallInRoom, mySensitivity;
  final int myDrinking, myCleaning;
  final List<String> priorities;

  const MatchListScreen({
    super.key,
    required this.myName,
    required this.mySleep,
    required this.myWake,
    required this.myIsSmoker,
    required this.myFirstClass,
    required this.mySnoring,
    required this.myEatInRoom,
    required this.myCallInRoom,
    required this.mySensitivity,
    required this.myDrinking,
    required this.myCleaning,
    required this.priorities,
  });

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  List<Roommate> _list = [];
  bool _isLoading = true;
  String _statusText = 'Gemini AI가 우선순위를 반영해 정밀 채점 중입니다...';

  @override
  void initState() {
    super.initState();
    _scoreWithAI();
  }

  Future<void> _scoreWithAI() async {
    final raw = await rootBundle.loadString('assets/roommates.json');
    final items = (jsonDecode(raw) as List).map((e) => Roommate.fromJson(e)).toList();

    final candidatesJson = items.map((r) => {
      'name': r.name,
      'sleep': r.sleep,
      'wake': r.wake,
      'first_class': r.firstClassByDay,
      'is_smoker': r.isSmoker,
      'snoring': r.snoring,
      'eat_in_room': r.eatInRoom,
      'call_in_room': r.callInRoom,
      'sleep_sensitivity': r.sleepSensitivity,
      'drinking_per_week': r.drinkingPerWeek,
      'cleaning_per_week': r.cleaningPerWeek,
    }).toList();

    final priorityText = widget.priorities
        .asMap()
        .entries
        .map((e) => '${e.key + 1}순위: ${e.value}')
        .join(' > ');

    final prompt = '''
너는 대학 기숙사 룸메이트 매칭 AI 평가관이다.
[기준 사용자]와 [후보자 30명]의 데이터를 비교하여 각 후보자의 궁합 점수를 30~100점 사이로 평가하라.

[평가 원칙 - 반드시 준수]
1. 사용자가 지정한 중요도 순서($priorityText)를 절대적 가중치 기준으로 적용한다.
2. 1순위 항목에서 치명적 불일치(예: 흡연 vs 비흡연, 잠귀 예민 vs 코골이 심함 등)가 발생하면, 다른 생활 패턴이 아무리 비슷하더라도 룸메이트 갈등 가능성이 높으므로 반드시 60~72점 이하로 낮게 평가한다.
3. 1순위와 2순위 항목이 모두 잘 맞고 나머지 생활 리듬과 시간표가 조화로운 후보에게 85~98점의 고득점을 부여한다.
4. 점수를 산출하기 전에 반드시 'reason' 필드에 1~2순위 항목의 일치 여부를 먼저 분석한 뒤, 그 논리에 맞는 'score'를 부여하라.

[출력 예시 (Few-Shot)]
- 1순위가 '흡연 여부'이고 기준 사용자가 흡연자일 때:
  {"name": "비흡연후보", "reason": "수면 시간은 비슷하나 1순위인 흡연 여부가 불일치하여 갈등 우려가 큼", "score": 65}
  {"name": "흡연후보", "reason": "1순위인 흡연 여부가 일치하며 취침 리듬도 무난함", "score": 89}

[기준 사용자 (${widget.myName})]
- 취침/기상: ${widget.mySleep} ~ ${widget.myWake}
- 요일별 첫 수업: ${jsonEncode(widget.myFirstClass)}
- 흡연 여부: ${widget.myIsSmoker ? '흡연' : '비흡연'}
- 코골이: ${widget.mySnoring} / 잠귀 예민도: ${widget.mySensitivity}
- 방 안 식사: ${widget.myEatInRoom} / 방 안 통화: ${widget.myCallInRoom}
- 주당 음주: ${widget.myDrinking}회 / 주당 청소: ${widget.myCleaning}회

[후보자 목록]
${jsonEncode(candidatesJson)}

반드시 아래 JSON 배열 형식으로만 응답하라:
[{"name": "이름", "reason": "1~2순위 중심 채점 근거", "score": 88}, ...]
''';

    try {
      final listRes = await http
          .get(Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'))
          .timeout(const Duration(seconds: 10));

      if (listRes.statusCode == 200) {
        final models = (jsonDecode(listRes.body)['models'] as List);
        final candidateModels = models.where((m) {
          final name = m['name'].toString().toLowerCase();
          final methods = (m['supportedGenerationMethods'] as List);
          return methods.contains('generateContent') &&
              name.contains('gemini') &&
              !name.contains('image') &&
              !name.contains('audio') &&
              !name.contains('tts') &&
              !name.contains('embedding');
        }).toList().reversed.toList();

        // ★ 정밀 추론을 위해 표준 flash 모델을 1순위로 배치 (lite는 후순위)
        candidateModels.sort((a, b) {
          final aIsStdFlash = (a['name'].toString().contains('flash') && !a['name'].toString().contains('lite')) ? 0 : 1;
          final bIsStdFlash = (b['name'].toString().contains('flash') && !b['name'].toString().contains('lite')) ? 0 : 1;
          return aIsStdFlash.compareTo(bIsStdFlash);
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
                  'temperature': 0.2, // ★ 일관되고 논리적인 채점을 위해 창의성 낮춤
                },
              }),
            )
                .timeout(const Duration(seconds: 25));

            if (res.statusCode == 200) {
              final data = jsonDecode(res.body);
              final parts = data['candidates'][0]['content']['parts'] as List;
              final textPart = parts.firstWhere((p) => p['text'] != null);
              final List<dynamic> scoreList = jsonDecode(textPart['text']);

              // ★ 코드 강제 보정 없이 AI가 산출한 순수 점수 그대로 반영
              final scoreMap = {
                for (var entry in scoreList)
                  entry['name'].toString(): (entry['score'] as num).toInt()
              };

              for (var r in items) {
                r.score = (scoreMap[r.name] ?? 50).clamp(30, 100);
              }

              items.sort((a, b) => b.score.compareTo(a.score));
              if (!mounted) return;
              setState(() {
                _list = items;
                _isLoading = false;
              });
              return;
            }
          } catch (_) {
            continue;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _statusText = 'AI 채점 서버가 혼잡합니다. 다시 시도해 주세요.';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.myName}님의 AI 추천 목록')),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusText, style: const TextStyle(fontSize: 15)),
          ],
        ),
      )
          : _list.isEmpty
          ? Center(child: Text(_statusText))
          : ListView.builder(
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final r = _list[i];
          return ListTile(
            leading: Text('${i + 1}위', style: const TextStyle(fontWeight: FontWeight.bold)),
            title: Text('${r.name} (${r.isSmoker ? '흡연' : '비흡연'})'),
            subtitle: Text('취침 ${r.sleep} / 기상 ${r.wake} / 청소 주${r.cleaningPerWeek}회'),
            trailing: Text('${r.score}점',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailScreen(
                  myName: widget.myName,
                  mySleep: widget.mySleep,
                  myWake: widget.myWake,
                  myIsSmoker: widget.myIsSmoker,
                  myFirstClass: widget.myFirstClass,
                  mySnoring: widget.mySnoring,
                  myEatInRoom: widget.myEatInRoom,
                  myCallInRoom: widget.myCallInRoom,
                  mySensitivity: widget.mySensitivity,
                  myDrinking: widget.myDrinking,
                  myCleaning: widget.myCleaning,
                  priorities: widget.priorities,
                  target: r,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}