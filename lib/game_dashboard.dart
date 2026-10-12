import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _gameKey = 'study_game_progress_v1';
const _ink = Color(0xFF202840);
const _violet = Color(0xFF6957D8);
const _mint = Color(0xFF2EBB91);

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class StudyGameProgress {
  const StudyGameProgress({
    required this.totalXp,
    required this.todayXp,
    required this.streak,
    required this.completedSessions,
    required this.lastStudyDate,
    required this.todayDate,
    required this.lastSessionId,
    required this.lastBaseXp,
    required this.lastBonusXp,
    required this.bonusTodayXp,
  });

  final int totalXp;
  final int todayXp;
  final int streak;
  final int completedSessions;
  final String lastStudyDate;
  final String todayDate;
  final String lastSessionId;
  final int lastBaseXp;
  final int lastBonusXp;
  final int bonusTodayXp;

  static StudyGameProgress _fromJson(String? raw) {
    if (raw == null) {
      return const StudyGameProgress(
        totalXp: 0,
        todayXp: 0,
        streak: 0,
        completedSessions: 0,
        lastStudyDate: '',
        todayDate: '',
        lastSessionId: '',
        lastBaseXp: 0,
        lastBonusXp: 0,
        bonusTodayXp: 0,
      );
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return StudyGameProgress(
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
      todayXp: (map['todayXp'] as num?)?.toInt() ?? 0,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      completedSessions: (map['completedSessions'] as num?)?.toInt() ?? 0,
      lastStudyDate: map['lastStudyDate'] as String? ?? '',
      todayDate: map['todayDate'] as String? ?? '',
      lastSessionId: map['lastSessionId'] as String? ?? '',
      lastBaseXp: (map['lastBaseXp'] as num?)?.toInt() ?? 0,
      lastBonusXp: (map['lastBonusXp'] as num?)?.toInt() ?? 0,
      bonusTodayXp: (map['bonusTodayXp'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<StudyGameProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _fromJson(prefs.getString(_gameKey));
  }

  // 완료한 세션 한 번에만 XP를 지급합니다. 정답률을 추측하지 않습니다.
  static Future<void> recordSession({
    required String sessionId,
    required int conceptCount,
  }) async {
    if (conceptCount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final old = _fromJson(prefs.getString(_gameKey));
    if (old.lastSessionId == sessionId) return;

    final now = DateTime.now();
    final today = _dayKey(now);
    final yesterday = _dayKey(
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1)),
    );
    final newStreak = old.lastStudyDate == today
        ? old.streak
        : old.lastStudyDate == yesterday
            ? old.streak + 1
            : 1;
    final base = conceptCount * 10;
    final bonusUsed = old.todayDate == today ? old.bonusTodayXp : 0;
    // 기본 XP는 항상 지급. 무료 깜짝 보너스는 25% 확률로 +10 XP, 하루 최대 30 XP.
    final bonus = bonusUsed < 30 && math.Random().nextInt(4) == 0 ? 10 : 0;
    final points = base + bonus;
    final updated = <String, dynamic>{
      'totalXp': old.totalXp + points,
      'todayXp': (old.todayDate == today ? old.todayXp : 0) + points,
      'todayDate': today,
      'streak': newStreak,
      'lastStudyDate': today,
      'completedSessions': old.completedSessions + 1,
      'lastSessionId': sessionId,
      'lastBaseXp': base,
      'lastBonusXp': bonus,
      'bonusTodayXp': bonusUsed + bonus,
    };
    if (!await prefs.setString(_gameKey, jsonEncode(updated))) {
      throw StateError('게임 진행 기록 저장 실패');
    }
  }

  int get currentStreak {
    final now = DateTime.now();
    final today = _dayKey(now);
    final yesterday = _dayKey(
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1)),
    );
    return lastStudyDate == today || lastStudyDate == yesterday ? streak : 0;
  }

  int get currentTodayXp => todayDate == _dayKey(DateTime.now()) ? todayXp : 0;
}

// 학습을 완료하고 아직 처음 보는 문제의 개수 (기존 질문 커서 키 활용).
Future<int> _remainingNewQuestions() async {
  final text = await rootBundle.loadString('assets/concepts/concepts.json');
  final data = jsonDecode(text) as List<dynamic>;
  final prefs = await SharedPreferences.getInstance();
  var remaining = 0;
  for (final raw in data) {
    final concept = raw as Map<String, dynamic>;
    final id = concept['id'] as String;
    final questions = concept['questions'] as List<dynamic>? ?? [];
    final seen = prefs.getInt('concept_question_cursor_v1$id') ?? 0;
    remaining += math.max(0, questions.length - seen);
  }
  return remaining;
}

class GameDashboard extends StatefulWidget {
  const GameDashboard({super.key, required this.count, required this.dueCount, required this.onStart});
  final int count;
  final int dueCount;
  final VoidCallback onStart;
  @override
  State<GameDashboard> createState() => _GameDashboardState();
}

class _GameDashboardState extends State<GameDashboard> with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  late final Future<int> _remaining;
  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: const Duration(milliseconds: 2900));
    _remaining = _remainingNewQuestions();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _motion.stop();
      _motion.value = 0;
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }
  @override
  void dispose() { _motion.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudyGameProgress>(
      future: StudyGameProgress.load(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('학습 기록을 읽지 못했어요: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final stats = snapshot.data!;
        final today = stats.currentTodayXp;
        final region = today ~/ 50 + 1;
        final inRegion = today % 50;
        return Container(
          color: const Color(0xFFF4F2FF),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
            Row(children: [
              const Expanded(child: Text('오늘의 모험', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFF292653)))),
              Text('🔥 ${stats.currentStreak}일  ·  ⭐ ${stats.totalXp} XP', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ]),
            const SizedBox(height: 13),
            Container(
              height: 205,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(colors: [Color(0xFF34418D), Color(0xFF7357CE), Color(0xFFB078DB)]),
                boxShadow: const [BoxShadow(color: Color(0x446954D8), blurRadius: 19, offset: Offset(0, 9))],
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(25), child: Stack(children: [
                Positioned.fill(child: AnimatedBuilder(animation: _motion, builder: (context, _) {
                  final phase = _motion.value * math.pi * 2;
                  return Stack(children: [
                    for (var i = 0; i < 12; i++) Positioned(
                      left: 12.0 + (i * 57.0) % 310, top: 8.0 + (i * 39.0) % 160,
                      child: Opacity(opacity: 0.25 + 0.65 * (1 + math.sin(phase + i * 1.7)) / 2,
                        child: const Icon(Icons.auto_awesome, size: 11, color: Color(0xFFFFD77C))),
                    ),
                    Positioned(right: 17, top: 25 + math.sin(phase) * 7, child: const _GuideRobot()),
                  ]);
                })),
                Positioned(left: 18, right: 142, top: 22, bottom: 18, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('✨ 오늘의 탐험', style: TextStyle(color: Color(0xFFFFE5A2), fontWeight: FontWeight.w900)),
                    const SizedBox(height: 9),
                    Text('제$region구간 진행 중', maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text('현재 구간 $inRegion / 50 XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(
                      value: inRegion / 50, minHeight: 10, backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD776)),
                    )),
                    const SizedBox(height: 5),
                    Text('${50 - inRegion} XP 후 다음 탐험', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                )),
              ])),
            ),
            const SizedBox(height: 13),
            Row(children: [
              Expanded(child: _InfoTile(icon: '🏆', label: '완료 세션', value: '${stats.completedSessions}회')),
              const SizedBox(width: 8),
              Expanded(child: _InfoTile(icon: '🔁', label: '복습 대기', value: '${widget.dueCount}개')),
            ]),
            const SizedBox(height: 8),
            FutureBuilder<int>(future: _remaining, builder: (context, result) {
              final label = result.hasError ? '새 문제 수를 불러올 수 없어요'
                  : !result.hasData ? '새 문제 확인 중...'
                  : result.data! > 0 ? '아직 만나지 않은 문제 ${result.data}개'
                  : '새 문제는 모두 만났어요 · 복습은 계속할 수 있어요';
              return _InfoTile(icon: '📘', label: '다음에 도전', value: label);
            }),
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🗺️ 제$region구간 · 끝나지 않는 탐험', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('50 XP마다 새로운 구간이 열려요', style: TextStyle(fontSize: 12, color: Color(0xFF766E92))),
                SizedBox(height: 280, child: LayoutBuilder(builder: (context, box) {
                  final centers = List<Offset>.generate(5, (i) => Offset(i.isEven ? box.maxWidth * .27 : box.maxWidth * .73, 32.0 + i * 57));
                  return Stack(children: [
                    Positioned.fill(child: CustomPaint(painter: _Trail(centers, inRegion / 50))),
                    for (var i = 0; i < 5; i++) Positioned(
                      left: centers[i].dx - 38, top: centers[i].dy - 25, width: 76,
                      child: AnimatedBuilder(animation: _motion, builder: (context, _) {
                        final done = inRegion >= (i + 1) * 10;
                        final next = !done && inRegion >= i * 10;
                        return Column(children: [
                          Transform.scale(scale: next ? 1 + .05 * math.sin(_motion.value * 2 * math.pi) : 1,
                            child: Container(width: 49, height: 49, alignment: Alignment.center,
                              decoration: BoxDecoration(shape: BoxShape.circle,
                                color: done ? const Color(0xFFFFD67A) : next ? const Color(0xFF7456DA) : const Color(0xFFE9E5F3),
                                boxShadow: next ? const [BoxShadow(color: Color(0x777A59DF), blurRadius: 12, spreadRadius: 3)] : null),
                              child: Text(['🌱','🌲','📚','💎','🏰'][i], style: const TextStyle(fontSize: 23))),
                          ),
                          Text('${(i + 1) * 10} XP', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                        ]);
                      }),
                    ),
                  ]);
                })),
                SizedBox(width: double.infinity, child: FilledButton.icon(
                  onPressed: widget.count == 0 ? null : widget.onStart,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7655D8), minimumSize: const Size.fromHeight(53)),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(widget.count == 0 ? '학습할 개념이 없어요' : stats.completedSessions > 0 ? '다음 탐험 시작' : '첫 탐험 시작', style: const TextStyle(fontWeight: FontWeight.w900)),
                )),
              ]),
            ),
            const SizedBox(height: 10),
            const Text('완료 시 개념당 10 XP · 무료 깜짝 보너스 +10 XP 확률 25% (하루 최대 30 XP)\n보너스가 없어도 기본 XP는 항상 지급돼요.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF706C88))),
          ]),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final String icon, label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [Text(icon, style: const TextStyle(fontSize: 22)), const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF706C88))),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
      ])),
    ]),
  );
}

class _GuideRobot extends StatelessWidget {
  const _GuideRobot();
  @override
  Widget build(BuildContext context) => SizedBox(width: 112, height: 130, child: Stack(alignment: Alignment.center, children: [
    Positioned(bottom: 0, child: Container(width: 78, height: 12, decoration: const BoxDecoration(color: Color(0x66312061), shape: BoxShape.circle))),
    Positioned(top: 8, child: Container(width: 5, height: 25, color: const Color(0xFFDDEAFF))),
    const Positioned(top: 0, child: Icon(Icons.star_rounded, color: Color(0xFFFFDE87), size: 22)),
    Positioned(top: 68, child: Container(width: 60, height: 53, decoration: BoxDecoration(color: const Color(0xFFDCEAFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.auto_awesome, color: Color(0xFF7958CB)))),
    Positioned(top: 25, child: Container(width: 98, height: 72, padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.white, Color(0xFFDDEBFF)]), borderRadius: BorderRadius.circular(29), boxShadow: const [BoxShadow(color: Color(0x66322275), blurRadius: 14, offset: Offset(0, 7))]),
      child: Container(decoration: BoxDecoration(color: const Color(0xFF263C78), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.auto_awesome, color: Color(0xFF9BE8FF), size: 30)),
    )),
  ]));
}

class _Trail extends CustomPainter {
  const _Trail(this.points, this.progress);
  final List<Offset> points;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      path.cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
    }
    canvas.drawPath(path, Paint()..color = const Color(0xFFE9E3F3)..style = PaintingStyle.stroke..strokeWidth = 11);
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), Paint()..color = const Color(0xFFFFC665)..style = PaintingStyle.stroke..strokeWidth = 7);
    }
  }
  @override
  bool shouldRepaint(covariant _Trail old) => old.progress != progress || old.points != points;
}
