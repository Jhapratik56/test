import 'models/question.dart';

class QuizParser {
  static List<Question> parseMCQs(String rawText) {
    final List<Question> questions = [];

    // Split by lines that start with number and dot (e.g., 1. 2. 3.)
    final blocks = rawText.split(RegExp(r"\n(?=\d+\.)"));

    for (var block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 6) continue; // question + 4 options + answer

      final questionLine = lines[0];
      final optionLines = lines.sublist(1, 5);
      final answerLine = lines[5];

      // Remove '1. ', '2. ', etc.
      final questionText = questionLine.replaceFirst(RegExp(r"^\d+\.\s*"), "");

      final options = optionLines.map((line) {
        return line.replaceFirst(RegExp(r"^[A-Da-d]\.\s*"), "").trim();
      }).toList();

      // Find the correct index
      final answerMatch = RegExp(r"Answer:\s*([A-Da-d])").firstMatch(answerLine);
      if (answerMatch == null) continue;
      final correctLetter = answerMatch.group(1)!.toUpperCase();
      final correctIndex = correctLetter.codeUnitAt(0) - 'A'.codeUnitAt(0);

      if (options.length == 4 && correctIndex >= 0 && correctIndex < 4) {
        questions.add(Question(
          question: questionText,
          options: options,
          correctIndex: correctIndex,
        ));
      }
    }

    return questions;
  }
}
