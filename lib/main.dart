import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:growletters/game/resource_manager/resource_manager.dart';
import 'package:growletters/question/questionManager.dart';
import 'game/main_view/game_tree.dart';
import 'game/main_view/main_view.dart';
import 'game/trading_post/tradingPostUI.dart';
import 'question/questionMaker.dart';
import 'lobby/main_page.dart';
import 'question/questionUI.dart';
import 'theme/palette.dart';
import 'lobby/apple_reporter.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppleReporter.instance;
  await _preloadQuestions();
  runApp(GrowLettersApp(showDebugHome: args.contains('--debug')));
}

Future<void> _preloadQuestions() async {
  final yaml = await rootBundle.loadString('assets/wotd.yaml');
  QuestionManager.loadQuestions(yaml);
}

class GrowLettersApp extends StatelessWidget {
  const GrowLettersApp({super.key, required this.showDebugHome});

  final bool showDebugHome;

  @override
  Widget build(BuildContext context) {
    final baseDark = ThemeData.dark(useMaterial3: false);
    final appTheme = baseDark.copyWith(
      scaffoldBackgroundColor: AppPalette.background,
      colorScheme: baseDark.colorScheme.copyWith(
        primary: AppPalette.accent,
        secondary: AppPalette.secondaryAccent,
        surface: AppPalette.card,
        background: AppPalette.background,
      ),
      textTheme: baseDark.textTheme.apply(
        bodyColor: Colors.blueGrey[50],
        displayColor: Colors.blueGrey[50],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.secondaryAccent,
          foregroundColor: AppPalette.background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: baseDark.appBarTheme.copyWith(
        backgroundColor: AppPalette.card,
        elevation: 0,
        titleTextStyle: baseDark.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: appTheme,
      theme: appTheme,
      title: 'GrowLetters',
      home: showDebugHome ? const HomeScreen() : const LobbyPage(),
    );
  }
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

  void _previewMainView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainViewPreviewScreen()),
    );
  }

  void _previewLobby(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LobbyPagePreviewScreen()),
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
        title: const Text('GrowLetters'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppPalette.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "grow_some_letters",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppPalette.accent,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'High Score: $_highScore',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  _buildPrimaryButton(
                    label: 'Start Quiz',
                    onPressed: () => _startQuiz(context),
                  ),
                  const SizedBox(height: 12),
                  _buildSecondaryButton(
                    label: 'Preview Trading Post UI',
                    onPressed: () => _previewTradingPost(context),
                  ),
                  const SizedBox(height: 12),
                  _buildSecondaryButton(
                    label: 'Preview Tree',
                    onPressed: () => _previewTree(context),
                  ),
                  const SizedBox(height: 12),
                  _buildSecondaryButton(
                    label: 'Preview Main View',
                    onPressed: () => _previewMainView(context),
                  ),
                  const SizedBox(height: 12),
                  _buildSecondaryButton(
                    label: 'Preview Lobby Page',
                    onPressed: () => _previewLobby(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onPressed}) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppPalette.accent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Text(label),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
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
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Tree(dat: TreeData.basic()),
        ),
      ),
    );
  }
}

class MainViewPreviewScreen extends StatelessWidget {
  const MainViewPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: MainView());
  }
}

class LobbyPagePreviewScreen extends StatelessWidget {
  const LobbyPagePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lobby Page Preview')),
      body: const LobbyPage(),
    );
  }
}
