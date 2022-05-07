enum QuestionType {
  kNumber, kNumberInc, kString, kSelect, kCheckbox
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
