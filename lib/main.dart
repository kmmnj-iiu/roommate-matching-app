import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'ai_matching_service.dart';
import 'clean_ui.dart';
import 'config/firebase_config.dart';
import 'match_list_screen.dart';
import 'user_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: firebaseOptions,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
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
  String? _initError;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    setState(() {
      _checking = true;
      _initError = null;
    });

    try {
      final user = await UserStorageService.getMyProfile()
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _savedUser = user;
        _checking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _checking = false;
      });
    }
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

    if (_initError != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: Color(0xFFE53935),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Firebase 연결에 실패했습니다',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _checkRegistration,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
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
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.meeting_room_rounded,
                    color: AppColors.blue,
                    size: 46,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'ROOMFIT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '나와 딱 맞는\n기숙사 룸메이트, 룸핏',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  height: 1.35,
                  letterSpacing: -0.6,
                ),
              ),
              const Spacer(flex: 4),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16.5,
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
  TimeOfDay _sleepTime = const TimeOfDay(hour: 0, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 8, minute: 30);

  late List<TimeOfDay> _dailyClassTimes;
  late List<bool> _dailyNoClass;

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
  static const _weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일'];

  @override
  void initState() {
    super.initState();
    final init = widget.initialProfile;
    if (init != null) {
      _name.text = init.name;
      _dorm = _dorms.contains(init.dorm) ? init.dorm : '101동';
      _smoking = init.smoking;
      _sleepTime = _parseTimeOfDay(init.sleep, fallbackHour: 0, fallbackMin: 30);
      _wakeTime = _parseTimeOfDay(init.wake, fallbackHour: 8, fallbackMin: 30);

      _dailyClassTimes = List<TimeOfDay>.generate(5, (i) {
        final str = init.dailyFirstClasses[i];
        if (str == '수업 없음' || str == '오전수업 없음') {
          return const TimeOfDay(hour: 9, minute: 0);
        }
        return _parseTimeOfDay(str, fallbackHour: 9, fallbackMin: 0);
      });
      _dailyNoClass = List<bool>.generate(5, (i) {
        final str = init.dailyFirstClasses[i];
        return str == '수업 없음' || str == '오전수업 없음';
      });

      _stay = init.stayInDorm;
      _drink = init.drinkingPerWeek;
      _clean = init.cleaningPerWeek;
      _eat = init.eatInRoom;
      _call = init.callInRoom;
      _lightSleep = init.lightSleeper == 'O';
      _snore = init.snoring == 'O';
      _priorities = List<String>.from(init.rank3Priorities);
    } else {
      _dailyClassTimes =
      List<TimeOfDay>.filled(5, const TimeOfDay(hour: 9, minute: 0));
      _dailyNoClass = List<bool>.filled(5, false);
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

  TimeOfDay _parseTimeOfDay(String hhmm,
      {required int fallbackHour, required int fallbackMin}) {
    try {
      final p = hhmm.split(':');
      final h = int.parse(p[0]) % 24;
      final m = int.parse(p[1]);
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return TimeOfDay(hour: fallbackHour, minute: fallbackMin);
    }
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.blue,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
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

  void _onReorderPriority(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _priorities.removeAt(oldIndex);
      _priorities.insert(newIndex, item);
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

    try {
      final dailyStrings = List<String>.generate(5, (i) {
        return _dailyNoClass[i]
            ? '수업 없음'
            : _formatTimeOfDay(_dailyClassTimes[i]);
      });

      final shortDays = ['월', '화', '수', '목', '금'];
      final summaryFirstClass = List<String>.generate(5, (i) {
        return '${shortDays[i]} ${dailyStrings[i]}';
      }).join(', ');

      final profile = RegisteredUserProfile(
        name: _name.text.trim(),
        dorm: _dorm,
        smoking: _smoking,
        sleep: _formatTimeOfDay(_sleepTime),
        wake: _formatTimeOfDay(_wakeTime),
        firstClass: summaryFirstClass,
        dailyFirstClasses: dailyStrings,
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '저장 실패: $e';
      });
    }
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
          '시간을 눌러 시계 또는 키보드로 직접 시간을 선택할 수 있어요.',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _timePickerTile(
                icon: Icons.bedtime_outlined,
                label: '평균 취침 시간',
                timeText: _formatTimeOfDay(_sleepTime),
                onTap: () => _pickTime(
                  initial: _sleepTime,
                  onSelected: (t) => setState(() => _sleepTime = t),
                ),
              ),
              const Divider(height: 24, color: AppColors.border),
              _timePickerTile(
                icon: Icons.wb_sunny_outlined,
                label: '평균 기상 시간',
                timeText: _formatTimeOfDay(_wakeTime),
                onTap: () => _pickTime(
                  initial: _wakeTime,
                  onSelected: (t) => setState(() => _wakeTime = t),
                ),
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
        const SizedBox(height: 14),
        WhitePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '요일별 첫 수업 시작 시간',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                '요일마다 시간을 눌러 선택하거나 공강(수업 없음)을 체크하세요.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              ...List.generate(5, (i) {
                final isNoClass = _dailyNoClass[i];
                return Container(
                  margin: EdgeInsets.only(bottom: i < 4 ? 10 : 0),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          _weekdays[i],
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: isNoClass
                              ? null
                              : () => _pickTime(
                            initial: _dailyClassTimes[i],
                            onSelected: (t) => setState(
                                    () => _dailyClassTimes[i] = t),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isNoClass
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isNoClass
                                      ? '수업 없음'
                                      : _formatTimeOfDay(_dailyClassTimes[i]),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: isNoClass
                                        ? AppColors.muted
                                        : AppColors.blue,
                                  ),
                                ),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 18,
                                  color: isNoClass
                                      ? AppColors.muted
                                      : AppColors.blue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(
                                () => _dailyNoClass[i] = !_dailyNoClass[i]),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: isNoClass,
                              activeColor: AppColors.blue,
                              materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (v) => setState(
                                      () => _dailyNoClass[i] = v ?? false),
                            ),
                            const Text(
                              '없음',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
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

  Widget _timePickerTile({
    required IconData icon,
    required String label,
    required String timeText,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.blue),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_outlined, size: 16, color: AppColors.blue),
              ],
            ),
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '생활습관 중요도 순위',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '드래그로 순서 변경',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '항목을 길게 눌러 위아래로 끌어당겨 순위를 정해주세요.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _priorities.length,
                onReorder: _onReorderPriority,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Material(
                        elevation: 6,
                        color: Colors.transparent,
                        shadowColor: AppColors.blue.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        child: Transform.scale(
                          scale: 1.02,
                          child: child,
                        ),
                      );
                    },
                    child: child,
                  );
                },
                itemBuilder: (context, i) {
                  final label = _priorities[i];
                  final isTop3 = i < 3;
                  return ReorderableDragStartListener(
                    key: ValueKey(label),
                    index: i,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: isTop3 ? Colors.white : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isTop3
                              ? AppColors.blue.withValues(alpha: 0.35)
                              : AppColors.border,
                          width: isTop3 ? 1.3 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.drag_indicator_rounded,
                            color: isTop3 ? AppColors.blue : AppColors.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isTop3
                                  ? AppColors.blue
                                  : AppColors.muted.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isTop3 ? Colors.white : AppColors.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight:
                                isTop3 ? FontWeight.w700 : FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
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
  Set<String> _likedRoommates = {};

  @override
  void initState() {
    super.initState();
    _loadLikedRoommates();
  }

  Future<void> _loadLikedRoommates() async {
    try {
      final liked = await UserStorageService.getLikedRoommates();
      if (!mounted) return;
      setState(() => _likedRoommates = liked);
    } catch (_) {}
  }

  Future<void> _cancelLikedRoommate(String name) async {
    final updated = await UserStorageService.toggleLikedRoommate(name);
    if (!mounted) return;
    setState(() => _likedRoommates = updated);
  }

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
    return 2;
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
      final List<int?> dailyFirstClassMins = u.dailyFirstClasses.map((str) {
        if (str == '수업 없음' || str == '오전수업 없음') return null;
        return _hhmmToMinutes(str);
      }).toList();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            response: response,
            myDorm: u.dorm,
            mySmoking: u.smoking == 'O',
            myBed: _hhmmToMinutes(u.sleep),
            myWake: List<int>.filled(5, wakeMin),
            myFirstClass: dailyFirstClassMins,
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

      await _loadLikedRoommates();
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
            if (_likedRoommates.isNotEmpty) ...[
              WhitePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: Color(0xFFE53935),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '내가 룸메이트 신청한 후보 (${_likedRoommates.length}명)',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _likedRoommates.map((name) {
                        return Container(
                          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEFEF),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: const Color(0xFFE53935)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                borderRadius: BorderRadius.circular(99),
                                onTap: () => _cancelLikedRoommate(name),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: Color(0xFFE53935),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
                      InfoPill(text: '체류 ${u.stayInDorm}'),
                      InfoPill(text: '음주 주 ${u.drinkingPerWeek}회'),
                      InfoPill(text: '청소 주 ${u.cleaningPerWeek}회'),
                      InfoPill(text: '식사 ${u.eatInRoom}'),
                      InfoPill(text: '통화 ${u.callInRoom}'),
                      InfoPill(text: '잠귀예민 ${u.lightSleeper}'),
                      InfoPill(text: '코골이 ${u.snoring}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '첫 수업: ${u.firstClass}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
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
}