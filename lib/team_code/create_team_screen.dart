import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_khel/models/question.dart';
import 'package:quiz_khel/QuizParser.dart';
import 'package:quiz_khel/services/a4fservice.dart';
import 'package:quiz_khel/imagepickerservice.dart';
import 'package:quiz_khel/textrecognitionservice.dart';
import 'package:quiz_khel/team_code/shared_quiz_screen.dart';
import 'team_code_service.dart';

class CreateTeamScreen extends StatefulWidget {
  final String userId;

  const CreateTeamScreen({super.key, required this.userId});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final TeamService _teamService = TeamService();
  final A4FService _a4fService = A4FService();
  final ImagePickerService _imagePicker = ImagePickerService();
  final TextRecognitionService _textRecognizer = TextRecognitionService();

  String? _teamCode;
  bool _loading = false;

  Future<void> _createTeam() async {
    setState(() => _loading = true);

    try {
      final code = await _teamService.createTeam(widget.userId);
      setState(() => _teamCode = code);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating team: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _createTeam();
  }

  Future<void> _scanAndStartQuiz() async {
    final image = await _imagePicker.pickImageFromGallery();
    if (image == null || _teamCode == null) return;

    setState(() => _loading = true);

    try {
      final extractedText = await _textRecognizer.recognizeTextFromImage(image);
      final rawMCQs = await _a4fService.generateMCQs(extractedText);
      final questions = QuizParser.parseMCQs(rawMCQs);

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid questions generated.')),
        );
        return;
      }

      // Fetch current team members from 'teams' collection
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(_teamCode)
          .get();

      final List<dynamic> members = teamDoc.exists && teamDoc.data()!.containsKey('members')
          ? List<dynamic>.from(teamDoc.data()!['members'])
          : [widget.userId];

      // Save to Firestore sessions collection with members & answers map
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(_teamCode)
          .set({
        'questions': questions.map((q) => q.toMap()).toList(),
        'currentIndex': 0,
        'started': true,
        'members': members,
        'answers': {}, // empty map to track user answers later
      });

      // Navigate to Shared Quiz Screen (host)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SharedQuizScreen(
            teamCode: _teamCode!,
            isHost: true, userId: '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Team')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _teamCode != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Team Code:', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      SelectableText(
                        _teamCode!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Scan & Start Quiz'),
                        onPressed: _scanAndStartQuiz,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, _teamCode),
                        child: const Text('Done'),
                      )
                    ],
                  )
                : const Text('Press button to create team'),
      ),
    );
  }
}
