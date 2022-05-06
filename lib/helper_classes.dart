enum QuestionType {
  kNumber, kString
}

class Question {
  final QuestionType type;
  final String label;
  final List<String> options;

  const Question({
    required this.type,
    required this.label,
    required this.options,
  });
}

class Answer {
  QuestionType type;
  String response;

  Answer({
    required this.type,
    required this.response,
  });
}