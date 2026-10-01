import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _progressKey = 'concept_review_dates_v1';
const _questionCursorKey = 'concept_question_cursor_v1';
const _sessionCursorPrefix = 'concept_session_cursor_v1_';
const _sessionSize = 5;
const _green = Color(0xFF58CC78);

class _Question {
  _Question({
    required this.id,
    required this.type,
    required this.prompt,
    required this.parts,
    required this.answers,
    required this.options,
    required this.keyPoints,
    required this.explanation,
  });

  final String id;
  final String type;
  final String prompt;
  final List<String> parts;
  final List<String> answers;
  final List<List<String>> options;
  final List<String> keyPoints;
  final String explanation;

  factory _Question.fromJson(Map<String, dynamic> json, String conceptId) {
    final id = json['id'] as String;
    final type = json['type'] as String;
    final prompt = (json['prompt'] as String?) ?? '';
    final parts = ((json['parts'] as List?) ?? []).cast<String>();
    final answers = ((json['answers'] as List?) ?? []).cast<String>();
    final options = ((json['options'] as List?) ?? [])
        .map((row) => (row as List).cast<String>())
        .toList();
    final keyPoints = ((json['keyPoints'] as List?) ?? []).cast<String>();

    const types = {
      'blank_choice',
      'blank_input',
      'name_recall',
      'definition_recall',
      'components',
      'distinguish',
    };

    if (!types.contains(type)) {
      throw FormatException('$conceptId / $id: 알 수 없는 문제 유형: $type');
    }

    if (type == 'blank_choice' || type == 'blank_input') {
      if (answers.isEmpty || parts.length != answers.length + 1) {
        throw FormatException(
          '$conceptId / $id: parts는 빈칸 수보다 1개 많아야 하고 '
          'answers는 빈칸 수만큼 있어야 해요.',
        );
      }
      if (type == 'blank_choice' &&
          (options.length != answers.length ||
              options.any((row) => row.isEmpty))) {
        throw FormatException(
          '$conceptId / $id: 각 빈칸마다 options 목록이 필요해요.',
        );
      }
    } else if (prompt.trim().isEmpty) {
      throw FormatException('$conceptId / $id: prompt가 비어 있어요.');
    }

    if (type == 'name_recall' &&
        ((json['answer'] as String?) ?? '').trim().isEmpty) {
      throw FormatException('$conceptId / $id: answer가 필요해요.');
    }

    if (type == 'components' && answers.isEmpty) {
      throw FormatException('$conceptId / $id: answers가 필요해요.');
    }

    if ((type == 'definition_recall' || type == 'distinguish') &&
        keyPoints.isEmpty) {
      throw FormatException('$conceptId / $id: keyPoints가 필요해요.');
    }

    return _Question(
      id: id,
      type: type,
      prompt: prompt,
      parts: parts,
      answers: type == 'name_recall'
          ? [json['answer'] as String]
          : answers,
      options: options,
      keyPoints: keyPoints,
      explanation: (json['explanation'] as String?) ?? '',
    );
  }
}

class _Concept {
  _Concept({
    required this.id,
    required this.subject,
    required this.unit,
    required this.title,
    required this.explanation,
    required this.questions,
  });

  final String id;
  final String subject;
  final String unit;
  final String title;
  final String explanation;
  final List<_Question> questions;

  factory _Concept.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final rawQuestions = json['questions'] as List;

    if (rawQuestions.isEmpty) {
      throw FormatException('$id: questions가 비어 있어요.');
    }

    return _Concept(
      id: id,
      subject: json['subject'] as String,
      unit: json['unit'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String,
      questions: rawQuestions
          .map((item) =>
              _Question.fromJson(item as Map<String, dynamic>, id))
          .toList(),
    );
  }
}

class _SessionItem {
  _SessionItem(this.concept, this.question, this.isNew);

  final _Concept concept;
  final _Question question;
  final bool isNew;
}

class _StudyData {
  _StudyData(this.items, this.dueCount);

  final List<_SessionItem> items;
  final int dueCount;
}

Future<Map<String, String>> _loadDates() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_progressKey);
  if (saved == null) return {};

  final decoded = jsonDecode(saved) as Map<String, dynamic>;
  return decoded.map(
    (key, value) => MapEntry(key, value as String),
  );
}

Future<_StudyData> _loadStudyData(String? subject) async {
  final text = await rootBundle.loadString(
    'assets/concepts/concepts.json',
  );
  final raw = jsonDecode(text) as List;
  final allConcepts = raw
      .map((item) => _Concept.fromJson(item as Map<String, dynamic>))
      .toList();

  final conceptIds = <String>{};
  final questionIds = <String>{};
  for (final concept in allConcepts) {
    if (!conceptIds.add(concept.id)) {
      throw FormatException('중복된 개념 ID: ${concept.id}');
    }
    for (final question in concept.questions) {
      if (!questionIds.add(question.id)) {
        throw FormatException('중복된 문제 ID: ${question.id}');
      }
    }
  }

  final concepts = subject == null
      ? allConcepts
      : allConcepts.where((c) => c.subject == subject).toList();

  if (concepts.isEmpty) return _StudyData([], 0);

  final dates = await _loadDates();
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final due = <_Concept>[];
  final fresh = <_Concept>[];
  final studied = <_Concept>[];

  for (final concept in concepts) {
    final saved = dates[concept.id];
    if (saved == null) {
      fresh.add(concept);
      continue;
    }

    final date = DateTime.tryParse(saved);
    if (date == null || !date.isAfter(today)) {
      due.add(concept);
    } else {
      studied.add(concept);
    }
  }

  // 복습 예정 → 새 개념 → 이미 배운 개념 순서.
  // 마지막 그룹도 포함해 같은 날 여러 번 세션을 시작할 수 있어요.
  final pool = [...due, ...fresh, ...studied];
  final scope = subject ?? 'all';
  final cursor = prefs.getInt('$_sessionCursorPrefix$scope') ?? 0;

  // 우선 복습/새 개념이 있으면 그쪽부터, 없으면 배운 개념을 순환.
  final priority = [...due, ...fresh];
  final chosen = priority.isNotEmpty
      ? priority.take(_sessionSize).toList()
      : List.generate(
          concepts.length < _sessionSize ? concepts.length : _sessionSize,
          (i) => pool[(cursor + i) % pool.length],
        );

  final items = <_SessionItem>[];
  for (final concept in chosen) {
    final questionCursor =
        prefs.getInt('$_questionCursorKey${concept.id}') ?? 0;
    final question =
        concept.questions[questionCursor % concept.questions.length];
    items.add(_SessionItem(concept, question, !dates.containsKey(concept.id)));
  }

  return _StudyData(items, due.length);
}

class StudyHomePage extends StatefulWidget {
  const StudyHomePage({super.key, this.subject});

  final String? subject;

  @override
  State<StudyHomePage> createState() => _StudyHomePageState();
}

class _StudyHomePageState extends State<StudyHomePage> {
  late Future<_StudyData> _data;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _data = _loadStudyData(widget.subject);
    });
  }

  Future<void> _start(List<_SessionItem> items) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _StudySessionPage(
          items: items,
          subject: widget.subject,
        ),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StudyData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('개념 JSON을 읽지 못했어요.'),
                  const SizedBox(height: 12),
                  SelectableText('${snapshot.error}'),
                  OutlinedButton(
                    onPressed: _refresh,
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

        final data = snapshot.data!;
        final count = data.items.length;

        // 기존 D-day는 main.dart에서 이 위에 표시하므로 여기에는 넣지 않음.
        // ListView라 작은 화면에서도 bottom overflow가 나지 않음.
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            Text(
              widget.subject ?? '오늘의 학습',
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (data.dueCount > 0) ...[
              const SizedBox(height: 8),
              Text('복습할 개념 ${data.dueCount}개'),
            ],
            const SizedBox(height: 40),
            const Center(
              child: Icon(
                Icons.psychology_alt_rounded,
                size: 90,
                color: _green,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              count == 0
                  ? '학습할 개념이 없어요'
                  : '이번 세션은 $count개 개념!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '개념을 이해하고, 문제를 풀고, 기억을 확인해요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                ),
                onPressed: count == 0 ? null : () => _start(data.items),
                child: const Text(
                  '학습 시작',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '완료 후에도 바로 다음 세션을 시작할 수 있어요.',
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class _StudySessionPage extends StatefulWidget {
  const _StudySessionPage({
    required this.items,
    required this.subject,
  });

  final List<_SessionItem> items;
  final String? subject;

  @override
  State<_StudySessionPage> createState() => _StudySessionPageState();
}

class _StudySessionPageState extends State<_StudySessionPage> {
  int _index = 0;
  bool _reading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reading = widget.items.first.isNew;
  }

  Future<void> _finishQuestion(int days) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final item = widget.items[_index];
      final prefs = await SharedPreferences.getInstance();
      final dates = await _loadDates();
      final now = DateTime.now();

      dates[item.concept.id] =
          DateTime(now.year, now.month, now.day + days).toIso8601String();

      final saved = await prefs.setString(_progressKey, jsonEncode(dates));
      if (!saved) throw StateError('학습 기록 저장 실패');

      // 같은 개념을 다음 세션에서 만났을 때 다른 문제를 출제.
      final key = '$_questionCursorKey${item.concept.id}';
      final cursor = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, cursor + 1);

      if (_index == widget.items.length - 1) {
        final scope = widget.subject ?? 'all';
        final cursorKey = '$_sessionCursorPrefix$scope';
        final oldCursor = prefs.getInt(cursorKey) ?? 0;
        await prefs.setInt(cursorKey, oldCursor + widget.items.length);
      }

      if (!mounted) return;
      setState(() {
        _index++;
        _reading = _index < widget.items.length &&
            widget.items[_index].isNew;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장하지 못했어요: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.items.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('학습 완료')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: _green, size: 80),
              const SizedBox(height: 16),
              Text(
                '${widget.items.length}개 개념 학습 완료!',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    final item = widget.items[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('학습 세션')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('${_index + 1} / ${widget.items.length}'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _index / widget.items.length,
            color: _green,
          ),
          const SizedBox(height: 24),
          Text('${item.concept.subject} · ${item.concept.unit}'),
          const SizedBox(height: 8),
          Text(
            item.concept.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          if (_reading) ...[
            const Text(
              '먼저 이해하기',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              item.concept.explanation,
              style: const TextStyle(fontSize: 17, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => setState(() => _reading = false),
              child: const Text('설명 가리고 문제 풀기'),
            ),
          ] else
            _QuestionView(
              // 카드가 바뀔 때 입력 상태도 새로 만들기.
              key: ValueKey('${_index}_${item.question.id}'),
              question: item.question,
              saving: _saving,
              onRated: _finishQuestion,
            ),
        ],
      ),
    );
  }
}

class _QuestionView extends StatefulWidget {
  const _QuestionView({
    super.key,
    required this.question,
    required this.saving,
    required this.onRated,
  });

  final _Question question;
  final bool saving;
  final Future<void> Function(int days) onRated;

  @override
  State<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<_QuestionView> {
  late final List<TextEditingController> _inputs;
  late final List<String?> _choices;
  bool _checked = false;
  int _activeBlank = 0;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    final inputCount = switch (q.type) {
      'blank_input' || 'components' => q.answers.length,
      'name_recall' || 'definition_recall' || 'distinguish' => 1,
      _ => 0,
    };

    _inputs = List.generate(
      inputCount,
      (_) => TextEditingController(),
    );
    _choices = List<String?>.filled(q.answers.length, null);
  }

  @override
  void dispose() {
    for (final input in _inputs) {
      input.dispose();
    }
    super.dispose();
  }

  bool get _allFilled {
    if (widget.question.type == 'blank_choice') {
      return _choices.every((choice) => choice != null);
    }
    return _inputs.every((input) => input.text.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          switch (q.type) {
            'blank_choice' => '빈칸에서 선택하기',
            'blank_input' => '빈칸 직접 채우기',
            'name_recall' => '개념 이름 떠올리기',
            'definition_recall' => '개념 정의하기',
            'components' => '구성요소 쓰기',
            _ => '개념 구별하기',
          },
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (q.type == 'blank_choice' || q.type == 'blank_input')
          _buildInlineBlanks(q)
        else ...[
          Text(
            q.prompt,
            style: const TextStyle(fontSize: 19, height: 1.5),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < _inputs.length; i++) ...[
            TextField(
              controller: _inputs[i],
              enabled: !_checked,
              maxLines: q.type == 'definition_recall' ||
                      q.type == 'distinguish'
                  ? 4
                  : 1,
              decoration: InputDecoration(
                labelText: q.type == 'components'
                    ? '요소 ${i + 1}'
                    : '내 답',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],

        const SizedBox(height: 20),
        if (!_checked && q.type != 'blank_choice')
        FilledButton(
            onPressed: () {
              if (!_allFilled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('답을 먼저 모두 채워주세요.'),
                  ),
                );
                return;
              }
              setState(() => _checked = true);
            },
            child: const Text('답 확인'),
          ),

        if (_checked) ...[
          const Divider(height: 36),
          const Text(
            '핵심 답 · 확인 요소',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (q.keyPoints.isNotEmpty)
            for (final point in q.keyPoints)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $point'),
              )
          else
            for (var i = 0; i < q.answers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  q.answers.length == 1
                      ? q.answers[i]
                      : '${i + 1}. ${q.answers[i]}',
                ),
              ),
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('해설: ${q.explanation}'),
          ],
          const SizedBox(height: 20),
          const Text('내 답과 비교하면 어땠나요?'),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: widget.saving
                ? null
                : () => widget.onRated(1),
            child: const Text('기억 안 남 · 내일 복습'),
          ),
          OutlinedButton(
            onPressed: widget.saving
                ? null
                : () => widget.onRated(3),
            child: const Text('애매함 · 3일 뒤 복습'),
          ),
          FilledButton(
            onPressed: widget.saving
                ? null
                : () => widget.onRated(7),
            child: const Text('설명 가능 · 7일 뒤 복습'),
          ),
        ],
      ],
    );
  }

  Widget _buildInlineBlanks(_Question q) {
  final pieces = <Widget>[];

  for (var i = 0; i < q.parts.length; i++) {
    if (q.parts[i].isNotEmpty) {
      pieces.add(
        Text(
          q.parts[i],
          style: const TextStyle(fontSize: 19, height: 1.7),
        ),
      );
    }

    if (i >= q.answers.length) continue;

    // 문장 안에 표시되는 하얀 빈칸
    if (q.type == 'blank_choice') {
      pieces.add(
        Container(
          constraints: const BoxConstraints(minWidth: 90),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: i == _activeBlank && !_checked
                  ? const Color(0xFF58CC78)
                  : Colors.grey.shade400,
              width: i == _activeBlank && !_checked ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _choices[i] ?? '빈칸 ${i + 1}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _choices[i] == null ? Colors.grey : Colors.black87,
            ),
          ),
        ),
      );
    } else {
      // 기존 입력형 빈칸은 유지
      pieces.add(
        Container(
          width: 115,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: TextField(
            controller: _inputs[i],
            enabled: !_checked,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '빈칸 ${i + 1}',
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      );
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: pieces,
      ),

      // 선택형에만 문제 아래 보기 표시
      if (q.type == 'blank_choice' && !_checked) ...[
        const SizedBox(height: 28),
        Text(
          '빈칸 ${_activeBlank + 1}에 들어갈 말은?',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final option in q.options[_activeBlank])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final blankIndex = _activeBlank;
                  final correctAnswer = q.answers[blankIndex];
                  final isCorrect = option == correctAnswer;

                  setState(() {
                    _choices[blankIndex] = option;
                  });

                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(isCorrect ? '정답이에요! 🎉' : '아쉬워요!'),
                      content: Text(
                        isCorrect
                            ? '빈칸 ${blankIndex + 1}의 정답은 "$correctAnswer"예요.'
                            : '선택한 답: $option\n정답: $correctAnswer',
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            blankIndex == q.answers.length - 1
                                ? '결과 보기'
                                : '다음 빈칸',
                          ),
                        ),
                      ],
                    ),
                  );

                  if (!mounted) return;

                  setState(() {
                    if (blankIndex == q.answers.length - 1) {
                      _checked = true;
                    } else {
                      _activeBlank = blankIndex + 1;
                    }
                  });
                },
                child: Text(
                  option,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
      ],

      if (q.type == 'blank_choice' && _checked)
        const Text(
          '모든 빈칸을 풀었어요. 아래에서 핵심 답과 해설을 확인해 주세요.',
          style: TextStyle(color: Colors.black54),
        ),
    ],
  );
}
}
