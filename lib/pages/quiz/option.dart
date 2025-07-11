import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:quiz_khel/controllers/quiz_controllers.dart';
import 'package:quiz_khel/utils/screen_size.dart';

class Option extends StatelessWidget {
  const Option({
    super.key,
    required this.text,
    required this.index,
    required this.press,
  });

  final String text;
  final int index;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    screenSize.init(context: context);
    return GetBuilder<QuestionController>(
      builder: (qncontroller) {
        Color getTheRightColor() {
          if (qncontroller.isAnswered) {
            if (index == qncontroller.correctAns) {
              return Colors.green.shade900;
            } else if (index == qncontroller.selectedAns &&
                qncontroller.selectedAns != qncontroller.correctAns) {
              return Colors.red;
            }
          }
          return Colors.grey;
        }

        IconData getTheRightIcon() {
          return getTheRightColor() == Colors.red ? Icons.close : Icons.done;
        }

        return InkWell(
          onTap: press,
          child: Container(
            margin: const EdgeInsets.only(top: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: getTheRightColor() == Colors.grey
                  ? Colors.white
                  : getTheRightColor().withOpacity(.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: getTheRightColor()),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  spreadRadius: .2,
                  color: Colors.grey.withOpacity(.4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${index + 1}. $text",
                  style: TextStyle(
                    color: getTheRightColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  height: 26,
                  width: 26,
                  decoration: BoxDecoration(
                    color: getTheRightColor() == Colors.grey
                        ? Colors.transparent
                        : getTheRightColor(),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: getTheRightColor(),
                    ),
                  ),
                  child: getTheRightColor() == Colors.grey
                      ? null
                      : Icon(
                          getTheRightIcon(),
                          size: 16,
                          color: Colors.white,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
