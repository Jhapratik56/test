import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_khel/models/question.dart';
import 'package:quiz_khel/pages/quiz/score_screen.dart';

class QuestionController extends GetxController
    with GetTickerProviderStateMixin {
  final List<Question> questions;
  QuestionController({required this.questions});

  late AnimationController _animationController;
  late Animation _animation;

  Animation get animation => _animation;

  final RxInt _questionNumber = 1.obs;
  RxInt get questionNumber => _questionNumber;

  bool _isAnswered = false;
  bool get isAnswered => _isAnswered;

  late int _correctAns;
  int get correctAns => _correctAns;

  int? _selectedAns;
  int get selectedAns => _selectedAns ?? -1;

  int _score = 0;
  int get score => _score;

  int _totalNumber = 0;
  int get totalNumber => _totalNumber;

  late RxInt _skipNumber = 0.obs;
  RxInt get skipNumber => _skipNumber;

  int get numOfCorrectAns => _score;

  @override
  void onInit() {
    super.onInit();

    _animationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        update();
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!_isAnswered) {
            skipQuestion(); // only skip if no answer
          }
        }
      });

    startTimer();
  }

  void startTimer() {
    _animationController.reset();
    _animationController.forward();
  }

  void checkAns(Question question, int selectedIndex) {
    if (_isAnswered) return;

    _isAnswered = true;
    _correctAns = question.correctIndex;
    _selectedAns = selectedIndex;

    if (_selectedAns == _correctAns) {
      _score++;
    }

    _animationController.stop();
    update();

    Future.delayed(const Duration(seconds: 2), () {
      nextQuestion();
    });
  }

  void nextQuestion() {
    if (_questionNumber.value >= questions.length) {
      _animationController.stop();
      Get.off(() => const ScoreScreen()); // replace route instead of stacking
      return;
    }

    _isAnswered = false;
    _selectedAns = null;
    _correctAns = -1;

    _questionNumber.value++;
    _totalNumber++;

    startTimer();
    update();
  }

  void skipQuestion() {
    if (_isAnswered) return;
    _isAnswered = true;
    _selectedAns = null;
    _correctAns = -1;
    _skipNumber.value++;
    nextQuestion();
  }

  @override
  void onClose() {
    _animationController.dispose();
    super.onClose();
  }
}
