import 'package:flutter/material.dart';
import 'ai_matching_service.dart';
import 'clean_ui.dart';
import 'match_list_screen.dart';
import 'user_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoommateApp());
}

class RoommateApp extends StatelessWidget {
  const RoommateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        surface: Colors.white,
      ),
    );

    return MaterialApp(
      title: '룸핏',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
          ),
        ),
      ),
      home: const EntryGate(),
    );
  }
}

/// 앱 시작 시 내 정보 등록 여부를 판별하여 화면을 분기하는 게이트
class EntryGate extends StatefulWidget {
  const EntryGate({super.key});

  @override
  State<EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<EntryGate> {
  RegisteredUserProfile? _savedUser;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final user = await UserStorageService.getMyProfile();
    if (!mounted) return;
    setState(() {
      _savedUser = user;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

    if (_savedUser == null) {
      return WelcomeScreen(
        onRegistered: (profile) {
          setState(() => _savedUser = profile);
        },
      );
    }

    return RecommendationDashboardScreen(
      user: _savedUser!,
      onProfileUpdated: (updated) {
        setState(() => _savedUser = updated);
      },
      onLoggedOut: () {
        setState(() => _savedUser = null);
      },
    );
  }
}

/// 1. 미등록 사용자를 위한 첫 화면
class WelcomeScreen extends StatelessWidget {
  final ValueChanged<RegisteredUserProfile> onRegistered;

  const WelcomeScreen({super.key, required this.onRegistered});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.meeting_room_outlined,
                    color: AppColors.blue,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '나와 딱 맞는\n기숙사 룸메이트, 룸핏',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  height: 1.3,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '나의 기숙사 조건과 생활패턴, 작은 생활습관까지\n한 번만 등록해 두면 AI가 가장 잘 맞는 룸메이트를 찾아드려요.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              WhitePanel(
                child: Column(
                  children: const [
                    _FeatureRow(
                      icon: Icons.verified_user_outlined,
                      title: '필수 조건 100% 일치 보장',
                      desc: '희망 기숙사 동과 흡연 여부가 같은 후보만 선별합니다.',
                    ),
                    Divider(height: 24, color: AppColors.border),
                    _FeatureRow(
                      icon: Icons.auto_awesome_outlined,
                      title: 'AI 기반 생활패턴·습관 정밀 분석',
                      desc: '수면 리듬과 우선순위 가중치를 반영해 TOP 5를 추천합니다.',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () async {
                  final result =
                  await Navigator.of(context).push<RegisteredUserProfile>(
                    MaterialPageRoute(
                      builder: (_) => const ProfileRegisterScreen(),
                    ),
                  );
                  if (result != null) {
                    onRegistered(result);
                  }
                },
                child: const Text('내 정보 등록하고 시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.blue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 2. 내 정보 전체 항목 등록(및 수정) 페이지
class ProfileRegisterScreen extends StatefulWidget {
  final RegisteredUserProfile? initialProfile;

  const ProfileRegisterScreen({super.key, this.initialProfile});

  @override
  State<ProfileRegisterScreen> createState() => _ProfileRegisterScreenState();
}

class _ProfileRegisterScreenState extends State<ProfileRegisterScreen> {
  final _scroll = ScrollController();
  final _name = TextEditingController();

  int _step = 0;
  String _dorm = '101동';
  String _smoking = 'X';
  int _sleep = 24 * 60 + 30;
  int _wake = 8 * 60 + 30;
  int _firstClass = 10 * 60;
  bool _noMorningClass = false;
  String _stay = '중간';
  int _drink = 1;
  int _clean = 2;
  String _eat = '상관없음';
  String _call = '상관없음';
  bool _lightSleep = false;
  bool _snore = false;
  bool _saving = false;
  String? _error;

  late List<String> _priorities;

  static const _dorms = ['101동', '102동', '103동', '104동', '105동'];
  static const _stays = ['거의 없음', '중간', '많음'];
  static const _roomOptions = ['O', 'X', '상관없음'];
  static const _steps = ['1. 기본 조건', '2. 생활패턴', '3. 생활습관'];

  @override
  void initState() {
    super.initState();
    final init = widget.initialProfile;
    if (init != null) {
      _name.text = init.name;
      _dorm = _dorms.contains(init.dorm) ? init.dorm : '101동';
      _smoking = init.smoking;
      _sleep = _parseMin(init.sleep);
      _wake = _parseMin(init.wake);
      if (init.firstClass == '오전수업 없음') {
        _noMorningClass = true;
      } else {
        _firstClass = _parseMin(init.firstClass);
      }
      _stay = init.stayInDorm;
      _drink = init.drinkingPerWeek;
      _clean = init.cleaningPerWeek;
      _eat = init.eatInRoom;
      _call = init.callInRoom;
      _lightSleep = init.lightSleeper == 'O';
      _snore = init.snoring == 'O';
      _priorities = List<String>.from(init.rank3Priorities);
    } else {
      _priorities = [
        '잠귀 예민도',
        '코골이 여부',
        '청소 빈도',
        '방 안 식사',
        '방 안 통화',
        '음주 빈도',
      ];
    }
  }

  int _parseMin(String hhmm) {
    final p = hhmm.split(':');
    int h = int.parse(p[0]);
    if (h < 12) h += 24;
    return h * 60 + int.parse(p[1]);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _name.dispose();
    super.dispose();
  }

  void _goStep(int next) {
    if (next == 1 && _name.text.trim().isEmpty) {
      setState(() => _error = '이름(또는 닉네임)을 입력해 주세요.');
      return;
    }
    setState(() {
      _error = null;
      _step = next;
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _movePriority(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _priorities.length) return;
    setState(() {
      final item = _priorities.removeAt(index);
      _priorities.insert(target, item);
    });
  }

  Future<void> _saveAndFinish() async {
    if (_name.text.trim().isEmpty) {
      setState(() {
        _step = 0;
        _error = '이름(또는 닉네임)을 입력해 주세요.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final profile = RegisteredUserProfile(
      name: _name.text.trim(),
      dorm: _dorm,
      smoking: _smoking,
      sleep: formatMinutes(_sleep),
      wake: formatMinutes(_wake),
      firstClass: _noMorningClass ? '오전수업 없음' : formatMinutes(_firstClass),
      stayInDorm: _stay,
      drinkingPerWeek: _drink,
      cleaningPerWeek: _clean,
      eatInRoom: _eat,
      callInRoom: _call,
      lightSleeper: _lightSleep ? 'O' : 'X',
      snoring: _snore ? 'O' : 'X',
      rank3Priorities: _priorities,
    );

    await UserStorageService.saveMyProfile(profile);

    if (!mounted) return;
    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialProfile != null;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          isEdit ? '내 정보 수정' : '내 정보 등록',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${_step + 1} / 3',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStepHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_step == 0) _buildStep1(),
                  if (_step == 1) _buildStep2(),
                  if (_step == 2) _buildStep3(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isEdit),
    );
  }

  Widget _buildStepHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final done = i <= _step;
          final current = i == _step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _steps.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => _goStep(i),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: done ? AppColors.blue : AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _steps[i],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                        color: current ? AppColors.blue : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '내 기본 프로필을\n등록해 주세요',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            height: 1.32,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '이름과 기숙사 동, 흡연 여부는 1순위 필수 조건으로 저장됩니다.',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('이름 또는 닉네임',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                decoration: const InputDecoration(hintText: '예: 김민준'),
              ),
              const SizedBox(height: 22),
              const Text('희망 기숙사 동',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ChoiceTiles<String>(
                value: _dorm,
                options: {for (final d in _dorms) d: d},
                onChanged: (v) => setState(() => _dorm = v),
              ),
              const SizedBox(height: 22),
              const Text('흡연 여부',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ChoiceTiles<String>(
                value: _smoking,
                options: const {'X': '비흡연 (X)', 'O': '흡연 (O)'},
                onChanged: (v) => setState(() => _smoking = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '하루 생활패턴을\n입력해 주세요',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            height: 1.32,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '취침·기상 시간과 기숙사 체류 시간은 매칭의 70% 비중으로 반영됩니다.',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sliderRow(
                label: '평균 취침 시간',
                valueText: formatMinutes(_sleep),
                value: _sleep.toDouble(),
                min: 21 * 60,
                max: 28 * 60,
                divisions: 28,
                onChanged: (v) => setState(() => _sleep = v.round()),
              ),
              const Divider(height: 28, color: AppColors.border),
              _sliderRow(
                label: '평균 기상 시간',
                valueText: formatMinutes(_wake),
                value: _wake.toDouble(),
                min: 5 * 60,
                max: 13 * 60,
                divisions: 32,
                onChanged: (v) => setState(() => _wake = v.round()),
              ),
              const Divider(height: 28, color: AppColors.border),
              _sliderRow(
                label: '첫 수업 시작 시간',
                valueText:
                _noMorningClass ? '오전수업 없음' : formatMinutes(_firstClass),
                value: _firstClass.toDouble(),
                min: 8 * 60,
                max: 15 * 60,
                divisions: 28,
                onChanged: _noMorningClass
                    ? null
                    : (v) => setState(() => _firstClass = v.round()),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _noMorningClass,
                activeColor: AppColors.blue,
                title: const Text('오전 수업 없음', style: TextStyle(fontSize: 14)),
                onChanged: (v) => setState(() => _noMorningClass = v ?? false),
              ),
              const Divider(height: 24, color: AppColors.border),
              const Text('수업 외 기숙사 체류 시간',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ChoiceTiles<String>(
                value: _stay,
                options: {for (final s in _stays) s: s},
                onChanged: (v) => setState(() => _stay = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '생활습관과 우선순위를\n설정해 주세요',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            height: 1.32,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '여기서 등록한 우선순위 그대로 AI 추천 점수가 산출됩니다.',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _counterRow(
                label: '일주일 음주 빈도',
                value: _drink,
                onChanged: (v) => setState(() => _drink = v),
              ),
              const Divider(height: 24, color: AppColors.border),
              _counterRow(
                label: '일주일 청소 빈도',
                value: _clean,
                onChanged: (v) => setState(() => _clean = v),
              ),
              const Divider(height: 24, color: AppColors.border),
              const Text('방 안 식사 허용',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ChoiceTiles<String>(
                value: _eat,
                options: {for (final o in _roomOptions) o: o},
                onChanged: (v) => setState(() => _eat = v),
              ),
              const SizedBox(height: 20),
              const Text('방 안 통화 허용',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ChoiceTiles<String>(
                value: _call,
                options: {for (final o in _roomOptions) o: o},
                onChanged: (v) => setState(() => _call = v),
              ),
              const Divider(height: 24, color: AppColors.border),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.blue,
                title: const Text('잠귀가 예민한 편이에요',
                    style:
                    TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                value: _lightSleep,
                onChanged: (v) => setState(() => _lightSleep = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.blue,
                title: const Text('코골이가 있는 편이에요',
                    style:
                    TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                value: _snore,
                onChanged: (v) => setState(() => _snore = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('생활습관 중요도 순위',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('화살표를 눌러 중요한 항목을 위로 올려주세요.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 12),
              ...List.generate(_priorities.length, (i) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.blue,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _priorities[i],
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                        onPressed: i == 0 ? null : () => _movePriority(i, -1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        onPressed: i == _priorities.length - 1
                            ? null
                            : () => _movePriority(i, 1),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(valueText,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.blue,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _counterRow({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text('주 $value회',
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < 7 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isEdit) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : () => _goStep(_step - 1),
                  child: const Text('이전'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: _saving
                    ? null
                    : () {
                  if (_step < 2) {
                    _goStep(_step + 1);
                  } else {
                    _saveAndFinish();
                  }
                },
                child: Text(
                  _step < 2
                      ? '다음'
                      : (_saving
                      ? '저장 중...'
                      : (isEdit ? '수정 완료' : '내 정보 등록 완료')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. 등록 완료 사용자가 바로 만나는 AI 룸메이트 추천 홈 화면
class RecommendationDashboardScreen extends StatefulWidget {
  final RegisteredUserProfile user;
  final ValueChanged<RegisteredUserProfile> onProfileUpdated;
  final VoidCallback onLoggedOut;

  const RecommendationDashboardScreen({
    super.key,
    required this.user,
    required this.onProfileUpdated,
    required this.onLoggedOut,
  });

  @override
  State<RecommendationDashboardScreen> createState() =>
      _RecommendationDashboardScreenState();
}

class _RecommendationDashboardScreenState
    extends State<RecommendationDashboardScreen> {
  bool _loading = false;
  String? _error;

  int _hhmmToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    int h = int.parse(parts[0]);
    if (h < 12) h += 24;
    return h * 60 + int.parse(parts[1]);
  }

  String _priorityNameToKey(String label) {
    switch (label) {
      case '음주 빈도':
        return 'drink';
      case '청소 빈도':
        return 'clean';
      case '방 안 식사':
        return 'meal';
      case '방 안 통화':
        return 'call';
      case '잠귀 예민도':
        return 'sensitive';
      case '코골이 여부':
        return 'snore';
      default:
        return 'sensitive';
    }
  }

  int _roomOptionToInt(String opt) {
    if (opt == 'X') return 0;
    if (opt == 'O') return 1;
    return 2; // 상관없음
  }

  Future<void> _runAiMatching() async {
    final u = widget.user;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await AiMatchingService.findTop5Matches(
        myName: u.name,
        myDorm: u.dorm,
        mySmoking: u.smoking,
        mySleep: u.sleep,
        myWake: u.wake,
        myFirstClass: u.firstClass,
        myStayInDorm: u.stayInDorm,
        myDrinking: u.drinkingPerWeek,
        myCleaning: u.cleaningPerWeek,
        myEatInRoom: u.eatInRoom,
        myCallInRoom: u.callInRoom,
        myLightSleeper: u.lightSleeper,
        mySnoring: u.snoring,
        rank3Priorities: u.rank3Priorities,
      );

      if (!mounted) return;

      if (response.recommendations.isEmpty) {
        setState(() {
          _error = '${u.dorm} · 흡연(${u.smoking}) 조건을 만족하는 다른 후보자가 없습니다.';
        });
        return;
      }

      final wakeMin = _hhmmToMinutes(u.wake);
      final int? firstClassMin =
      u.firstClass == '오전수업 없음' ? null : _hhmmToMinutes(u.firstClass);

      // match_list_screen.dart의 원래 ResultScreen으로 연결
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            response: response,
            myDorm: u.dorm,
            mySmoking: u.smoking == 'O',
            myBed: _hhmmToMinutes(u.sleep),
            myWake: List<int>.filled(5, wakeMin),
            myFirstClass: List<int?>.filled(5, firstClassMin),
            myStayLabel: u.stayInDorm,
            myHabits: {
              'drink': u.drinkingPerWeek,
              'clean': u.cleaningPerWeek,
              'meal': _roomOptionToInt(u.eatInRoom),
              'call': _roomOptionToInt(u.callInRoom),
              'sensitive': u.lightSleeper == 'O' ? 1 : 0,
              'snore': u.snoring == 'O' ? 1 : 0,
            },
            myPriorityKeys:
            u.rank3Priorities.map(_priorityNameToKey).toList(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.meeting_room_outlined, color: AppColors.blue),
            SizedBox(width: 8),
            Text(
              '룸핏',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _loading
                ? null
                : () async {
              await UserStorageService.clearMyProfile();
              widget.onLoggedOut();
            },
            child: const Text(
              '초기화',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '안녕하세요, ${u.name}님!\n등록된 조건으로 바로 추천받을 수 있어요',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            WhitePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '내 등록 프로필 요약',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loading
                            ? null
                            : () async {
                          final updated = await Navigator.of(context)
                              .push<RegisteredUserProfile>(
                            MaterialPageRoute(
                              builder: (_) => ProfileRegisterScreen(
                                initialProfile: u,
                              ),
                            ),
                          );
                          if (updated != null) {
                            widget.onProfileUpdated(updated);
                          }
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('내 정보 수정'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InfoPill(text: u.dorm),
                      InfoPill(text: '흡연 ${u.smoking}'),
                      InfoPill(text: '취침 ${u.sleep}'),
                      InfoPill(text: '기상 ${u.wake}'),
                      InfoPill(text: '첫수업 ${u.firstClass}'),
                      InfoPill(text: '체류 ${u.stayInDorm}'),
                      InfoPill(text: '음주 주 ${u.drinkingPerWeek}회'),
                      InfoPill(text: '청소 주 ${u.cleaningPerWeek}회'),
                      InfoPill(text: '식사 ${u.eatInRoom}'),
                      InfoPill(text: '통화 ${u.callInRoom}'),
                      InfoPill(text: '잠귀예민 ${u.lightSleeper}'),
                      InfoPill(text: '코골이 ${u.snoring}'),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  Text(
                    '1순위 중요 습관: ${u.rank3Priorities.first} (외 ${u.rank3Priorities.length - 1}개 항목)',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: _loading ? null : _runAiMatching,
            child: _loading
                ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Text('AI가 룸메이트를 분석하고 있어요...'),
              ],
            )
                : const Text('내 조건으로 바로 AI 룸메이트 추천받기'),
          ),
        ),
      ),
    );
  }
}ㅡ