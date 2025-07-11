class Question {
  final String question;
  final List<String> options;
  final int correctIndex;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  // ✅ Convert to map (for Firestore)
  Map<String, dynamic> toMap() => {
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
  };

  // ✅ Convert from Firestore map
  factory Question.fromMap(Map<String, dynamic> map) => Question(
    question: map['question'],
    options: List<String>.from(map['options']),
    correctIndex: map['correctIndex'],
  );
}
