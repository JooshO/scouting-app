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

  Question.fromJson(Map<String, dynamic> json)
      : type = QuestionType.values[json['type']],
        label = json['label'],
        options = json['options'].cast<String>(); //map((e) => e.toString()).toList();
}


