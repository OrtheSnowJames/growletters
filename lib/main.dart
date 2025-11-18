import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'question/quizScreen.dart';

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
  }

  void _startQuiz(BuildContext context) async {
    final yamlContent = await _yamlContent;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          onQuizFinished: _updateHighScore,
          yamlContent: yamlContent,
        ),
      ),
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
          ],
        ),
      ),
    );
  }
}
