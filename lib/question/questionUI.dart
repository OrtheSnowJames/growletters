import 'package:flutter/material.dart';
import 'package:growletters/question/questionType.dart';
import 'statusPage.dart';

export 'package:growletters/question/questionType.dart';

class QuestionData {
  final String question;
  final QuestionType questionType;
  final List<String>? options;
  final String answer;

  QuestionData({
    required this.question,
    required this.answer,
    required this.questionType,
    this.options,
  });
}

typedef QuestionCompletionBuilder = Widget Function(
  BuildContext context,
  int score,
  VoidCallback restart,
);

class Questions extends StatefulWidget {
  const Questions({
    super.key,
    required this.questions,
    this.onFinished,
    this.emptyState,
    this.completionBuilder,
  });

  final List<QuestionData> questions;
  final ValueChanged<int>? onFinished;
  final Widget? emptyState;
  final QuestionCompletionBuilder? completionBuilder;

  @override
  State<Questions> createState() => _QuestionsState();
}

class _QuestionsState extends State<Questions> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _hasReportedCompletion = false;

  @override
  void didUpdateWidget(covariant Questions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questions != widget.questions) {
      _resetQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return widget.emptyState ??
          const Center(child: Text('No questions available.'));
    }

    if (_currentQuestionIndex >= widget.questions.length) {
      return widget.completionBuilder?.call(
            context,
            _score,
            _resetQuiz,
          ) ??
          _buildDefaultCompletedView(context);
    }

    final question = widget.questions[_currentQuestionIndex];
    final isLastQuestion =
        _currentQuestionIndex >= widget.questions.length - 1;

    return Question(
      questionData: question,
      onAnswered: _handleQuestionAnswered,
      isLastQuestion: isLastQuestion,
      popParentOnClose: false,
    );
  }

  void _handleQuestionAnswered(bool wasCorrect) {
    setState(() {
      if (wasCorrect) {
        _score++;
        _currentQuestionIndex++;
      } else {
        _score--;
      }
    });

    if (wasCorrect && _currentQuestionIndex >= widget.questions.length) {
      _notifyFinished();
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _hasReportedCompletion = false;
    });
  }

  void _notifyFinished() {
    if (_hasReportedCompletion) {
      return;
    }
    _hasReportedCompletion = true;
    widget.onFinished?.call(_score);
  }

  Widget _buildDefaultCompletedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quiz complete!',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Score: $_score / ${widget.questions.length}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _resetQuiz,
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }
}

class Question extends StatefulWidget {
  const Question({
    super.key,
    required this.questionData,
    this.onAnswered,
    this.onClosed,
    this.isLastQuestion = false,
    this.popParentOnClose = true,
  });
  final QuestionData questionData;
  final ValueChanged<bool>? onAnswered;
  final ValueChanged<bool>? onClosed;
  final bool isLastQuestion;
  final bool popParentOnClose;

  @override
  State<Question> createState() => _QuestionState();
}

class _QuestionState extends State<Question> {
  late QuestionData questionData;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    questionData = widget.questionData;
    _textController = TextEditingController();
  }

  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  ButtonStyle makeButtonStyle(int index) {
    switch (index) {
      case 0:
        return ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.red),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          padding: WidgetStateProperty.all(EdgeInsets.all(10)),
          minimumSize: WidgetStateProperty.all(Size(double.infinity, 60)),
        );
      case 1:
        return ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.green),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          padding: WidgetStateProperty.all(EdgeInsets.all(10)),
          minimumSize: WidgetStateProperty.all(Size(double.infinity, 60)),
        );
      case 2:
        return ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.blue),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          padding: WidgetStateProperty.all(EdgeInsets.all(10)),
          minimumSize: WidgetStateProperty.all(Size(double.infinity, 60)),
        );
      default:
        return ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            const Color.fromARGB(255, 189, 170, 1),
          ),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          padding: WidgetStateProperty.all(EdgeInsets.all(10)),
          minimumSize: WidgetStateProperty.all(Size(double.infinity, 60)),
        );
    }
  }

  ElevatedButton makeButton(int index, {String text = "use widget"}) {
    if (text == "use widget") {
      text = 'Widget ${index + 1}';
    }

    return ElevatedButton(
      onPressed: () {
        handleSubmit(text);
      },
      style: makeButtonStyle(index),
      child: Text(text),
    );
  }

  Widget makeButtonRow(int buttonCount) {
    List<Widget> rows = [];
    final options = widget.questionData.options ?? [];
    // 2 buttons per row
    for (int i = 0; i < buttonCount; i += 2) {
      List<Widget> rowButtons = [];
      final buttonText = i < options.length ? options[i] : 'Widget ${i + 1}';
      rowButtons.add(Expanded(child: makeButton(i, text: buttonText)));
      if (i + 1 < buttonCount) {
        rowButtons.add(const SizedBox(width: 10));
        final buttonText2 = i + 1 < options.length
            ? options[i + 1]
            : 'Widget ${i + 2}';
        rowButtons.add(Expanded(child: makeButton(i + 1, text: buttonText2)));
      }
      rows.add(
        Row(children: rowButtons, mainAxisAlignment: MainAxisAlignment.center),
      );
      if (i + 2 < buttonCount) {
        rows.add(const SizedBox(height: 10));
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _buildAnswerInput() {
    if (widget.questionData.questionType == QuestionType.textInput) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromARGB(255, 45, 44, 44),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter your answer...',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () {
                handleSubmit(_textController.text);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.blue),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
                minimumSize: WidgetStateProperty.all(
                  const Size(double.infinity, 60),
                ),
              ),
              child: const Text('Submit'),
            ),
          ),
        ],
      );
    } else {
      return makeButtonRow(4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 20),
          Text(
            widget.questionData.question,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          _buildAnswerInput(),
        ],
      ),
    );
  }

  void handleSubmit(String response) {
    bool correct =
        response.toLowerCase().trim() ==
        widget.questionData.answer.toLowerCase().trim();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => StatusPage(
          correct: correct,
          correctAnswer: widget.questionData.answer,
          isLastQuestion: widget.isLastQuestion,
          onContinue: (wasCorrect) {
            widget.onAnswered?.call(wasCorrect);
          },
          onClose: (wasCorrect) {
            (widget.onClosed ?? widget.onAnswered)?.call(wasCorrect);
          },
          popParentOnClose: widget.popParentOnClose,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from left for correct, from right for incorrect
          final begin = Offset(correct ? -1.0 : 1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    ).then((_) {
      // Handle navigation after status page
    });
  }
}
