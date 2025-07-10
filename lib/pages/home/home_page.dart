import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quiz_khel/QuizParser.dart';
import 'package:quiz_khel/QuizScreen.dart';
import 'package:quiz_khel/a4fservice.dart';
import 'package:quiz_khel/imagepickerservice.dart';
import 'package:quiz_khel/models/question.dart';
import 'package:quiz_khel/playbytopicscreen.dart';
import 'package:quiz_khel/textrecognitionservice.dart';
import 'package:quiz_khel/pdf_text_extractor.dart';
import 'package:quiz_khel/pdf_picker_service.dart';
// import 'package:quiz_khel/team_code_screen.dart'; // Create this screen separately

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

  Future<void> _processPDF() async {
  final pdfFile = await PDFPickerService().pickPDF();
  if (pdfFile == null) return;

  setState(() => loading = true);

  try {
    final text = await PDFTextExtractor().extractText(pdfFile);

    if (text.trim().isEmpty) {
      _showSnackBar("No text found in the PDF.");
      return;
    }

    final rawMCQs = await _a4fService.generateMCQs(text);
    final questions = QuizParser.parseMCQs(rawMCQs);

    if (questions.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuizScreen(questions: questions)),
      );
    } else {
      _showSnackBar("No MCQs generated from this PDF.");
    }
  } catch (e) {
    _showSnackBar("Error: ${e.toString()}");
  } finally {
    setState(() => loading = false);
  }
}


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan to Quiz")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
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
                      onPressed: _processPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Upload PDF"),
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
                    //const SizedBox(height: 16),
                   /* ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TeamCodeScreen(), // You must create this screen
                          ),
                        );
                      },
                      icon: const Icon(Icons.group),
                      label: const Text("Join with Team Code"),
                    // ),*/
                  ],
                ),
              ),
      ),
    );
  }
}
