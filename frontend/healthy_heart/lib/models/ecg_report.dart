class QA {
  final String question;
  final String answer;

  QA({required this.question, required this.answer});

  factory QA.fromJson(Map<String, dynamic> json) {
    return QA(
      question: json['question'],
      answer: json['answer'],
    );
  }
}

class ECGReport {
  final String id;
  final String filename;
  final String path;
  final String timestamp;
  final String description;
  final List<QA> questionsAndAnswers;

  ECGReport({
    required this.id,
    required this.filename,
    required this.path,
    required this.timestamp,
    required this.description,
    required this.questionsAndAnswers,
  });

  factory ECGReport.fromJson(Map<String, dynamic> json) {
    return ECGReport(
      id: json['id'],
      filename: json['filename'],
      path: json['path'],
      timestamp: json['timestamp'],
      description: json['description'],
      questionsAndAnswers: (json['questions_and_answers'] as List)
          .map((qa) => QA.fromJson(qa))
          .toList(),
    );
  }
}
