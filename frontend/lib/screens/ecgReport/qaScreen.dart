// First, create a model class for Q&A
import 'package:flutter/material.dart';
import 'package:healthy_heart/commonComponents/customAppBar.dart';
import 'package:healthy_heart/models/questions_and_answers.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:share_plus/share_plus.dart';

class ECGQuestionsScreen extends StatelessWidget {
  final List<QuestionsAndAnswers> questionsAndAnswers;
  final double healthScore;
  final String riskLevel;
  final double riskProbability;

  const ECGQuestionsScreen({
    super.key,
    required this.questionsAndAnswers,
    required this.healthScore,
    required this.riskLevel,
    required this.riskProbability,
  });

  Future<void> _generatePDF(BuildContext context) async {
    print("Clicked");
    // Request storage permission
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // If permission is granted, proceed with the PDF generation logic
      print('Storage permission granted');
      // Your code for generating the PDF goes here
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Storage permission is required to save the PDF.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final pdf = pw.Document();
      // Add content to PDF
      pdf.addPage(
        pw.MultiPage(
          build:
              (context) => [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'ECG Analysis Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                // Health Risk Section
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Health Risk Assessment',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Health Score: $healthScore'),
                      pw.Text('Risk Level: $riskLevel'),
                      pw.Text(
                        'Risk Probability: ${riskProbability.toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                // Q&A Section
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Detailed Analysis',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                ...questionsAndAnswers.map(
                  (qa) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Q: ${qa.question}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('A: ${qa.answer}'),
                      pw.SizedBox(height: 10),
                      pw.Divider(),
                    ],
                  ),
                ),
              ],
        ),
      );

      // Save PDF
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        // For iOS, you might want to use the documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Create a unique filename with timestamp
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final file = File('${downloadsDir.path}/ecg_report_$timestamp.pdf');

      await file.writeAsBytes(await pdf.save());

      // Hide loading indicator
      if (context.mounted) Navigator.of(context).pop();

      if (await file.exists()) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Success'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PDF report has been generated successfully.'),
                    const SizedBox(height: 8),
                    Text(
                      'Saved at: ${file.path}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Share.shareXFiles([
                        XFile(file.path),
                      ], text: 'ECG Analysis Report');
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      // Hide loading indicator
      if (context.mounted) Navigator.of(context).pop();

      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Error'),
                ],
              ),
              content: Text('Failed to generate PDF: $e'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'ECG Analysis'),
      body: Column(
        children: [
          // Health Risk Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Health Risk Assessment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRiskIndicator(
                          'Health Score',
                          healthScore.toString(),
                          Colors.blue,
                          Icons.favorite,
                        ),
                        _buildRiskIndicator(
                          'Risk Level',
                          riskLevel,
                          riskLevel == 'High' ? Colors.red : Colors.green,
                          Icons.warning_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Risk Probability: ${riskProbability.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              riskLevel == 'High' ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Q&A List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questionsAndAnswers.length,
              itemBuilder: (context, index) {
                return _buildQuestionCard(questionsAndAnswers[index], context);
              },
            ),
          ),

          // Generate Report Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _generatePDF(context),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicator(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildQuestionCard(QuestionsAndAnswers qa, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showAnswerDialog(context, qa);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qa.question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to see answer',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnswerDialog(BuildContext context, QuestionsAndAnswers qa) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            qa.question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Answer:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                qa.answer,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
