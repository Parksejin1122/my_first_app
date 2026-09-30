import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PastExamPdfPage extends StatelessWidget {
  const PastExamPdfPage({
    super.key,
    required this.year,
    required this.subject,
  });

  final int year;
  final String subject; // 'A' 또는 'B'

  @override
  Widget build(BuildContext context) {
    final assetPath =
        'assets/exams/${year}_중등1차_전문상담_전공$subject.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text('$year년 전문상담 전공 $subject'),
      ),
      body: SfPdfViewer.asset(assetPath),
    );
  }
}
class EducationExamPdfPage extends StatelessWidget {
  const EducationExamPdfPage({
    super.key,
    required this.year,
  });

  final int year;

  @override
  Widget build(BuildContext context) {
    final assetPath = 'assets/exams/${year}_중등1차_교육학.pdf';

    return Scaffold(
      appBar: AppBar(title: Text('$year년 교육학')),
      body: SfPdfViewer.asset(assetPath),
    );
  }
}