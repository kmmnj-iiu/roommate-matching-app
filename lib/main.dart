import 'package:flutter/material.dart';
import 'match_list_screen.dart';

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

  // 1순위: 기숙사 동 & 흡연 여부
  final List<String> _dorms = [
    '101동', '102동', '103동', '104동', '105동', '106동',
    '201동', '202동', '203동', '204동', '205동',
  ];
  String _selectedDorm = '101동';
  String _smoking = 'X';

  // 2순위: 취침, 기상, 첫 수업 시간표, 수업 외 기숙사 체류 여부
  var _sleep = const TimeOfDay(hour: 23, minute: 30);
  var _wake = const TimeOfDay(hour: 7, minute: 30);
  String _firstClass = '09:00';
  String _stayInDorm = 'O';

  // 3순위: 6가지 세부 습관
  int _drinking = 1;
  int _cleaning = 3;
  String _eatInRoom = 'X';
  String _callInRoom = 'X';
  String _lightSleeper = 'O';
  String _snoring = 'X';

  // 3순위 내 6개 항목 우선순위
  final List<String> _rank3Priorities = [
    '잠귀 예민도',
    '코골이 여부',
    '청소 빈도',
    '방 안 식사',
    '방 안 통화',
    '음주 빈도',
  ];

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isSleep) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isSleep ? _sleep : _wake,
    );
    if (t != null) setState(() => isSleep ? _sleep = t : _wake = t);
  }

  Widget _segmentRow(
      String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
            ),
            segments: options
                .map((o) => ButtonSegment(
              value: o,
              label: Text(o, style: const TextStyle(fontSize: 13)),
            ))
                .toList(),
            selected: {value},
            onSelectionChanged: (set) => onChanged(set.first),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기숙사 룸메이트 AI 매칭')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '본인 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ================= 1순위 섹션 =================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1순위 기준 (필수 일치 필터)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('기숙사 동 선택', style: TextStyle(fontSize: 15)),
                        DropdownButton<String>(
                          value: _selectedDorm,
                          items: _dorms
                              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedDorm = v!),
                        ),
                      ],
                    ),
                    _segmentRow('흡연 여부', _smoking, ['O', 'X'],
                            (v) => setState(() => _smoking = v)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ================= 2순위 섹션 =================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2순위 기준 (수면 · 시간표 · 체류 리듬)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('평균 취침 시간'),
                      trailing: Text(_fmt(_sleep), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      onTap: () => _pickTime(true),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('평균 기상 시간'),
                      trailing: Text(_fmt(_wake), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      onTap: () => _pickTime(false),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('시간표상 첫 수업 시간', style: TextStyle(fontSize: 15)),
                        DropdownButton<String>(
                          value: _firstClass,
                          items: ['09:00', '10:00', '10:30', '11:00', '13:00', '14:00']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => setState(() => _firstClass = v!),
                        ),
                      ],
                    ),
                    _segmentRow('수업 외 시간 기숙사 체류', _stayInDorm, ['O', 'X'],
                            (v) => setState(() => _stayInDorm = v)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ================= 3순위 섹션 =================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('3순위 기준 (세부 생활 습관 6가지)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
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
                    _segmentRow('방 안 식사 여부', _eatInRoom, ['O', 'X', '상관없음'],
                            (v) => setState(() => _eatInRoom = v)),
                    _segmentRow('방 안 통화 여부', _callInRoom, ['O', 'X', '상관없음'],
                            (v) => setState(() => _callInRoom = v)),
                    _segmentRow('잠귀 예민도 (밝음)', _lightSleeper, ['O', 'X'],
                            (v) => setState(() => _lightSleeper = v)),
                    _segmentRow('코골이 여부', _snoring, ['O', 'X'],
                            (v) => setState(() => _snoring = v)),
                    const Divider(height: 24),
                    const Text('3순위 6개 항목 우선순위 지정 (드래그하여 순서 변경)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _rank3Priorities.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _rank3Priorities.removeAt(oldIndex);
                          _rank3Priorities.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = _rank3Priorities[index];
                        return ListTile(
                          key: ValueKey(item),
                          dense: true,
                          leading: CircleAvatar(
                            radius: 12,
                            child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text(item),
                          trailing: const Icon(Icons.drag_handle),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchListScreen(
                    myName: _nameCtrl.text.isEmpty ? '나' : _nameCtrl.text,
                    myDorm: _selectedDorm,
                    mySmoking: _smoking,
                    mySleep: _fmt(_sleep),
                    myWake: _fmt(_wake),
                    myFirstClass: _firstClass,
                    myStayInDorm: _stayInDorm,
                    myDrinking: _drinking,
                    myCleaning: _cleaning,
                    myEatInRoom: _eatInRoom,
                    myCallInRoom: _callInRoom,
                    myLightSleeper: _lightSleeper,
                    mySnoring: _snoring,
                    rank3Priorities: List.from(_rank3Priorities),
                  ),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('AI 추천 룸메이트 TOP 5 찾기', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}