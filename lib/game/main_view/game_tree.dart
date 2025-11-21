import 'package:flutter/material.dart';
import 'package:growletters/question/questionManager.dart';
import 'package:growletters/question/questionUI.dart';
import '../resource_manager/resource_manager.dart';

enum TreeStage { seed, sprout, branchy, sapling, grown }

class TreeData {
  TreeStage stage;

  TreeData({required this.stage});

  TreeData.basic() : stage = TreeStage.seed;
}

class Tree extends StatefulWidget {
  final TreeData dat;

  Tree({required this.dat});

  _TreeState createState() => _TreeState();
}

class _TreeState extends State<Tree> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            child: Image(image: ResourceManager.all[widget.dat.stage.index]),
            onTapUp: (_) => _onTapUp(context),
          ),
          Text("Stage: ${widget.dat.stage.index}/${TreeStage.values.length}"),
        ],
      ),
    );
  }

  Future<void> _onTapUp(BuildContext tapContext) async {
    final question = QuestionManager.nextQuestion();
    if (question == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No questions available.')));
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: const Text('Question')),
          body: Question(
            questionData: question,
            onAnswered: (wasCorrect) {
              setState(() {
                if (wasCorrect) {
                  final nextIndex =
                      (widget.dat.stage.index + 1).clamp(0, TreeStage.values.length - 1);
                  widget.dat.stage = TreeStage.values[nextIndex];
                } else {
                  final prevIndex =
                      (widget.dat.stage.index - 1).clamp(0, TreeStage.values.length - 1);
                  widget.dat.stage = TreeStage.values[prevIndex];
                }
              });
              Navigator.pop(routeContext, wasCorrect);
            },
            isLastQuestion: false,
            popParentOnClose: false,
          ),
        ),
      ),
    );
  }
}
