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
  int countdown = 15;

  Set<String> answeredUsers = {};
  List<String> teamMembers = [];
  Map<String, int> scores = {}; // userId -> score

  @override
  void initState() {
    super.initState();
    _fetchTeamMembers();
    startCountdown();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    countdownTimer?.cancel();
    countdown = 15;
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

    final sessionDoc = FirebaseFirestore.instance.collection('sessions').doc(widget.teamCode);
    final sessionSnapshot = await sessionDoc.get();

    Map<String, dynamic> data = {};
    if (sessionSnapshot.exists && sessionSnapshot.data() != null) {
      data = sessionSnapshot.data()! as Map<String, dynamic>;
    }

    final currentQuestion = questions.isNotEmpty && currentIndex < questions.length
        ? questions[currentIndex]
        : null;

    // Get current scores or initialize empty
    Map<String, dynamic> currentScores = {};
    if (data.containsKey('scores')) {
      currentScores = Map<String, dynamic>.from(data['scores']);
    }

    int previousScore = currentScores[widget.userId] ?? 0;
    int newScore = previousScore;

    // Increase score if answer is correct
    if (currentQuestion != null && index == currentQuestion.correctIndex) {
      newScore += 1;
    }
    currentScores[widget.userId] = newScore;

    // Update answers and scores atomically in Firestore
    await sessionDoc.set({
      'answers': {widget.userId: index},
      'scores': currentScores,
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
      countdown = 15;
      answeredUsers.clear();
    });

    startCountdown();
  }

  bool get allAnswered {
    return teamMembers.isNotEmpty && answeredUsers.length >= teamMembers.length;
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

          if (!data.containsKey('questions') || data['questions'] == null || data['questions'].isEmpty) {
            return const Center(child: Text("Waiting for host to start quiz..."));
          }

          final questionsData = data['questions'] as List<dynamic>;
          questions = questionsData
              .map((q) => Question.fromMap(q as Map<String, dynamic>))
              .toList();

          currentIndex = data['currentIndex'] ?? 0;

          if (currentIndex >= questions.length) {
            // Show final scoreboard after quiz completion
            final finalScores = Map<String, dynamic>.from(data['scores'] ?? {});
            return Scaffold(
              appBar: AppBar(title: const Text("Quiz Completed!")),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("Quiz completed!", style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: teamMembers.map((memberId) {
                          final score = finalScores[memberId] ?? 0;
                          return ListTile(
                            title: Text("User: $memberId"),
                            trailing: Text("Score: $score"),
                          );
                        }).toList(),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Exit"),
                    ),
                  ],
                ),
              ),
            );
          }

          final question = questions[currentIndex];

          final answersMap = Map<String, dynamic>.from(data['answers'] ?? {});
          answeredUsers = answersMap.keys.toSet();

          if (answersMap.containsKey(widget.userId)) {
            selectedOptionIndex = answersMap[widget.userId];
            answered = true;
          } else {
            selectedOptionIndex = null;
            answered = false;
          }

          // Get scores for showing scoreboard
          final scoresData = Map<String, dynamic>.from(data['scores'] ?? {});
          scores = scoresData.map((key, value) => MapEntry(key, (value as int)));

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question info and timer
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
                // Options
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
                // Next Question button for host only
                if (widget.isHost && currentIndex < questions.length - 1)
                  ElevatedButton(
                    onPressed: allAnswered ? _goToNextQuestion : null,
                    child: Text(allAnswered
                        ? "Next Question"
                        : "Waiting for all members to answer"),
                  ),

                const Divider(height: 32),

                // Scoreboard
                Text("Scoreboard:", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: teamMembers.map((memberId) {
                      final score = scores[memberId] ?? 0;
                      return ListTile(
                        title: Text("User: $memberId"),
                        trailing: Text("Score: $score"),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
