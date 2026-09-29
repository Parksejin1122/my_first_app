
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'D-Day',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const DDayPage(),
    );
  }
}

class DDayPage extends StatelessWidget {
  const DDayPage({super.key});

  static final DateTime targetDate = DateTime(2026, 11, 28);

  int calculateDDay() {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return targetDate.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final dDay = calculateDDay();

    String dDayText;

    if (dDay > 0) {
      dDayText = 'D-$dDay';
    } else if (dDay == 0) {
      dDayText = 'D-Day';
    } else {
      dDayText = 'D+${dDay.abs()}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 D-Day'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '2026년 11월 28일',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              dDayText,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

