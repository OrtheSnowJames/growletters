import 'dart:async';
import 'package:flutter/material.dart';
import 'package:growletters/question/questionManager.dart';
import 'package:growletters/question/questionUI.dart';
import '../inventory/inventory_manager.dart';
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
  Timer? _harvestTimer;
  int _bananas = 0;

  @override
  void initState() {
    super.initState();
    _maybeStartHarvestTimer();
  }

  @override
  void dispose() {
    _harvestTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            child: Image(image: ResourceManager.all[widget.dat.stage.index], width: 100, height: 100,),
            onTapUp: (_) => _onTapUp(context),
          ),
          Text(
            'Stage: ${widget.dat.stage.index + 1}/${TreeStage.values.length}',
          ),
          Text('Bananas ready: $_bananas'),
        ],
      ),
    );
  }

  Future<void> _onTapUp(BuildContext tapContext) async {
    _collectBananasIfReady();
    if (widget.dat.stage == TreeStage.grown) {
      /*
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This tree is fully grown!')),
      );
      */
      return;
    }
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
        builder: (_) => _TreeQuestionScreen(
          initialQuestion: question,
          onResult: (wasCorrect) {
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
              _maybeStartHarvestTimer();
            });
          },
        ),
      ),
    );
  }

  void _maybeStartHarvestTimer() {
    if (widget.dat.stage != TreeStage.grown) {
      _harvestTimer?.cancel();
      _harvestTimer = null;
      return;
    }

    _harvestTimer ??= Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() {
        _bananas++;
      });
    });
  }

  void _collectBananasIfReady() {
    if (widget.dat.stage != TreeStage.grown || _bananas == 0) {
      return;
    }
    InventoryManager.addItem('banana', _bananas);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Collected $_bananas bananas!')),
    );
    setState(() {
      _bananas = 0;
    });
  }
}

class _TreeQuestionScreen extends StatefulWidget {
  const _TreeQuestionScreen({
    required this.initialQuestion,
    required this.onResult,
  });

  final QuestionData initialQuestion;
  final ValueChanged<bool> onResult;

  @override
  State<_TreeQuestionScreen> createState() => _TreeQuestionScreenState();
}

class _TreeQuestionScreenState extends State<_TreeQuestionScreen> {
  late QuestionData _currentQuestion;

  @override
  void initState() {
    super.initState();
    _currentQuestion = widget.initialQuestion;
  }

  void _handleContinue(bool wasCorrect) {
    widget.onResult(wasCorrect);
    final nextQuestion = QuestionManager.nextQuestion();
    if (nextQuestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more questions available.')),
      );
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _currentQuestion = nextQuestion;
    });
  }

  void _handleClose(bool wasCorrect) {
    widget.onResult(wasCorrect);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Question')),
      body: Question(
        key: ValueKey(_currentQuestion.question),
        questionData: _currentQuestion,
        onAnswered: _handleContinue,
        onClosed: _handleClose,
        isLastQuestion: false,
        popParentOnClose: false,
      ),
    );
  }
}
