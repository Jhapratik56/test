import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:quiz_khel/controllers/quiz_controllers.dart';
import 'package:quiz_khel/models/question.dart';
import 'package:quiz_khel/pages/quiz/option.dart';
import 'package:quiz_khel/utils/screen_size.dart';

class QuestionCard extends StatelessWidget {
  QuestionCard({
    super.key,
    required this.question,
  });

  final Question question;

QuestionController _controller = Get.find<QuestionController>();

  @override
  Widget build(BuildContext context) {
    screenSize.init(context: context);
    return Container(
      // margin: EdgeInsets.symmetric(horizontal: 5),

      child: Column(
        children: [
          Container(
            width: screenSize.screenWidth,
            height: 150,
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    spreadRadius: 3,
                    color: Colors.grey.withOpacity(.4))
              ],
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                question.question,
                style: TextStyle(
                    color: Colors.indigo.shade900,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          SizedBox(height: 7.5),
          Expanded(
            child: ListView(
              children: [
                ...List.generate(
                    question.options.length,
                    (index) => Option(
                          index: index,
                          text: question.options[index],
                          press: () => _controller.checkAns(question, index),
                        ))
              ],
            ),
          ),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}
