import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'study_home_page.dart';

class StudySubjectPage extends StatefulWidget {
  const StudySubjectPage({super.key});

  @override
  State<StudySubjectPage> createState() => _StudySubjectPageState();
}

class _StudySubjectPageState extends State<StudySubjectPage> {
  // 기출 과목별 탭과 동일한 과목명·순서·이모지
  static const subjects = <(String, String)>[
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

  late Future<Map<String, int>> _subjectCounts;

  @override
  void initState() {
    super.initState();
    _subjectCounts = _loadSubjectCounts();
  }

  Future<Map<String, int>> _loadSubjectCounts() async {
    final text = await rootBundle.loadString(
      'assets/concepts/concepts.json',
    );
    final decoded = jsonDecode(text) as List<dynamic>;

    final counts = <String, int>{};

    for (final item in decoded) {
      final concept = item as Map<String, dynamic>;
      final subject = concept['subject'] as String;
      counts[subject] = (counts[subject] ?? 0) + 1;
    }

    return counts;
  }

  void _retry() {
    setState(() {
      _subjectCounts = _loadSubjectCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _subjectCounts,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('개념 파일을 읽지 못했어요.'),
                  const SizedBox(height: 8),
                  SelectableText('${snapshot.error}'),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _retry,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final counts = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          children: [
            const Text(
              '과목별 학습',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text('공부할 과목을 선택해 주세요.'),
            const SizedBox(height: 24),

            for (final (subject, emoji) in subjects)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    (counts[subject] ?? 0) == 0
                        ? '개념 준비 중'
                        : '개념 ${counts[subject]}개',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: (counts[subject] ?? 0) > 0,
                  onTap: (counts[subject] ?? 0) == 0
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(title: Text(subject)),
                                body: StudyHomePage(subject: subject),
                              ),
                            ),
                          );
                        },
                ),
              ),
          ],
        );
      },
    );
  }
}
