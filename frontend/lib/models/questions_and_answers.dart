class QuestionsAndAnswers {
  final String question;
  final String answer;

  QuestionsAndAnswers({
    required this.question,
    required this.answer,
  });

  factory QuestionsAndAnswers.fromJson(Map<String, dynamic> json) {
    return QuestionsAndAnswers(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}
