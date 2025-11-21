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

    questions
      ..clear()
      ..addAll(quest);
    _currentIndex = 0;

    print(questions);
  }

  static QuestionData? nextQuestion() {
    if (questions.isEmpty) {
      return null;
    }
    final question = questions[_currentIndex % questions.length];
    _currentIndex++;
    return question;
  }

  static bool get hasQuestions => questions.isNotEmpty;

  static final List<QuestionData> questions = [];
  static int _currentIndex = 0;
}
