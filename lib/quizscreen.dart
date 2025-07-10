import 'dart:async';
import 'package:flutter/material.dart';
import 'models/question.dart';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  const QuizScreen({super.key, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int score = 0;
  int? selectedIndex;
  bool showAnswer = false;

  static const int _questionDuration = 20;
  late Timer _timer;
  int _remainingTime = _questionDuration;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _remainingTime = _questionDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == 0) {
        _nextQuestion(); // auto next if time ends
      } else {
        setState(() => _remainingTime--);
      }
    });
  }

  void _stopTimer() => _timer.cancel();

  void _nextQuestion() {
    _stopTimer();

    if (selectedIndex == widget.questions[currentQuestion].correctIndex) {
      score++;
    }

    if (currentQuestion < widget.questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedIndex = null;
        showAnswer = false;
      });
      _startTimer();
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Quiz Completed!"),
        content: Text("Your score: $score/${widget.questions.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Back to Home"),
          )
        ],
      ),
    );
  }

  void _showHint() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("💡 Hint"),
        content: const Text("Think carefully. Eliminate wrong options.\nYou can add custom hints per question later."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[currentQuestion];
    final isLast = currentQuestion == widget.questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🧠 Quiz"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (currentQuestion + 1) / widget.questions.length,
            backgroundColor: Colors.deepPurple.shade100,
            color: Colors.white,
            minHeight: 4,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "⏱ Time left: $_remainingTime sec",
              style: TextStyle(
                color: _remainingTime <= 5 ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text("Q${currentQuestion + 1}. ${q.question}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...List.generate(q.options.length, (i) {
              Color? tileColor;
              if (showAnswer) {
                if (i == q.correctIndex) tileColor = Colors.green.shade200;
                else if (i == selectedIndex && selectedIndex != q.correctIndex) {
                  tileColor = Colors.red.shade200;
                }
              }

              return Card(
                color: tileColor,
                child: ListTile(
                  title: Text(q.options[i]),   //Option integration
                  leading: Radio<int>(
                    value: i,
                    groupValue: selectedIndex,
                    onChanged: showAnswer
                        ? null
                        : (value) => setState(() => selectedIndex = value),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text("Hint"),
                ),
                ElevatedButton(
                  onPressed: selectedIndex != null && !showAnswer
                      ? () {
                          setState(() => showAnswer = true);
                          Future.delayed(const Duration(seconds: 2), _nextQuestion);
                        }
                      : null,
                  child: Text(isLast ? "Finish" : "Next"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
