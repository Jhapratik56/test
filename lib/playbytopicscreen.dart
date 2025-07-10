import 'package:flutter/material.dart';
import 'A4FService.dart';
import 'QuizParser.dart';
import 'models/question.dart';
import 'QuizScreen.dart';

class PlayByTopicScreen extends StatefulWidget {
  const PlayByTopicScreen({super.key});

  @override
  State<PlayByTopicScreen> createState() => _PlayByTopicScreenState();
}

class _PlayByTopicScreenState extends State<PlayByTopicScreen> {
  final TextEditingController _topicController = TextEditingController();
  final A4FService _a4fService = A4FService();

  bool loading = false;
  List<Question> questions = [];

  void _generateMCQs() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a topic")),
      );
      return;
    }

    setState(() {
      loading = true;
      questions = [];
    });

    try {
      final rawMCQs = await _a4fService.generateMCQs(topic);
      questions = QuizParser.parseMCQs(rawMCQs);

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No questions generated for this topic.")),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(questions: questions),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Play by Topic")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: "Enter topic",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _generateMCQs,
                    child: const Text("Generate Quiz"),
                  ),
          ],
        ),
      ),
    );
  }
}
