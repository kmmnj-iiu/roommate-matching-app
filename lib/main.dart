import 'package:flutter/material.dart';
import 'clean_ui.dart';
import 'ai_matching_service.dart';
import 'match_list_screen.dart';

void main() {
  runApp(const RoommateApp());
}

class RoommateApp extends StatelessWidget {
  const RoommateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.blue,
      surface: Colors.white,
    );

    return MaterialApp(
      title: '룸핏',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: AppColors.text,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
        ),
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scroll = ScrollController();

  int _step = 0;
  bool _loading = false;
  bool _consent = false;
  String? _error;

  static const _dorms = [
    '101', '102', '103', '104', '105', '106',
    '201', '202', '203', '204', '205',
  ];
  static const _weekdays = ['월', '화', '수', '목', '금'];
  static const _stayLabels = {
    'mostly_dorm': '주로 기숙사',
    'mixed': '반반',
    'mostly_out': '주로 외출',
  };
  static const _habitLabels = {
    'drink': '음주 빈도',
    'clean': '청소 빈도',
    'meal': '방 안 식사',
    'call': '방 안 통화',
    'sensitive': '잠귀 예민도',
    'snore': '코골이 여부',
  };

  String _dorm = '101';
  bool _smoking = false;

  int _bed = 23 * 60 + 30;
  final List<int> _wake = List.filled(5, 7 * 60 + 30);
  final List<int?> _firstClass = List<int?>.filled(5, 9 * 60);
  String _stay = 'mostly_dorm';

  final Map<String, int> _habits = {
    'drink': 1,
    'meal': 0,
    'call': 0,
    'clean': 3,
    'sensitive': 1,
    'snore': 0,
  };

  final List<String> _priority = [
    'sensitive',
    'snore',
    'clean',
    'meal',
    'call',
    'drink',
  ];

  static const _stepNames = ['기본 조건', '생활패턴', '생활습관'];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _changeStep(int value) {
    if (_loading || value < 0 || value > 2) return;
    setState(() {
      _step = value;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _pickTime({
    required int current,
    required ValueChanged<int> onPicked,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (!mounted || selected == null) return;
    onPicked(selected.hour * 60 + selected.minute);
  }

  Future<void> _pickFirstClass(int day) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.65,
            child: Column(
              children: [
                Text(
                  '${_weekdays[day]}요일 첫 수업',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        title: const Text('수업 없음'),
                        trailing: _firstClass[day] == null
                            ? const Icon(Icons.check_circle, color: AppColors.blue)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, -1),
                      ),
                      for (int slot = 16; slot <= 36; slot++)
                        ListTile(
                          title: Text(formatMinutes(slot * 30)),
                          trailing: _firstClass[day] == slot * 30
                              ? const Icon(Icons.check_circle, color: AppColors.blue)
                              : null,
                          onTap: () => Navigator.pop(sheetContext, slot * 30),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() => _firstClass[day] = selected == -1 ? null : selected);
  }

  void _copyMonday() {
    setState(() {
      for (int i = 1; i < 5; i++) {
        _wake[i] = _wake[0];
        _firstClass[i] = _firstClass[0];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('월요일 기상·첫 수업 설정을 평일 전체에 적용했어요.')),
    );
  }

  void _movePriority(int index, int direction) {
    final target = index + direction;
    if (target < 0 || target >= _priority.length) return;
    setState(() {
      final item = _priority.removeAt(index);
      _priority.insert(target, item);
    });
  }

  Future<void> _submit() async {
    if (_loading || !_consent) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 평일 5일 기상 및 첫 수업 평균 계산
      final avgWake = (_wake.reduce((a, b) => a + b) / 5).round();
      final validClasses = _firstClass.whereType<int>().toList();
      final avgClass = validClasses.isEmpty
          ? '없음'
          : formatMinutes((validClasses.reduce((a, b) => a + b) / validClasses.length).round());

      String mapAllowance(int v) => v == 1 ? 'O' : (v == 0 ? 'X' : '상관없음');

      final response = await AiMatchingService.findTop5Matches(
        myName: '나',
        myDorm: '$_dorm동',
        mySmoking: _smoking ? 'O' : 'X',
        mySleep: formatMinutes(_bed),
        myWake: formatMinutes(avgWake),
        myFirstClass: avgClass,
        myStayInDorm: _stay == 'mostly_out' ? 'X' : 'O',
        myDrinking: _habits['drink']!,
        myCleaning: _habits['clean']!,
        myEatInRoom: mapAllowance(_habits['meal']!),
        myCallInRoom: mapAllowance(_habits['call']!),
        myLightSleeper: _habits['sensitive'] == 1 ? 'O' : 'X',
        mySnoring: _habits['snore'] == 1 ? 'O' : 'X',
        rank3Priorities: _priority.map((k) => _habitLabels[k]!).toList(),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            response: response,
            myDorm: '$_dorm동',
            mySmoking: _smoking,
            myBed: _bed,
            myWake: List<int>.from(_wake),
            myFirstClass: List<int?>.from(_firstClass),
            myStayLabel: _stayLabels[_stay]!,
            myHabits: Map<String, int>.from(_habits),
            myPriorityKeys: List<String>.from(_priority),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _heading(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, height: 1.3)),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: AppColors.muted, height: 1.5)),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: List.generate(3, (index) {
          final active = index <= _step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: active ? AppColors.blue : AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${index + 1}. ${_stepNames[index]}',
                    style: TextStyle(
                      color: active ? AppColors.blue : AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _basicStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('먼저, 꼭 맞아야 하는\n조건을 알려주세요', '같은 기숙사와 흡연 조건을 선택한 학생만 추천해 드려요.'),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('기숙사'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 260 ? 2 : 3;
                  final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _dorms.map((dorm) {
                      final selected = _dorm == dorm;
                      return SizedBox(
                        width: width,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selected ? AppColors.lightBlue : Colors.white,
                            foregroundColor: selected ? AppColors.blue : AppColors.text,
                            side: BorderSide(color: selected ? AppColors.blue : AppColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                          ),
                          onPressed: () => setState(() => _dorm = dorm),
                          child: Text('${selected ? '✓ ' : ''}$dorm동',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 28),
              _label('흡연 여부'),
              ChoiceTiles<bool>(
                value: _smoking,
                options: const {false: '비흡연', true: '흡연'},
                onChanged: (value) => setState(() => _smoking = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '기숙사 11개 동 × 10명(총 110명)의 가상 학생 데이터를 사용합니다.\n'
              '어떤 동·흡연 조건을 선택해도 추천 TOP 5를 확인할 수 있어요.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  Widget _patternStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('생활 리듬이 비슷하면\n함께 지내기 편해요', '평소 취침 시간과 평일 아침 일정을 알려주세요.'),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('평소 취침 시간'),
              Row(
                children: [
                  const Icon(Icons.bedtime_outlined, color: AppColors.blue, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(formatMinutes(_bed),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: () => _pickTime(
                      current: _bed,
                      onPicked: (value) => setState(() => _bed = value),
                    ),
                    child: const Text('변경'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('월요일부터 금요일까지'),
              const Text('시간을 누르면 변경할 수 있어요.', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              const Row(
                children: [
                  SizedBox(width: 32, child: Text('요일')),
                  Expanded(child: Center(child: Text('기상'))),
                  Expanded(child: Center(child: Text('첫 수업'))),
                ],
              ),
              const SizedBox(height: 8),
              for (int day = 0; day < 5; day++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(_weekdays[day], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(
                            current: _wake[day],
                            onPicked: (value) => setState(() => _wake[day] = value),
                          ),
                          child: Text(formatMinutes(_wake[day])),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickFirstClass(day),
                          child: Text(
                            _firstClass[day] == null ? '수업 없음' : formatMinutes(_firstClass[day]!),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: _copyMonday,
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('월요일 설정을 평일 전체에 적용'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('수업 외에는 주로 어디에 있나요?'),
              ChoiceTiles<String>(
                value: _stay,
                options: _stayLabels,
                onChanged: (value) => setState(() => _stay = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _frequency(String key) {
    final value = _habits[key]!;
    return Row(
      children: [
        Expanded(child: Text(_habitLabels[key]!, style: const TextStyle(fontWeight: FontWeight.w700))),
        IconButton(
          onPressed: value == 0 ? null : () => setState(() => _habits[key] = value - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 66,
          child: Text('주 $value회', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        IconButton(
          onPressed: value == 7 ? null : () => setState(() => _habits[key] = value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _habitChoice(String key, String title, Map<int, String> options) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(title),
          ChoiceTiles<int>(
            value: _habits[key]!,
            options: options,
            onChanged: (value) => setState(() => _habits[key] = value),
          ),
        ],
      ),
    );
  }

  Widget _habitsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('작은 생활습관까지\n나에게 맞게', '생활습관을 선택하고, 중요하게 생각하는 순서를 정해 주세요.'),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('일주일 기준 빈도'),
              _frequency('drink'),
              const Divider(height: 24),
              _frequency('clean'),
              _habitChoice('meal', '방 안에서 식사를 허용하나요?', const {1: '허용', 0: '비허용', 2: '상관없음'}),
              _habitChoice('call', '방 안에서 통화를 허용하나요?', const {1: '허용', 0: '비허용', 2: '상관없음'}),
              _habitChoice('sensitive', '나는 잠귀가 밝은 편인가요?', const {1: '예', 0: '아니요'}),
              _habitChoice('snore', '나는 코골이가 있나요?', const {1: '있음', 0: '없음'}),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('나에게 중요한 순서'),
              const Text('위에 있을수록 추천 점수에 크게 반영돼요.', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              for (int index = 0; index < _priority.length; index++)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.lightBlue,
                      child: Text('${index + 1}',
                          style: const TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_habitLabels[_priority[index]]!)),
                    IconButton(
                      onPressed: index == 0 ? null : () => _movePriority(index, -1),
                      icon: const Icon(Icons.keyboard_arrow_up),
                    ),
                    IconButton(
                      onPressed: index == _priority.length - 1 ? null : () => _movePriority(index, 1),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('추천 전 확인'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoPill(text: '$_dorm동'),
                  InfoPill(text: _smoking ? '흡연' : '비흡연'),
                  InfoPill(text: '취침 ${formatMinutes(_bed)}'),
                  InfoPill(text: _stayLabels[_stay]!),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consent,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Gemini AI 평가용 생활패턴 전송에 동의합니다.'),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    '선택한 생활패턴 및 우선순위 데이터가 Gemini AI API로 전송되어 '
                        '110명 후보군 중 최적의 룸메이트 TOP 5를 분석합니다.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted),
                  ),
                ),
                onChanged: (value) => setState(() => _consent = value ?? false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('추천을 완료하지 못했어요', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(_error!),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              if (_step > 0) ...[
                OutlinedButton(
                  onPressed: _loading ? null : () => _changeStep(_step - 1),
                  child: const Text('이전'),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : _step < 2
                      ? () => _changeStep(_step + 1)
                      : _consent
                      ? _submit
                      : null,
                  child: _loading
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 10),
                      Text('AI가 비교하고 있어요'),
                    ],
                  )
                      : Text(_step < 2 ? '다음' : '룸메이트 추천받기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading && _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_loading && _step > 0) _changeStep(_step - 1);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Row(
            children: [
              Icon(Icons.meeting_room_outlined, color: AppColors.blue),
              SizedBox(width: 8),
              Text('룸핏', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(child: Text('${_step + 1} / 3', style: const TextStyle(color: AppColors.muted))),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _progress(),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _loading,
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      if (_error != null) _errorPanel(),
                      if (_step == 0) _basicStep(),
                      if (_step == 1) _patternStep(),
                      if (_step == 2) _habitsStep(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomBar(),
      ),
    );
  }
}