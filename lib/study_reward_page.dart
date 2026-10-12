import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 세션 완료 이후 저장된 XP를 보여 주는 축하 화면.
/// XP 저장은 이 화면이 아닌 학습 세션에서 한 번만 처리하세요.
class StudyRewardPage extends StatefulWidget {
  const StudyRewardPage({
    super.key,
    required this.previousXp,
    required this.earnedXp,
    required this.conceptCount,
    this.baseXp = 0,
    this.bonusXp = 0,
    required this.onContinue,
  });

  final int previousXp;
  final int earnedXp;
  final int conceptCount;
  final int baseXp;
  final int bonusXp;
  final VoidCallback onContinue;

  @override
  State<StudyRewardPage> createState() => _StudyRewardPageState();
}

class _StudyRewardPageState extends State<StudyRewardPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _rainController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    // XP 숫자는 한 번만 증가하고, 보물 비는 화면을 나갈 때까지 반복됩니다.
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    // 시스템에서 애니메이션을 끈 경우 움직임을 생략합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
      } else {
        _controller.forward();
        _rainController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _rainController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101936),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rainController,
              builder: (context, _) => CustomPaint(
                painter: _TreasureRainPainter(_rainController.value),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 20,
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    final progress = Curves.easeOutCubic.transform(
                      ((t - 0.16) / 0.78).clamp(0.0, 1.0),
                    );
                    final shownGain = (widget.earnedXp * progress).round();
                    final chestLift = math.sin(t * math.pi * 5) *
                        (1 - t) * 10;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🎉  QUEST COMPLETE  🎉',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFFDF8E),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Transform.translate(
                          offset: Offset(0, chestLift),
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(colors: [
                                Color(0xFFFFE7A0),
                                Color(0xFFF8A638),
                                Color(0xFFB9692C),
                              ]),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFCE6E)
                                      .withOpacity(0.48),
                                  blurRadius: 38,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Color(0xFF73360F),
                              size: 78,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          '${widget.conceptCount}개 개념 정복!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '오늘의 보물 상자를 열었어요',
                          style: TextStyle(
                            color: Color(0xFFBFC9E9),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF243052),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFFFD577),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '획득한 경험치',
                                style: TextStyle(color: Color(0xFFBBC8ED)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '+$shownGain XP',
                                style: const TextStyle(
                                  color: Color(0xFFFFDD79),
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('기본 +${widget.baseXp} XP  ·  깜짝 보너스 +${widget.bonusXp} XP',
                                style: const TextStyle(color: Color(0xFFFFE7AB), fontSize: 13)),
                              const Text('깜짝 보너스 확률 25% · 하루 최대 30 XP',
                                style: TextStyle(color: Color(0xFFBBC8ED), fontSize: 11)),
                              const SizedBox(height: 18),
                              const Divider(color: Color(0xFF506181)),
                              const SizedBox(height: 12),
                              Text(
                                '${widget.previousXp} XP  +  $shownGain XP',
                                style: const TextStyle(
                                  color: Color(0xFFBBC8ED),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '총 ${widget.previousXp + shownGain} XP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton(
                            onPressed: widget.onContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFCB65),
                              foregroundColor: const Color(0xFF352513),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              '홈으로 돌아가기',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreasureRainPainter extends CustomPainter {
  _TreasureRainPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(4729);
    for (var i = 0; i < 95; i++) {
      final x = random.nextDouble() * size.width;
      // 정수 배속이면 반복 경계(1 → 0)에서도 위치가 끊기지 않습니다.
      final speed = 1 + (i % 3);
      final offset = random.nextDouble();
      final travel = (progress * speed + offset) % 1.0;
      final y = travel * (size.height + 140) - 70;
      final r = 3.0 + random.nextDouble() * 6.0;
      final isGem = i % 5 == 0;
      final paint = Paint()
        ..color = isGem
            ? const Color(0xFF91EEEF).withOpacity(0.85)
            : const Color(0xFFFFCE69).withOpacity(0.85);
      if (isGem) {
        final diamond = Path()
          ..moveTo(x, y - r * 1.5)
          ..lineTo(x + r, y)
          ..lineTo(x, y + r * 1.5)
          ..lineTo(x - r, y)
          ..close();
        canvas.drawPath(diamond, paint);
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: r * 1.5,
            height: r * 2,
          ),
          paint,
        );
        canvas.drawCircle(
          Offset(x - r * 0.2, y - r * 0.3),
          r * 0.19,
          Paint()..color = Colors.white.withOpacity(0.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreasureRainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
