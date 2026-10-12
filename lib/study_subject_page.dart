import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StudySubjectPage extends StatefulWidget {
  const StudySubjectPage({super.key});

  @override
  State<StudySubjectPage> createState() => _StudySubjectPageState();
}

class _StudySubjectPageState extends State<StudySubjectPage> {
  // 기존 기출 과목별 탭과 동일한 이름·순서·이모지
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

  late Future<List<Map<String, dynamic>>> _concepts;

  @override
  void initState() {
    super.initState();
    _concepts = _loadConcepts();
  }

  Future<List<Map<String, dynamic>>> _loadConcepts() async {
    final text = await rootBundle.loadString(
      'assets/concepts/concepts.json',
    );

    // 현재 프로젝트의 JSON 최상위 형식은 배열: [ {...}, {...} ]
    final decoded = jsonDecode(text) as List<dynamic>;

    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  void _openPage(String title, Widget body) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _concepts,
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
                    onPressed: () {
                      setState(() => _concepts = _loadConcepts());
                    },
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

        final concepts = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          children: [
            const Text(
              '과목별 학습',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('과목 → 단원 → 개념을 선택해 주세요.'),
            const SizedBox(height: 24),
            for (final (subject, emoji) in subjects)
              Builder(
                builder: (context) {
                  final subjectConcepts = concepts
                      .where((c) => c['subject'] == subject)
                      .toList();

                  return Card(
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
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        subjectConcepts.isEmpty
                            ? '개념 준비 중'
                            : '개념 ${subjectConcepts.length}개',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: subjectConcepts.isNotEmpty,
                      onTap: subjectConcepts.isEmpty
                          ? null
                          : () => _openPage(
                                subject,
                                _UnitList(
                                  subject: subject,
                                  concepts: subjectConcepts,
                                ),
                              ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _UnitList extends StatelessWidget {
  const _UnitList({
    required this.subject,
    required this.concepts,
  });

  final String subject;
  final List<Map<String, dynamic>> concepts;

  @override
  Widget build(BuildContext context) {
    // JSON에 처음 등장하는 단원 순서를 유지한다.
    final units = <String, List<Map<String, dynamic>>>{};

    for (final concept in concepts) {
      final unit = concept['unit'] as String;
      units.putIfAbsent(unit, () => []).add(concept);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '$subject의 단원',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        for (final entry in units.entries)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('개념 ${entry.value.length}개'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(entry.key)),
                      body: _ConceptList(
                        subject: subject,
                        unit: entry.key,
                        concepts: entry.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConceptList extends StatelessWidget {
  const _ConceptList({
    required this.subject,
    required this.unit,
    required this.concepts,
  });

  final String subject;
  final String unit;
  final List<Map<String, dynamic>> concepts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '$subject > $unit',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        for (final concept in concepts)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                concept['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: Text(concept['title'] as String),
                      ),
                      body: _ConceptDetail(concept: concept),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConceptDetail extends StatelessWidget {
  const _ConceptDetail({required this.concept});

  final Map<String, dynamic> concept;

  String _questionText(Map<String, dynamic> question) {
    final type = question['type'] as String;

    if (type == 'blank_choice' || type == 'blank_input') {
      final parts = (question['parts'] as List).cast<String>();
      final buffer = StringBuffer();

      for (var i = 0; i < parts.length; i++) {
        buffer.write(parts[i]);
        if (i < parts.length - 1) buffer.write('【   】');
      }

      return buffer.toString();
    }

    return (question['prompt'] as String?) ?? '';
  }

  String _answerText(Map<String, dynamic> question) {
    final answer = question['answer'];
    if (answer is String) return answer;

    final answers = question['answers'];
    if (answers is List) {
      return answers.map((item) => item.toString()).join(' / ');
    }

    final keyPoints = question['keyPoints'];
    if (keyPoints is List) {
      return keyPoints.map((item) => item.toString()).join('\n');
    }

    return '답이 등록되지 않았어요.';
  }

  @override
  Widget build(BuildContext context) {
    final questions = (concept['questions'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${concept['subject']} > ${concept['unit']}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Text(
          concept['title'] as String,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),

        // 먼저 본문 카드 표시
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              concept['explanation'] as String,
              style: const TextStyle(fontSize: 17, height: 1.65),
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text(
          '연습 문제 ${questions.length}개',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text('문제를 눌러 핵심 답을 확인하세요.'),
        const SizedBox(height: 12),

        for (var i = 0; i < questions.length; i++)
          Card(
            key: ValueKey(questions[i]['id']),
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              title: Text(
                '${i + 1}. ${_questionText(questions[i])}',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '핵심 답',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                SelectableText(_answerText(questions[i])),
                if ((questions[i]['explanation'] as String?)?.isNotEmpty ??
                    false) ...[
                  const SizedBox(height: 12),
                  SelectableText(
                    questions[i]['explanation'] as String,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
