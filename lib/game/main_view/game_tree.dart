import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:growletters/question/questionManager.dart';
import 'package:growletters/question/questionUI.dart';
import 'package:growletters/widgets/confirm_exit_dialog.dart';
import 'package:growletters/lobby/lobby_api.dart';
import 'package:growletters/lobby/lobby_session_store.dart';
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

  AssetImage get _stageImage {
    switch (widget.dat.stage) {
      case TreeStage.seed:
        return ResourceManager.tree1;
      case TreeStage.sprout:
        return ResourceManager.tree2;
      case TreeStage.branchy:
        return ResourceManager.tree3;
      case TreeStage.sapling:
        return ResourceManager.tree4;
      case TreeStage.grown:
        return ResourceManager.tree5;
    }
  }

  AssetImage get _currentTreeImage {
    if (widget.dat.stage != TreeStage.grown) {
      return _stageImage;
    }
    if (_bananas == 0) {
      return ResourceManager.grownNoBananas;
    }
    if (_bananas == 1) {
      return ResourceManager.grownOneBanana;
    }
    return ResourceManager.grownManyBananas;
  }

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
            child: SizedBox(
              width: 100,
              height: 100,
              child: Image(
                image: _currentTreeImage,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
            ),
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
          isTreeGrown: () => widget.dat.stage == TreeStage.grown,
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
    required this.isTreeGrown,
  });

  final QuestionData initialQuestion;
  final ValueChanged<bool> onResult;
  final ValueGetter<bool> isTreeGrown;

  @override
  State<_TreeQuestionScreen> createState() => _TreeQuestionScreenState();
}

class _TreeQuestionScreenState extends State<_TreeQuestionScreen> {
  late QuestionData _currentQuestion;
  bool _showContinueButton = true;

  @override
  void initState() {
    super.initState();
    _currentQuestion = widget.initialQuestion;
  }

  void _handleEvaluated(bool wasCorrect) {
    widget.onResult(wasCorrect);
    final grown = widget.isTreeGrown();
    setState(() {
      _showContinueButton = !grown;
    });
  }

  void _handleContinue(bool wasCorrect) {
    if (!_showContinueButton) {
      Navigator.of(context).pop();
      return;
    }
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
      _showContinueButton = true;
    });
  }

  void _handleClose(bool wasCorrect) {
    Navigator.of(context).pop();
  }

  Future<void> _exitToLobby() async {
    final session = LobbySessionStore.instance.current;
    final confirmed = await showLobbyExitDialog(
      context,
      showHostWarning: session?.isHost ?? false,
    );
    if (!confirmed) return;
    if (session != null) {
      try {
        await LobbyApi.instance.leaveLobby(
          session.lobbyCode,
          session.playerId,
        );
      } catch (_) {}
      LobbySessionStore.instance.clear();
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: _exitToLobby,
        ),
      ),
      body: Question(
        key: ValueKey(_currentQuestion.question),
        questionData: _currentQuestion,
        onEvaluated: _handleEvaluated,
        onAnswered: _handleContinue,
        onClosed: _handleClose,
        showContinueButton: _showContinueButton,
        isLastQuestion: false,
        popParentOnClose: false,
      ),
    );
  }
}
