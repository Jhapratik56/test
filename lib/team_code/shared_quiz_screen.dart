import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quiz_khel/models/question.dart';

class SharedQuizScreen extends StatefulWidget {
  final String teamCode;
  final bool isHost;
  final String userId;

  const SharedQuizScreen({
    Key? key,
    required this.teamCode,
    required this.isHost,
    required this.userId,
  }) : super(key: key);

  @override
  State<SharedQuizScreen> createState() => _SharedQuizScreenState();
}

class _SharedQuizScreenState extends State<SharedQuizScreen> {
  List<Question> questions = [];
  int currentIndex = 0;
  int? selectedOptionIndex;
  bool answered = false;
  Timer? countdownTimer;
  int countdown = 20;

  Set<String> answeredUsers = {};
  List<String> teamMembers = [];

  @override
  void initState() {
    super.initState();
    startCountdown();
    _fetchTeamMembers();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    countdownTimer?.cancel();
    countdown = 20;
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown == 0) {
        timer.cancel();
        if (widget.isHost && currentIndex < questions.length - 1) {
          _goToNextQuestion();
        }
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  Future<void> _fetchTeamMembers() async {
    final doc = await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamCode)
        .get();

    if (doc.exists && doc.data() != null) {
      setState(() {
        teamMembers = List<String>.from(doc['members'] ?? []);
      });
    }
  }

  Future<void> _selectOption(int index) async {
    if (answered) return;

    setState(() {
      selectedOptionIndex = index;
      answered = true;
    });

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.teamCode)
        .set({
      'answers': {widget.userId: index}
    }, SetOptions(merge: true));
  }

  Future<void> _goToNextQuestion() async {
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.teamCode)
        .update({
      'currentIndex': currentIndex + 1,
      'answers': {},
    });

    setState(() {
      selectedOptionIndex = null;
      answered = false;
      countdown = 20;
      answeredUsers.clear();
    });

    startCountdown();
  }

  bool get allAnswered {
    return teamMembers.isNotEmpty &&
        answeredUsers.length >= teamMembers.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team: ${widget.teamCode}'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.teamCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists || doc.data() == null) {
            return const Center(child: Text("Waiting for host to start quiz..."));
          }

          final data = doc.data() as Map<String, dynamic>;

          if (data['questions'] == null || data['questions'].isEmpty) {
            return const Center(child: Text("No questions found."));
          }

          final questionsData = data['questions'] as List<dynamic>;
          questions = questionsData
              .map((q) => Question.fromMap(q as Map<String, dynamic>))
              .toList();

          currentIndex = data['currentIndex'] ?? 0;

          if (currentIndex >= questions.length) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Quiz completed!", style: TextStyle(fontSize: 24)),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Exit"),
                  ),
                ],
              ),
            );
          }

          final question = questions[currentIndex];

          // Read who has answered
          final answersMap = Map<String, dynamic>.from(data['answers'] ?? {});
          answeredUsers = answersMap.keys.toSet();

          if (answersMap.containsKey(widget.userId)) {
            selectedOptionIndex = answersMap[widget.userId];
            answered = true;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Q${currentIndex + 1} / ${questions.length}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Time: $countdown s",
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.question,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...List.generate(question.options.length, (i) {
                  final option = question.options[i];
                  final isSelected = selectedOptionIndex == i;
                  final isCorrect = i == question.correctIndex;

                  Color? tileColor;
                  if (answered) {
                    if (isSelected && isCorrect) {
                      tileColor = Colors.green[300];
                    } else if (isSelected && !isCorrect) {
                      tileColor = Colors.red[300];
                    } else if (!isSelected && isCorrect) {
                      tileColor = Colors.green[100];
                    }
                  }

                  return Card(
                    color: tileColor,
                    child: ListTile(
                      title: Text(option),
                      leading: Radio<int>(
                        value: i,
                        groupValue: selectedOptionIndex,
                        onChanged: answered ? null : (val) => _selectOption(val!),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                if (widget.isHost && currentIndex < questions.length - 1)
                  ElevatedButton(
                    onPressed: allAnswered ? _goToNextQuestion : null,
                    child: Text(allAnswered
                        ? "Next Question"
                        : "Waiting for all members to answer"),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
