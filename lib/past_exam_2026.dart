import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PastExam2026Page extends StatelessWidget {
  const PastExam2026Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2026년 전문상담 전공 A'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SfPdfViewer.asset(
        'assets/exams/2026_전문상담_2교시_전공A.pdf',
      ),
    );
  }
}

