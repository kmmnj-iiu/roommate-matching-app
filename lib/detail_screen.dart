import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'roommate.dart';
import 'config.dart';

class DetailScreen extends StatefulWidget {
  final String myName, mySleep, myWake;
  final bool myIsSmoker;
  final Map<String, String> myFirstClass;
  final String mySnoring, myEatInRoom, myCallInRoom, mySensitivity;
  final int myDrinking, myCleaning;
  final List<String> priorities;
  final Roommate target;

  const DetailScreen({
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
    required this.target,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String _result = 'AI가 두 사람의 생활 패턴을 정밀 분석 중입니다...';

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  String get _myClassSummary =>
      '월 ${widget.myFirstClass['mon']} / 화 ${widget.myFirstClass['tue']} / 수 ${widget.myFirstClass['wed']} / 목 ${widget.myFirstClass['thu']} / 금 ${widget.myFirstClass['fri']}';

  Future<void> _analyze() async {
    try {
      final listRes = await http
          .get(Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'))
          .timeout(const Duration(seconds: 10));

      if (listRes.statusCode != 200) {
        setState(() => _result = '모델 조회 오류 (${listRes.statusCode})');
        return;
      }

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

      candidateModels.sort((a, b) {
        final aLite = a['name'].toString().contains('lite') ? 0 : 1;
        final bLite = b['name'].toString().contains('lite') ? 0 : 1;
        return aLite.compareTo(bLite);
      });

      final r = widget.target;
      final priorityText = widget.priorities
          .asMap()
          .entries
          .map((e) => '${e.key + 1}순위: ${e.value}')
          .join(', ');

      final prompt = '''
두 대학생의 기숙사 생활 패턴 데이터를 종합 비교해 룸메이트 궁합을 분석해줘.
특히 사용자가 설정한 중요도 우선순위($priorityText)를 중심으로 잘 맞는 점과 사전에 조율할 점을 4문장 이내로 요약해줘.

[나(${widget.myName})]
- 취침/기상: ${widget.mySleep} ~ ${widget.myWake} (잠귀: ${widget.mySensitivity}, 코골이: ${widget.mySnoring})
- 첫 수업 시간표: $_myClassSummary
- 흡연 여부: ${widget.myIsSmoker ? '흡연' : '비흡연'}
- 생활 습관: 방 안 식사(${widget.myEatInRoom}), 통화(${widget.myCallInRoom}), 음주 주 ${widget.myDrinking}회, 청소 주 ${widget.myCleaning}회

[상대방(${r.name})]
- 취침/기상: ${r.sleep} ~ ${r.wake} (잠귀: ${r.sleepSensitivity}, 코골이: ${r.snoring}, 수면 중 깸 ${r.awakeCount}회)
- 첫 수업 시간표: ${r.classSummary}
- 흡연 여부: ${r.isSmoker ? '흡연' : '비흡연'}
- 생활 습관: 방 안 식사(${r.eatInRoom}), 통화(${r.callInRoom}), 음주 주 ${r.drinkingPerWeek}회, 청소 주 ${r.cleaningPerWeek}회
- 종합 일치도 점수: ${r.score}점
''';

      for (var m in candidateModels) {
        final modelName = m['name'];
        if (!mounted) return;
        setState(() => _result = 'AI 분석 요청 중... ($modelName)');

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
            }),
          )
              .timeout(const Duration(seconds: 12));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final parts = data['candidates'][0]['content']['parts'] as List;
            final textPart = parts.firstWhere(
                  (p) => p['text'] != null,
              orElse: () => {'text': '응답 없음'},
            );
            if (!mounted) return;
            setState(() => _result = textPart['text'].toString());
            return;
          }
        } catch (_) {
          continue;
        }
      }

      if (!mounted) return;
      setState(() => _result = '현재 서버가 혼잡합니다. 잠시 후 다시 시도해 주세요.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _result = '네트워크 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.target;
    return Scaffold(
      appBar: AppBar(title: Text('${r.name}님 AI 궁합 분석')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('일치도 점수: ${r.score}점',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('내 우선순위: ${widget.priorities.take(3).join(' > ')} 순',
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('• 수면/기상: 나(${widget.mySleep}~${widget.myWake}) vs ${r.name}(${r.sleep}~${r.wake})'),
            Text('• 흡연/코골이: 나(${widget.myIsSmoker ? '흡연' : '비흡연'}, ${widget.mySnoring}) vs ${r.name}(${r.isSmoker ? '흡연' : '비흡연'}, ${r.snoring})'),
            Text('• 식사/통화: 나(${widget.myEatInRoom}, ${widget.myCallInRoom}) vs ${r.name}(${r.eatInRoom}, ${r.callInRoom})'),
            Text('• 음주/청소: 나(주 ${widget.myDrinking}회 / ${widget.myCleaning}회) vs ${r.name}(주 ${r.drinkingPerWeek}회 / ${r.cleaningPerWeek}회)'),
            const SizedBox(height: 6),
            Text('• ${r.name} 첫 수업: ${r.classSummary}', style: const TextStyle(color: Colors.black54)),
            const Divider(height: 32),
            const Text('Gemini AI 종합 분석 결과',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(_result, style: const TextStyle(fontSize: 15, height: 1.6)),
          ],
        ),
      ),
    );
  }
}