import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'roommate.dart';
import 'config.dart';

class DetailScreen extends StatefulWidget {
  final String myName, mySleep, myWake, myFirstClass, myStayInDorm;
  final int myDrinking, myCleaning;
  final String myEatInRoom, myCallInRoom, myLightSleeper, mySnoring;
  final List<String> rank3Priorities;
  final Roommate target;

  const DetailScreen({
    super.key,
    required this.myName,
    required this.mySleep,
    required this.myWake,
    required this.myFirstClass,
    required this.myStayInDorm,
    required this.myDrinking,
    required this.myCleaning,
    required this.myEatInRoom,
    required this.myCallInRoom,
    required this.myLightSleeper,
    required this.mySnoring,
    required this.rank3Priorities,
    required this.target,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _detailAnalysis;

  @override
  void initState() {
    super.initState();
    _detailAnalysis = widget.target.aiReason;
    _fetchDeepAnalysis();
  }

  Future<void> _fetchDeepAnalysis() async {
    final r = widget.target;
    final prompt = '''
두 학생(${widget.myName}, ${r.name})은 1순위(${r.dorm}, 흡연 ${r.smoking})가 일치하여 매칭되었다.
2순위(수면·기상·첫수업·기숙사 체류)와 3순위(우선순위: ${widget.rank3Priorities.join(' > ')}) 데이터를 바탕으로, 함께 생활할 때의 장점과 미리 정해두면 좋을 기숙사 규칙을 3~4문장으로 친절하게 조언해줘.

- ${widget.myName}: 취침 ${widget.mySleep}, 기상 ${widget.myWake}, 첫수업 ${widget.myFirstClass}, 체류 ${widget.myStayInDorm}, 음주 주${widget.myDrinking}회, 청소 주${widget.myCleaning}회, 식사 ${widget.myEatInRoom}, 통화 ${widget.myCallInRoom}, 잠귀예민 ${widget.myLightSleeper}, 코골이 ${widget.mySnoring}
- ${r.name}: 취침 ${r.sleep}, 기상 ${r.wake}, 첫수업 ${r.firstClass}, 체류 ${r.stayInDorm}, 음주 주${r.drinkingPerWeek}회, 청소 주${r.cleaningPerWeek}회, 식사 ${r.eatInRoom}, 통화 ${r.callInRoom}, 잠귀예민 ${r.lightSleeper}, 코골이 ${r.snoring}
''';

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
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
          ]
        }),
      )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _detailAnalysis =
              data['candidates'][0]['content']['parts'][0]['text'].toString();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.target;
    return Scaffold(
      appBar: AppBar(title: Text('${r.name}님 상세 궁합 리포트')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('종합 일치도: ${r.score}점',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            Text('1순위 일치: ${r.dorm} / 흡연 ${r.smoking}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const Divider(height: 28),
            const Text('[2순위] 수면 · 시간표 · 체류 비교', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('• 취침/기상: 나(${widget.mySleep}~${widget.myWake}) vs ${r.name}(${r.sleep}~${r.wake})'),
            Text('• 첫 수업 시간: 나(${widget.myFirstClass}) vs ${r.name}(${r.firstClass})'),
            Text('• 수업 외 기숙사 체류: 나(${widget.myStayInDorm}) vs ${r.name}(${r.stayInDorm})'),
            const Divider(height: 28),
            const Text('[3순위] 세부 생활 습관 비교', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('내 우선순위: ${widget.rank3Priorities.join(' > ')}',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 6),
            Text('• 음주/청소(주): 나(${widget.myDrinking}회 / ${widget.myCleaning}회) vs ${r.name}(${r.drinkingPerWeek}회 / ${r.cleaningPerWeek}회)'),
            Text('• 방 안 식사/통화: 나(${widget.myEatInRoom} / ${widget.myCallInRoom}) vs ${r.name}(${r.eatInRoom} / ${r.callInRoom})'),
            Text('• 잠귀예민/코골이: 나(${widget.myLightSleeper} / ${widget.mySnoring}) vs ${r.name}(${r.lightSleeper} / ${r.snoring})'),
            const Divider(height: 28),
            const Text('Gemini AI 룸메이트 맞춤 조언',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_detailAnalysis, style: const TextStyle(fontSize: 15, height: 1.6)),
          ],
        ),
      ),
    );
  }
}