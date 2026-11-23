import 'package:flutter/material.dart';
import 'ai_matching_service.dart';
import 'clean_ui.dart';
import 'roommate.dart';
import 'user_storage_service.dart';

class ResultScreen extends StatefulWidget {
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

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Set<String> _likedNames = {};

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    final liked = await UserStorageService.getLikedRoommates();
    if (!mounted) return;
    setState(() => _likedNames = liked);
  }

  Future<void> _toggleLike(String candidateName) async {
    final wasLiked = _likedNames.contains(candidateName);
    final updated = await UserStorageService.toggleLikedRoommate(candidateName);
    if (!mounted) return;
    setState(() => _likedNames = updated);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: wasLiked ? AppColors.text : AppColors.blue,
          content: Row(
            children: [
              Icon(
                wasLiked ? Icons.heart_broken_rounded : Icons.favorite_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  wasLiked
                      ? '$candidateName님에게 보낸 룸메이트 신청을 취소했어요.'
                      : '$candidateName님에게 룸메이트 신청을 보냈어요!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.response.recommendations;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: const Text(
          '추천 결과',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        actions: [
          if (_likedNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEFEF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: Color(0xFFE53935),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '신청 ${_likedNames.length}명',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            '${widget.myDorm} · ${widget.mySmoking ? '흡연' : '비흡연'} 기준\nAI 룸메이트 추천 TOP ${list.length}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '마음에 드는 후보에게 하트를 눌러 룸메이트 신청을 보내보세요.',
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          if (list.isEmpty)
            const WhitePanel(
              child: Text(
                '같은 기숙사 동과 흡연 여부가 일치하는 후보를 찾지 못했습니다.',
                style: TextStyle(fontSize: 15, color: AppColors.muted),
              ),
            ),
          for (int i = 0; i < list.length; i++) ...[
            _RankCard(
              rank: i + 1,
              item: list[i],
              isLiked: _likedNames.contains(list[i].profile.name),
              onToggleLike: () => _toggleLike(list[i].profile.name),
              onTap: () => _openDetail(context, list[i]),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, AiRecommendation item) {
    final p = item.profile;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isLiked = _likedNames.contains(p.name);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            builder: (_, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 36),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p.dorm} · ${p.smoking == 'O' ? '흡연' : '비흡연'} · 일치도 ${item.totalScore.toStringAsFixed(1)}점',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _LikeActionButton(
                      isLiked: isLiked,
                      onPressed: () async {
                        await _toggleLike(p.name);
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.reason,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.text,
                      height: 1.5,
                    ),
                  ),
                ),
                if (item.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '미리 조율할 부분',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final c in item.warnings)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '· $c',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.text,
                                height: 1.45,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  '나와 상세 비교',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                _compareRow('취침 시간', formatMinutes(widget.myBed), p.sleep),
                _compareRow(
                  '기상 시간',
                  _formatWakeList(widget.myWake),
                  p.wake,
                ),
                _compareRow(
                  '첫 수업 시간',
                  _formatFirstClassList(widget.myFirstClass),
                  p.firstClass,
                ),
                _compareRow('기숙사 체류', widget.myStayLabel, p.stayInDorm),
                _compareRow(
                  '주간 음주',
                  '주 ${widget.myHabits['drink']}회',
                  '주 ${p.drinkingPerWeek}회',
                ),
                _compareRow(
                  '주간 청소',
                  '주 ${widget.myHabits['clean']}회',
                  '주 ${p.cleaningPerWeek}회',
                ),
                _compareRow(
                  '방 안 식사',
                  _triLabel(widget.myHabits['meal']!),
                  p.eatInRoom,
                ),
                _compareRow(
                  '방 안 통화',
                  _triLabel(widget.myHabits['call']!),
                  p.callInRoom,
                ),
                _compareRow(
                  '잠귀 예민',
                  widget.myHabits['sensitive'] == 1 ? '예민함' : '무던함',
                  p.lightSleeper == 'O' ? '예민함' : '무던함',
                ),
                _compareRow(
                  '코골이',
                  widget.myHabits['snore'] == 1 ? '있음' : '없음',
                  p.snoring == 'O' ? '있음' : '없음',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _triLabel(int v) {
    if (v == 0) return '비선호';
    if (v == 1) return '선호';
    return '무관';
  }

  String _formatWakeList(List<int> list) {
    final unique = list.map(formatMinutes).toSet();
    if (unique.length == 1) return unique.first;
    const days = ['월', '화', '수', '목', '금'];
    return List.generate(5, (i) => '${days[i]} ${formatMinutes(list[i])}')
        .join(', ');
  }

  String _formatFirstClassList(List<int?> list) {
    const days = ['월', '화', '수', '목', '금'];
    return List.generate(
      5,
          (i) => '${days[i]} ${list[i] == null ? '없음' : formatMinutes(list[i]!)}',
    ).join(', ');
  }

  Widget _compareRow(String label, String mine, String theirs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '나: $mine',
              style: const TextStyle(fontSize: 13.5, color: AppColors.text),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '상대: $theirs',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LikeActionButton extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onPressed;

  const _LikeActionButton({
    required this.isLiked,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const heartRed = Color(0xFFE53935);
    const heartBg = Color(0xFFFFEFEF);

    return Material(
      color: isLiked ? heartBg : AppColors.background,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isLiked ? heartRed.withValues(alpha: 0.4) : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isLiked ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color: isLiked ? heartRed : AppColors.muted,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isLiked ? '신청 완료' : '룸메 신청',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isLiked ? heartRed : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final int rank;
  final AiRecommendation item;
  final bool isLiked;
  final VoidCallback onToggleLike;
  final VoidCallback onTap;

  const _RankCard({
    required this.rank,
    required this.item,
    required this.isLiked,
    required this.onToggleLike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.profile;
    final top = rank == 1;

    return GestureDetector(
      onTap: onTap,
      child: WhitePanel(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: top ? AppColors.blue : AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$rank위',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: top ? Colors.white : AppColors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
                _LikeActionButton(
                  isLiked: isLiked,
                  onPressed: onToggleLike,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${p.dorm} · ${p.smoking == 'O' ? '흡연' : '비흡연'}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  '${item.totalScore.toStringAsFixed(1)}점',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.reason,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoPill(text: '취침 ${p.sleep}'),
                InfoPill(text: '기상 ${p.wake}'),
                InfoPill(text: '체류 ${p.stayInDorm}'),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '상세 비교 보기',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}