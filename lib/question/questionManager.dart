import 'package:growletters/question/questionUI.dart';
import 'questionMaker.dart';

class QuestionManager {
  static void loadQuestions(String yamlString) {
    final questionMaker = QuestionMaker(
      words: parseWordOfTheDayItems(yamlString),
    );

    final quest = questionMaker.makeQuestions(
      9000,
    ); // big number so that we can get all questions

    _unusedQuestions
      ..clear()
      ..addAll(quest);
  }

  static QuestionData? nextQuestion() {
    if (_unusedQuestions.isEmpty) {
      if (_usedQuestions.isEmpty) {
        return null;
      }
      _unusedQuestions.addAll(_usedQuestions);
      _usedQuestions.clear();
    }
    final question = _unusedQuestions.removeAt(0);
    _usedQuestions.add(question);
    return question;
  }

  static void resetUsedQuestions() {
    if (_usedQuestions.isNotEmpty) {
      _unusedQuestions.addAll(_usedQuestions);
      _unusedQuestions.shuffle();
      _usedQuestions.clear();
    }
  }

  static bool get hasQuestions => _unusedQuestions.isNotEmpty;

  static final List<QuestionData> _unusedQuestions = [];
  static final List<QuestionData> _usedQuestions = [];
}
