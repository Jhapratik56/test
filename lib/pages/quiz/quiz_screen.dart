import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:quiz_khel/controllers/quiz_controllers.dart';
import 'package:quiz_khel/models/question.dart';
import 'package:quiz_khel/pages/quiz/elevated_button.dart';
import 'package:quiz_khel/pages/quiz/progress_bar.dart';
import 'package:quiz_khel/pages/quiz/question_card.dart';
import 'package:quiz_khel/utils/screen_size.dart';

class QuizScreen extends StatelessWidget {
  final List<Question> questions;  // Receive questions via constructor

  const QuizScreen({super.key, required this.questions});

  @override
  Widget build(BuildContext context) {
    screenSize.init(context: context);
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Screen", style: TextStyle(color: Colors.white),), backgroundColor: Colors.indigo,leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios)),),
      body: GetBuilder<QuestionController>(
        // Pass questions to controller on initialization
        init: QuestionController(questions: questions),
        builder: (_questionController) {
          return Column(
            children: [
              SizedBox(
                height: screenSize.screenHeight * 0.76,
                child: Stack(
                  children: [
                    Container(
                      height: screenSize.screenHeight * .23,
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ProgressBar(),
                          const SizedBox(height: 15),
                          Text.rich(
                            TextSpan(
                              text: "Question ${_questionController.questionNumber}",
                              style: const TextStyle(fontSize: 30, color: Colors.white),
                              children: [
                                TextSpan(
                                  text: "/${_questionController.questions.length}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: screenSize.screenWidth * 0.1 / 2,
                      child: Container(
                        height: screenSize.screenHeight * 0.6,
                        width: screenSize.screenWidth * 0.9,
                        child: QuestionCard(
                          question: _questionController
                              .questions[_questionController.questionNumber.value - 1],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons Row
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _questionController.isAnswered
                        ? ElevatedButtonWidget(
                            color: Theme.of(context).colorScheme.primary,
                            action: _questionController.nextQuestion,
                            title: 'NEXT',
                            textColor: Colors.white,
                          )
                        : ElevatedButtonWidget(
                            color: Theme.of(context).colorScheme.secondary,
                            action: _questionController.skipQuestion,
                            title: 'SKIP',
                            textColor: Colors.indigo.shade900,
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
