/// Enum for limiting possible question types
enum QuestionType {
  kNumber, kNumberInc, kString, kSelect, kCheckbox
}

/// A question in our scouting
class Question {
  final QuestionType type;
  /// the actual question
  final String label;
  /// any applicable options e.g. selectable values
  final List<String> options;

  /// const constructor for a question, requiring all information
  const Question({
    required this.type,
    required this.label,
    required this.options,
  });

  /// load a question from json
  Question.fromJson(Map<String, dynamic> json)
      : type = QuestionType.values[json['type']],
        label = json['label'],
        options = json['options'].cast<String>(); //map((e) => e.toString()).toList();
}


