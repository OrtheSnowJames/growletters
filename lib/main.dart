import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:growletters/game/resource_manager/resource_manager.dart';
import 'package:growletters/question/questionManager.dart';
import 'game/main_view/game_tree.dart';
import 'game/trading_post/tradingPostUI.dart';
import 'question/questionMaker.dart';
import 'question/questionUI.dart';

void main() {
  runApp(
    MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: false),
      theme: ThemeData.light(useMaterial3: false),
      title: 'GrowLetters',
      home: const HomeScreen(),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _highScore = 0;
  late Future<String> _yamlContent;

  @override
  void initState() {
    super.initState();
    _yamlContent = rootBundle.loadString("assets/wotd.yaml");
    _yamlContent.then(QuestionManager.loadQuestions);
  }

  Future<void> _startQuiz(BuildContext context) async {
    final yamlContent = await _yamlContent;
    if (!mounted) return;

    final words = parseWordOfTheDayItems(yamlContent);
    final questionMaker = QuestionMaker(words: words);
    final questions = questionMaker.makeQuestions(5);

    final score = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: const Text('Quiz')),
          body: Questions(
            questions: questions,
            onFinished: (score) {
              Navigator.pop(routeContext, score);
            },
            emptyState: Builder(
              builder: (context) => Center(
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
          ),
        ),
      ),
    );

    if (!mounted || score == null) return;
    _updateHighScore(score);
  }

  void _previewTradingPost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TradingPostPreviewScreen()),
    );
  }

  void _previewTree(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TreePreviewScreen()),
    );
  }

  void _updateHighScore(int score) {
    setState(() {
      if (score > _highScore) {
        _highScore = score;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Load Stuff
    ResourceManager.preload(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('GrowLetters'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Cool Quiz",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'High Score: $_highScore',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _startQuiz(context),
              child: const Text("Start Quiz"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _previewTradingPost(context),
              child: const Text("Preview Trading Post UI"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _previewTree(context),
              child: const Text("Preview Tree"),
            ),
          ],
        ),
      ),
    );
  }
}

class TradingPostPreviewScreen extends StatelessWidget {
  const TradingPostPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trading Post Preview')),
      body: const TradingPost(),
    );
  }
}

class TreePreviewScreen extends StatelessWidget {
  const TreePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tree Preview')),
      body: Center(child: Tree(dat: TreeData.basic())),
    );
  }
}
