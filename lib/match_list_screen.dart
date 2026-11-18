import 'package:flutter/material.dart';
import 'roommate.dart';
import 'ai_matching_service.dart';
import 'detail_screen.dart';

class MatchListScreen extends StatefulWidget {
  final String myName, myDorm, mySmoking;
  final String mySleep, myWake, myFirstClass, myStayInDorm;
  final int myDrinking, myCleaning;
  final String myEatInRoom, myCallInRoom, myLightSleeper, mySnoring;
  final List<String> rank3Priorities;

  const MatchListScreen({
    super.key,
    required this.myName,
    required this.myDorm,
    required this.mySmoking,
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
  });

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  List<Roommate> _top5 = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadTop5();
  }

  Future<void> _loadTop5() async {
    try {
      final result = await AiMatchingService.findTop5Matches(
        myName: widget.myName,
        myDorm: widget.myDorm,
        mySmoking: widget.mySmoking,
        mySleep: widget.mySleep,
        myWake: widget.myWake,
        myFirstClass: widget.myFirstClass,
        myStayInDorm: widget.myStayInDorm,
        myDrinking: widget.myDrinking,
        myCleaning: widget.myCleaning,
        myEatInRoom: widget.myEatInRoom,
        myCallInRoom: widget.myCallInRoom,
        myLightSleeper: widget.myLightSleeper,
        mySnoring: widget.mySnoring,
        rank3Priorities: widget.rank3Priorities,
      );
      if (!mounted) return;
      setState(() {
        _top5 = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.myDorm} 추천 룸메이트 TOP 5')),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('1순위 필터링 후 AI가 2·3순위 유사도를 분석 중입니다...'),
          ],
        ),
      )
          : _errorMsg != null
          ? Center(child: Text(_errorMsg!))
          : _top5.isEmpty
          ? const Center(child: Text('1순위 조건(기숙사/흡연)에 일치하는 후보가 없습니다.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _top5.length,
        itemBuilder: (_, i) {
          final r = _top5[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(child: Text('${i + 1}위')),
              title: Text('${r.name} (${r.dorm} · 흡연 ${r.smoking})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '취침 ${r.sleep} / 기상 ${r.wake} / 첫수업 ${r.firstClass}\n${r.aiReason}',
              ),
              isThreeLine: true,
              trailing: Text('${r.score}점',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(
                    myName: widget.myName,
                    mySleep: widget.mySleep,
                    myWake: widget.myWake,
                    myFirstClass: widget.myFirstClass,
                    myStayInDorm: widget.myStayInDorm,
                    myDrinking: widget.myDrinking,
                    myCleaning: widget.myCleaning,
                    myEatInRoom: widget.myEatInRoom,
                    myCallInRoom: widget.myCallInRoom,
                    myLightSleeper: widget.myLightSleeper,
                    mySnoring: widget.mySnoring,
                    rank3Priorities: widget.rank3Priorities,
                    target: r,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}