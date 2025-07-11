import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quiz_khel/QuizParser.dart';
import 'package:quiz_khel/models/question.dart';
import 'package:quiz_khel/imagepickerservice.dart';
import 'package:quiz_khel/textrecognitionservice.dart';
import 'package:quiz_khel/pdf_text_extractor.dart';
import 'package:quiz_khel/pdf_picker_service.dart';
import 'package:quiz_khel/services/a4fservice.dart';

import 'package:quiz_khel/pages/quiz/quiz_screen.dart';
import 'package:quiz_khel/playbytopicscreen.dart';
import 'package:quiz_khel/widgets/drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final A4FService _a4fService = A4FService();
  final ImagePickerService _imagePicker = ImagePickerService();
  final TextRecognitionService _textRecognizer = TextRecognitionService();

  String username = "User";
  bool loading = false;
  List<Question> questions = [];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('username')) {
        setState(() {
          username = doc['username'];
        });
      }
    }
  }

  Future<void> _processImage(bool fromCamera) async {
    final image = fromCamera
        ? await _imagePicker.pickImageFromCamera()
        : await _imagePicker.pickImageFromGallery();

    if (image == null) return;

    setState(() => loading = true);

    try {
      final extractedText = await _textRecognizer.recognizeTextFromImage(image);
      final rawMCQs = await _a4fService.generateMCQs(extractedText);
      questions = QuizParser.parseMCQs(rawMCQs);

      if (questions.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(questions: questions)));
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(questions: questions)));
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

  void _showTeamOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Team Options", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Create Team"),
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateTeamDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.group_add),
                label: const Text("Join Team"),
                onPressed: () {
                  Navigator.pop(context);
                  _showJoinTeamDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateTeamDialog() {
    final _teamNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Team"),
        content: TextField(
          controller: _teamNameController,
          decoration: const InputDecoration(
            labelText: "Team Name",
            hintText: "Enter a team name",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Create"),
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar("Team '${_teamNameController.text}' created.");
              // TODO: Add Firestore logic
            },
          ),
        ],
      ),
    );
  }

  void _showJoinTeamDialog() {
    final _teamCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join Team"),
        content: TextField(
          controller: _teamCodeController,
          decoration: const InputDecoration(
            labelText: "Team Code",
            hintText: "Enter team code to join",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Join"),
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar("Joined team with code '${_teamCodeController.text}'");
              // TODO: Add Firestore logic
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Khel")),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTeamOptions,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.group),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Hello, $username 👋',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                    ),
                    const SizedBox(height: 40),

                    // Categories
                    Text(
                      'Quiz by Category',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryCard('Science', Icons.science),
                          _buildCategoryCard('History', Icons.history_edu),
                          _buildCategoryCard('Math', Icons.calculate),
                          _buildCategoryCard('Literature', Icons.menu_book),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Upload section
                    Text(
                      'Scan Image for Quiz',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildUploadButton(
                            'Pick from Gallery',
                            Icons.photo_library,
                            () => _processImage(false),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildUploadButton(
                            'Take a Photo',
                            Icons.camera_alt,
                            () => _processImage(true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildUploadButton(
                            'Upload PDF',
                            Icons.picture_as_pdf,
                            _processPDF,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildUploadButton(
                            'Play by Topic',
                            Icons.topic,
                            () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayByTopicScreen()));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSnackBar("Coming soon: $title quiz!"),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.indigo, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.indigo,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: Colors.indigo.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}