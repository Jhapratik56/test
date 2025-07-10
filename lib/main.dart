import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'QuizScreen.dart';
import 'QuizParser.dart';
import 'models/question.dart';
import 'A4FService.dart';
import 'imagepickerservice.dart';
import 'TextRecognitionService.dart';
import 'playbytopicscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Khel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(), // <-- Direct to HomePage
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final A4FService _a4fService = A4FService();
  final ImagePickerService _imagePicker = ImagePickerService();
  final TextRecognitionService _textRecognizer = TextRecognitionService();

  String extractedText = '';
  List<Question> questions = [];
  bool loading = false;

  Future<void> _processImage(bool fromCamera) async {
    final image = fromCamera
        ? await _imagePicker.pickImageFromCamera()
        : await _imagePicker.pickImageFromGallery();

    if (image == null) return;

    setState(() => loading = true);

    try {
      extractedText = await _textRecognizer.recognizeTextFromImage(image);
      final rawMCQs = await _a4fService.generateMCQs(extractedText);
      questions = QuizParser.parseMCQs(rawMCQs);

      if (questions.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(questions: questions),
          ),
        );
      } else {
        _showSnackBar("No valid questions generated.");
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      setState(() => loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan to Quiz")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _processImage(false),
                    icon: const Icon(Icons.image),
                    label: const Text("Pick from Gallery"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _processImage(true),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Pick from Camera"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlayByTopicScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.topic),
                    label: const Text("Play by Topic"),
                  ),
                ],
              ),
      ),
    );
  }
}
