import 'package:flutter/material.dart';
import 'match_list_screen.dart';
// 메인
void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: InputScreen(),
));

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _nameCtrl = TextEditingController();

  var _sleep = const TimeOfDay(hour: 23, minute: 30);
  var _wake = const TimeOfDay(hour: 7, minute: 30);

  bool _isSmoker = false;
  final Map<String, String> _firstClass = {
    'mon': '09:00',
    'tue': '10:30',
    'wed': '09:00',
    'thu': '10:30',
    'fri': '없음',
  };
  String _snoring = '없음';
  String _eatInRoom = '간식만';
  String _callInRoom = '짧게만 함';
  String _sensitivity = '보통';
  int _drinking = 1;
  int _cleaning = 3;

  // ★ 사용자가 직접 순서를 바꿀 수 있는 6가지 중요도 순위 리스트
  final List<String> _priorities = [
    '흡연 여부',
    '수면/기상 시간',
    '코골이/잠귀',
    '청소 빈도',
    '식사/통화 습관',
    '음주 빈도',
  ];

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool isSleep) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isSleep ? _sleep : _wake,
    );
    if (t != null) setState(() => isSleep ? _sleep = t : _wake = t);
  }

  Widget _dropdownRow(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        DropdownButton<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('룸메이트 매칭 정보 입력')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '내 이름'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('평균 취침 시각'),
              trailing: Text(_fmt(_sleep), style: const TextStyle(fontSize: 16)),
              onTap: () => _pick(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('평균 기상 시각'),
              trailing: Text(_fmt(_wake), style: const TextStyle(fontSize: 16)),
              onTap: () => _pick(false),
            ),
            const Divider(height: 24),
            const Text('요일별 첫 수업 시간', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: {'mon': '월', 'tue': '화', 'wed': '수', 'thu': '목', 'fri': '금'}.entries.map((entry) {
                return DropdownButton<String>(
                  value: _firstClass[entry.key],
                  items: ['09:00', '10:00', '10:30', '11:00', '13:00', '없음']
                      .map((t) => DropdownMenuItem(value: t, child: Text('${entry.value}: $t')))
                      .toList(),
                  onChanged: (v) => setState(() => _firstClass[entry.key!] = v!),
                );
              }).toList(),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('흡연 여부'),
              value: _isSmoker,
              onChanged: (v) => setState(() => _isSmoker = v),
            ),
            _dropdownRow('코골이 여부', _snoring, ['없음', '가끔', '심함'], (v) => setState(() => _snoring = v!)),
            _dropdownRow('방 안 식사', _eatInRoom, ['안 먹음', '간식만', '자주 먹음'], (v) => setState(() => _eatInRoom = v!)),
            _dropdownRow('방 안 통화', _callInRoom, ['밖에서 함', '짧게만 함', '방에서 함'], (v) => setState(() => _callInRoom = v!)),
            _dropdownRow('잠귀 예민도', _sensitivity, ['둔감', '보통', '예민'], (v) => setState(() => _sensitivity = v!)),
            const SizedBox(height: 8),
            Text('주당 음주 빈도: $_drinking회'),
            Slider(
              value: _drinking.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: (v) => setState(() => _drinking = v.round()),
            ),
            Text('주당 청소 빈도: $_cleaning회'),
            Slider(
              value: _cleaning.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (v) => setState(() => _cleaning = v.round()),
            ),
            const Divider(height: 28),

            // ★ 중요도 순위 드래그 설정 UI
            const Text('중요도 우선순위 설정 (길게 눌러 드래그)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('위쪽에 배치한 항목일수록 점수 비중이 높아집니다.',
                style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _priorities.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _priorities.removeAt(oldIndex);
                    _priorities.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final item = _priorities[index];
                  return ListTile(
                    key: ValueKey(item),
                    dense: true,
                    leading: CircleAvatar(
                      radius: 13,
                      child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(item),
                    trailing: const Icon(Icons.drag_handle),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchListScreen(
                    myName: _nameCtrl.text.isEmpty ? '나' : _nameCtrl.text,
                    mySleep: _fmt(_sleep),
                    myWake: _fmt(_wake),
                    myIsSmoker: _isSmoker,
                    myFirstClass: _firstClass,
                    mySnoring: _snoring,
                    myEatInRoom: _eatInRoom,
                    myCallInRoom: _callInRoom,
                    mySensitivity: _sensitivity,
                    myDrinking: _drinking,
                    myCleaning: _cleaning,
                    priorities: List.from(_priorities), // ★ 설정한 순위 전달
                  ),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('룸메이트 찾기', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}