import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../models.dart';

class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({super.key, required this.info});

  final LobbyInfo info;

  @override
  Widget build(BuildContext context) {
    final players = List<LobbyPlayer>.from(info.players)
      ..sort((a, b) => b.apples.compareTo(a.apples));
    final showConfetti = _shouldShowConfetti();
    return Stack(
      children: [
        Container(
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
                'Leaderboard',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${index + 1}. ${player.name}, ${player.apples} apples',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (showConfetti) const Positioned.fill(child: _ConfettiOverlay()),
      ],
    );
  }

  bool _shouldShowConfetti() {
    final startedAt = info.startedAt;
    if (startedAt == null) {
      return false;
    }
    final endAt = startedAt.add(
      Duration(seconds: info.timeLimitSeconds),
    );
    final now = DateTime.now().toUtc();
    if (now.isBefore(endAt)) return false;
    final confettiUntil = endAt.add(const Duration(seconds: 5));
    return now.isBefore(confettiUntil);
  }
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _done = true);
        }
      })
      ..forward();
    _pieces = List<_ConfettiPiece>.generate(
      30,
      (index) => _ConfettiPiece.random(index),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              progress: _controller.value,
              pieces: _pieces,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.pieces});

  final double progress;
  final List<_ConfettiPiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final paint = Paint()..color = piece.color;
      final dx = (piece.startX + piece.drift * progress) * size.width;
      final dy = ((piece.startY + progress) % 1.0) * size.height;
      final rect = Rect.fromCenter(
        center: Offset(dx, dy),
        width: piece.size,
        height: piece.size * 0.6,
      );
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(piece.rotation + progress * math.pi);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: rect.width,
          height: rect.height,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pieces != pieces;
  }
}

class _ConfettiPiece {
  _ConfettiPiece({
    required this.startX,
    required this.startY,
    required this.size,
    required this.drift,
    required this.rotation,
    required this.color,
  });

  final double startX;
  final double startY;
  final double size;
  final double drift;
  final double rotation;
  final Color color;

  factory _ConfettiPiece.random(int seed) {
    final random = math.Random(seed);
    final palette = [
      const Color(0xFFFFC857),
      const Color(0xFF72B4FF),
      const Color(0xFFFF6B6B),
      const Color(0xFF8CE99A),
      const Color(0xFFF783AC),
    ];
    return _ConfettiPiece(
      startX: random.nextDouble(),
      startY: random.nextDouble(),
      size: 6 + random.nextDouble() * 6,
      drift: (random.nextDouble() - 0.5) * 0.3,
      rotation: random.nextDouble() * math.pi,
      color: palette[random.nextInt(palette.length)],
    );
  }
}
