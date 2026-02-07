import 'package:flutter/material.dart';

import '../../theme/palette.dart';

class TimeLimitCard extends StatefulWidget {
  const TimeLimitCard({
    super.key,
    required this.timeLimitSeconds,
    required this.startedAt,
    required this.canEdit,
    required this.onChanged,
    required this.isStarted,
  });

  final int timeLimitSeconds;
  final DateTime? startedAt;
  final bool canEdit;
  final bool isStarted;
  final ValueChanged<int>? onChanged;

  @override
  State<TimeLimitCard> createState() => _TimeLimitCardState();
}

class _TimeLimitCardState extends State<TimeLimitCard> {
  late double _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = _secondsToMinutes(widget.timeLimitSeconds);
  }

  @override
  void didUpdateWidget(TimeLimitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeLimitSeconds != widget.timeLimitSeconds ||
        oldWidget.isStarted != widget.isStarted) {
      _minutes = _secondsToMinutes(widget.timeLimitSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutesLabel = _minutes.round();
    final timeLeft = _formatDuration(_timeLeft());
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time limit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blueGrey[200],
                ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _minutes,
            min: 5,
            max: 30,
            divisions: 25,
            label: '$minutesLabel min',
            onChanged: widget.canEdit && !widget.isStarted
                ? (value) => setState(() => _minutes = value)
                : null,
            onChangeEnd: widget.canEdit && !widget.isStarted
                ? (value) =>
                    widget.onChanged?.call(value.round() * 60)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            '$minutesLabel minutes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Time left: $timeLeft',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blueGrey[200],
                ),
          ),
        ],
      ),
    );
  }

  double _secondsToMinutes(int seconds) {
    return (seconds / 60).clamp(5, 30).toDouble();
  }

  Duration _timeLeft() {
    final startedAt = widget.startedAt;
    if (startedAt == null) {
      return Duration(seconds: widget.timeLimitSeconds);
    }
    final endAt = startedAt.add(Duration(seconds: widget.timeLimitSeconds));
    final remaining = endAt.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesText = minutes.toString().padLeft(2, '0');
    final secondsText = seconds.toString().padLeft(2, '0');
    return '$minutesText:$secondsText';
  }
}
