import 'dart:async';
import 'package:flutter/material.dart';
import 'past_exam_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Flow',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  // 시험 날짜
  final DateTime targetDate = DateTime(2027, 11, 28);

  Duration remaining = Duration.zero;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    _updateRemaining();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (mounted) {
      setState(() {
        remaining = difference.isNegative ? Duration.zero : difference;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  int get days => remaining.inDays;

  int get hours => remaining.inHours % 24;

  int get minutes => remaining.inMinutes % 60;

  int get seconds => remaining.inSeconds % 60;

  String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: [
            _buildHome(),
            _buildStudyPage(),
            _buildStatsPage(),
            _buildPastExamPage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // =========================
  // HOME
  // =========================

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),

          const SizedBox(height: 24),

          _buildDDayCard(),

          const SizedBox(height: 18),

          _buildTodayGoal(),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 학습',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '3 / 5',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildLearningPath(),

          const SizedBox(height: 28),

          _buildQuickReview(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              '🧠',
              style: TextStyle(fontSize: 25),
            ),
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘도 공부해볼까?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '시험 준비',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Text(
                '🔥',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(width: 4),
              Text(
                '7',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // D-DAY
  // =========================

  Widget _buildDDayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F7CFF),
            Color(0xFF6D5DFB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F7CFF).withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '시험까지 남은 시간',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'D-$days',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox(
                twoDigits(hours),
                '시간',
              ),
              _buildTimeSeparator(),
              _buildTimeBox(
                twoDigits(minutes),
                '분',
              ),
              _buildTimeSeparator(),
              _buildTimeBox(
                twoDigits(seconds),
                '초',
              ),
            ],
          ),

          const SizedBox(height: 15),

          const Text(
            '2027년 11월 28일 시험',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =========================
  // TODAY GOAL
  // =========================

  Widget _buildTodayGoal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    '⭐',
                    style: TextStyle(fontSize: 23),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘의 목표',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '15분만 집중해보세요!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                '60%',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              value: 0.6,
              minHeight: 10,
              backgroundColor: Color(0xFFEAECEF),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF58CC78),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // LEARNING PATH
  // =========================

  Widget _buildLearningPath() {
    return Column(
      children: [
        _buildPathItem(
          number: '✓',
          title: '어제 배운 내용 복습',
          subtitle: '간격 반복 복습',
          emoji: '🔄',
          color: const Color(0xFF58CC78),
          completed: true,
          alignLeft: true,
        ),

        _buildPathLine(),

        _buildPathItem(
          number: '2',
          title: '새로운 개념 학습',
          subtitle: '오늘의 마이크로 러닝',
          emoji: '📖',
          color: const Color(0xFF4F7CFF),
          completed: false,
          alignLeft: false,
        ),

        _buildPathLine(),

        _buildPathItem(
          number: '3',
          title: '청킹 훈련',
          subtitle: '핵심 내용을 작은 단위로 기억하기',
          emoji: '🧩',
          color: const Color(0xFF9B6CFF),
          completed: false,
          alignLeft: true,
        ),

        _buildPathLine(),

        _buildPathItem(
          number: '4',
          title: '회상 테스트',
          subtitle: '힌트 없이 기억해보기',
          emoji: '🧠',
          color: const Color(0xFFFFA62B),
          completed: false,
          alignLeft: false,
        ),

        _buildPathLine(),

        _buildPathItem(
          number: '🔒',
          title: '오늘의 학습 완료',
          subtitle: '모든 학습을 완료하면 열립니다',
          emoji: '🏆',
          color: Colors.grey.shade400,
          completed: false,
          alignLeft: true,
          locked: true,
        ),
      ],
    );
  }

  Widget _buildPathItem({
    required String number,
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
    required bool completed,
    required bool alignLeft,
    bool locked = false,
  }) {
    return Row(
      mainAxisAlignment:
          alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (!alignLeft)
          const SizedBox(width: 65),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: locked
                              ? Colors.grey
                              : const Color(0xFF202124),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (completed)
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF58CC78),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 19,
                    ),
                  )
                else
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (alignLeft)
          const SizedBox(width: 65),
      ],
    );
  }

  Widget _buildPathLine() {
    return SizedBox(
      height: 25,
      child: Center(
        child: Container(
          width: 3,
          height: 25,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // =========================
  // QUICK REVIEW
  // =========================

  Widget _buildQuickReview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Text(
            '💡',
            style: TextStyle(fontSize: 32),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '잠깐 복습할까요?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '오늘 복습해야 할 카드가 12개 있어요.',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
          ),
        ],
      ),
    );
  }

  // =========================
  // STUDY
  // =========================

  Widget _buildStudyPage() {
    return const Center(
      child: Text(
        '📚 학습\n\n여기에 과목과 학습 카드를 만들 거예요.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // =========================
  // STATS
  // =========================

  Widget _buildStatsPage() {
    return const Center(
      child: Text(
        '📊 학습 통계\n\n나중에 기억률과 학습 기록을 보여줄 거예요.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // =========================
  // PAST EXAM
  // =========================


Widget _buildPastExamPage() {
  return DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '기출문제',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEFF3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF202124),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              tabs: const [
                Tab(text: '연도별'),
                Tab(text: '과목별'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Expanded(
          child: TabBarView(
            children: [
              _PastExamByYear(),
              _PastExamBySubject(),
            ],
          ),
        ),
      ],
    ),
  );
}
  // =========================
  // BOTTOM NAVIGATION
  // =========================

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F0FE),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: '학습',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: '통계',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: '기출',
        ),
      ],
    );
  }
}
class _PastExamByYear extends StatelessWidget {
  const _PastExamByYear();

  @override
  Widget build(BuildContext context) {
    final years = [
      '2026년',
      '2025년',
      '2024년',
      '2023년',
      '2022년',
      '2021년',
      '2020년',
      '2019년',
      '2018년',
      '2017년',
      '2016년',
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final yearText = years[index];
        final year = int.parse(yearText.replaceAll('년', ''));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('📅', style: TextStyle(fontSize: 22)),
              ),
            ),
            title: Text(
              yearText,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: const Text(
              '기출문제 풀기',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
           onTap: () {
  final yearText = years[index];
  final year = int.parse(yearText.replaceAll('년', ''));

  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('$yearText 기출문제 선택'),
            ),
            for (final subject in ['A', 'B'])
              ListTile(
                title: Text('전공 $subject'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PastExamPdfPage(
                        year: year,
                        subject: subject,
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              title: const Text('교육학'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EducationExamPdfPage(year: year),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
},
          ),
        );
      },
    );
  }
}

class _PastExamBySubject extends StatelessWidget {
  const _PastExamBySubject();

  @override
  Widget build(BuildContext context) {
    final subjects = [
      ('교육학', '🎓'),
      ('심리학개론', '🧠'), 
      ('성격심리', '👤'), 
      ('학습심리', '📖'), 
      ('상담이론과 실제', '💬'), 
      ('가족상담', '👨‍👩‍👧‍👦'), 
      ('특수아상담', '🧩'), 
      ('이상심리학', '🩺'), 
      ('심리검사', '📊'), 
      ('진로상담', '🧭'), 
      ('집단상담', '👥'), 
      ('아동심리학', '👶'), 
      ('청소년 심리학', '🧑‍🎓'),
      ('상담실습', '📝'),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EAFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  subjects[index].$2,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            title: Text(
              subjects[index].$1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: const Text(
              '과목별 기출문제',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
            onTap: () {
              // 나중에 해당 과목 기출문제로 이동
            },
          ),
        );
      },
    );
  }
}
