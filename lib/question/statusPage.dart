import 'package:flutter/material.dart';

class StatusPage extends StatefulWidget {
  final bool correct;
  final String? correctAnswer;
  final bool isLastQuestion;
  final ValueChanged<bool>? onContinue;
  final bool popParentOnClose;

  const StatusPage({
    required this.correct,
    this.correctAnswer,
    this.isLastQuestion = false,
    this.onContinue,
    this.popParentOnClose = true,
  });

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();

    if (!widget.correct) {
      Future.delayed(const Duration(seconds: 3), () {
        setState(() => _canGoBack = true);
      });
    } else {
      _canGoBack = true;
    }
  }

  void _continue() {
    if (_canGoBack) {
      widget.onContinue?.call(widget.correct);
      Navigator.pop(context);
    }
  }

  void _close() {
    if (_canGoBack) {
      widget.onContinue?.call(widget.correct);
      // Pop the status page, optionally closing the parent route as well.
      Navigator.pop(context);
      if (widget.popParentOnClose) {
        Navigator.pop(context);
      }
    }
  }

  void _goBackIncorrect() {
    if (_canGoBack) {
      widget.onContinue?.call(false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.correct
          ? Colors.lightGreenAccent
          : Colors.redAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.correct ? "Correct!" : "Incorrect",
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (!widget.correct && widget.correctAnswer != null) ...[
              const SizedBox(height: 20),
              Text(
                "The correct answer is:",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              Text(
                widget.correctAnswer!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (widget.correct) ...[
              // Show Continue or Close button for correct answers
              if (widget.isLastQuestion)
                ElevatedButton(
                  onPressed: _canGoBack ? _close : null,
                  child: const Text("Close"),
                )
              else
                ElevatedButton(
                  onPressed: _canGoBack ? _continue : null,
                  child: const Text("Continue"),
                ),
            ] else ...[
              // Show Go Back button for incorrect answers (no close button)
              ElevatedButton(
                onPressed: _canGoBack ? _goBackIncorrect : null,
                child: Text(_canGoBack ? "Go Back" : "Wait 3 seconds…"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
