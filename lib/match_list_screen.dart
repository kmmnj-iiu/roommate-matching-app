import 'package:flutter/material.dart';
import 'clean_ui.dart';
import 'ai_matching_service.dart';

class ResultScreen extends StatelessWidget {
  final AiMatchResponse response;
  final String myDorm;
  final bool mySmoking;
  final int myBed;
  final List<int> myWake;
  final List<int?> myFirstClass;
  final String myStayLabel;
  final Map<String, int> myHabits;
  final List<String> myPriorityKeys;

  const ResultScreen({
    super.key,
    required this.response,
    required this.myDorm,
    required this.mySmoking,
    required this.myBed,
    required this.myWake,
    required this.myFirstClass,
    required this.myStayLabel,
    required this.myHabits,
    required this.myPriorityKeys,
  });

  static const _weekdays = ['월', '화', '수', '목', '금'];
  static const _habitTitles = {
    'drink': '음주 빈도',
    'clean': '청소 빈도',
    'meal': '방 안 식사',
    'call': '방 안 통화',
    'sensitive': '잠귀 예민도',
    'snore': '코골이 여부',
  };

  String _displayMyHabit(String key, int val) {
    if (key == 'drink' || key == 'clean') return '주 $val회';
    if (key == 'meal' || key == 'call') {
      return {0: '비허용', 1: '허용', 2: '상관없음'}[val]!;
    }
    if (key == 'sensitive') return val == 1 ? '잠귀가 밝음' : '잠귀가 밝지 않음';
    return val == 1 ? '코골이 있음' : '코골이 없음';
  }

  String _displayOtherHabit(String key, AiRecommendation item) {
    final p = item.profile;
    if (key == 'drink') return '주 ${p.drinkingPerWeek}회';
    if (key == 'clean') return '주 ${p.cleaningPerWeek}회';
    if (key == 'meal') return p.eatInRoom == 'O' ? '허용' : (p.eatInRoom == 'X' ? '비허용' : '상관없음');
    if (key == 'call') return p.callInRoom == 'O' ? '허용' : (p.callInRoom == 'X' ? '비허용' : '상관없음');
    if (key == 'sensitive') return p.lightSleeper == 'O' ? '잠귀가 밝음' : '잠귀가 밝지 않음';
    return p.snoring == 'O' ? '코골이 있음' : '코골이 없음';
  }

  Widget _scoreBar(String label, double score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
              Text(score.toStringAsFixed(1),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              backgroundColor: AppColors.background,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warning(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF9A4D00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Color(0xFF7A3E00), fontSize: 12, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _comparisonRow(String label, String mine, String other, {bool header = false}) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: header ? FontWeight.w700 : FontWeight.w400,
      color: header ? AppColors.text : AppColors.muted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(label, style: style)),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: Text(mine, style: style)),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: Text(other, style: style)),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, AiRecommendation item) {
    final person = item.profile;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${person.name}님과 비교',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      WhitePanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('생활패턴 비교',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            _comparisonRow('항목', '나', '상대', header: true),
                            const Divider(),
                            _comparisonRow('취침', formatMinutes(myBed), person.sleep),
                            _comparisonRow(
                                '기숙사 체류',
                                myStayLabel,
                                person.stayInDorm == 'O' ? '주로 기숙사' : '주로 외출'),
                            const Divider(),
                            for (int day = 0; day < 5; day++) ...[
                              _comparisonRow('${_weekdays[day]} 기상',
                                  formatMinutes(myWake[day]), person.wake),
                              _comparisonRow(
                                  '${_weekdays[day]} 첫 수업',
                                  myFirstClass[day] == null
                                      ? '수업 없음'
                                      : formatMinutes(myFirstClass[day]!),
                                  person.firstClass),
                              if (day < 4) const Divider(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      WhitePanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('내 중요도 기준 생활습관',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            for (int i = 0; i < myPriorityKeys.length; i++) ...[
                              Text('${i + 1}순위. ${_habitTitles[myPriorityKeys[i]]}',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(
                                '나: ${_displayMyHabit(myPriorityKeys[i], myHabits[myPriorityKeys[i]]!)}\n'
                                    '상대: ${_displayOtherHabit(myPriorityKeys[i], item)}',
                                style: const TextStyle(color: AppColors.muted, height: 1.6),
                              ),
                              if (i < myPriorityKeys.length - 1) const Divider(height: 24),
                            ],
                          ],
                        ),
                      ),
                      for (final w in item.warnings) _warning(w),
                      const SizedBox(height: 16),
                      WhitePanel(
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          title: const Text('점수 산출 방식 안내',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '생활패턴(2순위): ${item.patternScore.toStringAsFixed(1)}점 (70%)\n'
                                    '생활습관(3순위): ${item.habitScore.toStringAsFixed(1)}점 (30%)\n'
                                    '최종 추천 점수: ${item.totalScore.toStringAsFixed(1)}점\n\n'
                                    'Gemini AI가 생활패턴 조화도와 사용자 우선순위 가중치를 종합 분석하여 산출했습니다.',
                                style: const TextStyle(color: AppColors.muted, height: 1.7),
                              ),
                            ),
                          ],
                        ),
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
  }

  Widget _recommendationCard(BuildContext context, AiRecommendation item, int index) {
    final person = item.profile;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: WhitePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('추천 ${index + 1}',
                      style: const TextStyle(
                          color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                const Text('추천 점수', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.name,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text('${person.dorm} · ${person.smoking == 'O' ? '흡연' : '비흡연'}',
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
                Text('${item.totalScore.toStringAsFixed(1)}점',
                    style: const TextStyle(
                        color: AppColors.blue, fontSize: 27, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 22),
            _scoreBar('생활패턴', item.patternScore, AppColors.blue),
            _scoreBar('생활습관', item.habitScore, AppColors.teal),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI 평가 이유', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(item.reason, style: const TextStyle(color: AppColors.muted, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoPill(text: '취침 ${person.sleep}'),
                InfoPill(text: '청소 주 ${person.cleaningPerWeek}회'),
                InfoPill(text: person.snoring == 'O' ? '코골이 있음' : '코골이 없음'),
              ],
            ),
            for (final w in item.warnings) _warning(w),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showDetails(context, item),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('나와 자세히 비교하기'),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추천 룸메이트', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Text('내 생활에 잘 맞는 후보',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              '조건 일치 ${response.eligibleCount}명 중 ${response.recommendations.length}명을 추천해요.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InfoPill(text: myDorm),
                InfoPill(text: mySmoking ? '흡연' : '비흡연'),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('조건 수정'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Gemini AI 평가가 추천 점수에 반영되었어요.',
                style: TextStyle(color: AppColors.blue, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < response.recommendations.length; i++)
              _recommendationCard(context, response.recommendations[i], i),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '추천 점수는 생활패턴 70%, 생활습관 30%를 반영한 비교 지표입니다. '
                    '실제 공동생활의 만족도를 보장하지 않으며, 입사 전 생활 규칙을 직접 확인하는 것이 좋아요.',
                style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}