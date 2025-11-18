import 'package:flutter/material.dart';
import 'questionUI.dart';
import 'questionMaker.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.onQuizFinished, required this.yamlContent});

  final ValueChanged<int>? onQuizFinished;
  final String yamlContent;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  late List<QuestionData> _questions;

  @override
  void initState() {
    super.initState();
    // Parse YAML and generate questions
    final words = parseWordOfTheDayItems(widget.yamlContent);
    final questionMaker = QuestionMaker(words: words);
    // Generate 5 questions (or fewer if not enough words)
    _questions = questionMaker.makeQuestions(5);
  }

  void _onQuestionAnswered(bool correct) {
    setState(() {
      if (correct) {
        _score++;
        _currentQuestionIndex++;

        if (_currentQuestionIndex >= _questions.length) {
          widget.onQuizFinished?.call(_score);
        }
      } else {
        _score--;
      }
    });
  }

  bool get _isLastQuestion => _currentQuestionIndex >= _questions.length - 1;

  @override
  Widget build(BuildContext context) {
    if (_currentQuestionIndex >= _questions.length) {
      // Quiz finished - this shouldn't happen, but just in case
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      body: Question(
        questionData: currentQuestion,
        onAnswered: _onQuestionAnswered,
        isLastQuestion: _isLastQuestion,
      ),
    );
  }
}
