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

  void _handleQuizFinished(int score) {
    widget.onQuizFinished?.call(score);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Questions(
        questions: _questions,
        onFinished: _handleQuizFinished,
        emptyState: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No questions available.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
