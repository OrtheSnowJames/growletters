import 'package:growletters/question/questionUI.dart';
import 'package:growletters/question/questionType.dart';
import 'package:yaml/yaml.dart';
import 'dart:math';

class WordOfTheDayItem {
  final String word;
  final String definition;
  final String partOfSpeech;
  final List<String> synonyms;
  final List<String> antonyms;

  WordOfTheDayItem({
    required this.word,
    required this.definition,
    required this.partOfSpeech,
    required this.synonyms,
    required this.antonyms,
  });

  factory WordOfTheDayItem.fromYamlMap(Map data) {
    return WordOfTheDayItem(
      word: data['word'] as String,
      definition: data['definition'] as String,
      partOfSpeech: data['part_of_speech'] as String? ?? '',
      synonyms: List<String>.from(data['synonyms'] ?? const []),
      antonyms: List<String>.from(data['antonyms'] ?? const []),
    );
  }
}

List<WordOfTheDayItem> parseWordOfTheDayItems(String yamlString) {
  final yamlList = loadYaml(yamlString) as YamlList;
  return yamlList
      .map((entry) => WordOfTheDayItem.fromYamlMap(Map.from(entry)))
      .toList();
}

class QuestionMaker {
  final List<WordOfTheDayItem> _allWords;
  final Set<String> _usedQuestions =
      {}; // Track (word, questionType) combinations
  final Random _random = Random();

  QuestionMaker({required List<WordOfTheDayItem> words}) : _allWords = words;

  /// Create questions from a single word
  List<QuestionData> makeQuestionsFromWord(WordOfTheDayItem word, int count) {
    return makeQuestions(count, words: [word]);
  }

  /// Create questions from a list of words (or all words if not specified)
  List<QuestionData> makeQuestions(int count, {List<WordOfTheDayItem>? words}) {
    final availableWords = words ?? _allWords;
    if (availableWords.isEmpty) return [];

    // Calculate maximum possible questions: words * question types
    final maxPossibleQuestions =
        availableWords.length * WordQuestionType.values.length;
    final questionsToGenerate = count < maxPossibleQuestions
        ? count
        : maxPossibleQuestions;

    List<QuestionData> result = [];

    while (result.length < questionsToGenerate) {
      // Pick a random word
      final word = availableWords[_random.nextInt(availableWords.length)];

      // Pick a random question type
      final questionType = _randomType();
      final questionKey = '${word.word}_$questionType';

      // Skip if we've already used this combination
      if (_usedQuestions.contains(questionKey)) {
        continue;
      }

      QuestionData questionData;
      switch (questionType) {
        case WordQuestionType.wordMultipleChoise:
          questionData = _questionMultipleChoiceDefinition(
            word,
            availableWords,
          );
          break;
        case WordQuestionType.wordTextInput:
          questionData = _questionWrittenDefinition(word);
          break;
      }

      _usedQuestions.add(questionKey);
      result.add(questionData);
    }

    return result;
  }

  /// Reset the used questions tracker
  void reset() {
    _usedQuestions.clear();
  }

  QuestionData _questionMultipleChoiceDefinition(
    WordOfTheDayItem word,
    List<WordOfTheDayItem> allWords,
  ) {
    // Generate 3 wrong options from other words
    final wrongOptions = <String>[];
    final availableWords = allWords.where((w) => w.word != word.word).toList();

    // Shuffle and take up to 3
    availableWords.shuffle(_random);
    for (var i = 0; i < 3 && i < availableWords.length; i++) {
      wrongOptions.add(availableWords[i].word);
    }

    // Combine with correct answer and shuffle
    final allOptions = [word.word, ...wrongOptions];
    allOptions.shuffle(_random);

    return QuestionData(
      question: "What is the word that has this definition: ${word.definition}",
      questionType: QuestionType.multipleChoice,
      answer: word.word,
      options: allOptions,
    );
  }

  QuestionData _questionWrittenDefinition(WordOfTheDayItem word) {
    return QuestionData(
      question: "What is the word that has this definition: ${word.definition}",
      questionType: QuestionType.textInput,
      answer: word.word,
    );
  }

  WordQuestionType _randomType() {
    final values = WordQuestionType.values;
    return values[_random.nextInt(values.length)];
  }
}
