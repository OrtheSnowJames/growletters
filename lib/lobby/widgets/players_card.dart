import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/palette.dart';
import '../models.dart';

class PlayersCard extends StatelessWidget {
  const PlayersCard({
    super.key,
    required this.info,
    required this.canManagePlayers,
    required this.currentPlayerId,
    required this.showScores,
    required this.onRemovePlayer,
  });

  final LobbyInfo info;
  final bool canManagePlayers;
  final String currentPlayerId;
  final bool showScores;
  final void Function(LobbyPlayer player, bool skipConfirmation) onRemovePlayer;

  @override
  Widget build(BuildContext context) {
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
            'Players',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: info.players.length,
                  itemBuilder: (context, index) {
                    final player = info.players[index];
                    return PlayerCard(
                      player: player,
                      showScores: showScores,
                      canRemove:
                          canManagePlayers && player.id != currentPlayerId,
                      onRemovePlayer: (skipConfirmation) =>
                          onRemovePlayer(player, skipConfirmation),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerCard extends StatefulWidget {
  const PlayerCard({
    super.key,
    required this.player,
    required this.showScores,
    required this.canRemove,
    required this.onRemovePlayer,
  });

  final LobbyPlayer player;
  final bool showScores;
  final bool canRemove;
  final void Function(bool skipConfirmation) onRemovePlayer;

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> {
  bool _hovering = false;

  void _handleTap() {
    if (!widget.canRemove) return;
    final skipConfirmation = _isShiftPressed();
    widget.onRemovePlayer(skipConfirmation);
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final theme = Theme.of(context);
    final highlight = widget.canRemove && _hovering;
    final bgColor = highlight ? const Color(0xFF431824) : AppPalette.card;
    final borderColor = highlight ? Colors.redAccent : Colors.white10;

    return MouseRegion(
      onEnter: widget.canRemove
          ? (_) => setState(() => _hovering = true)
          : null,
      onExit: widget.canRemove
          ? (_) => setState(() => _hovering = false)
          : null,
      child: GestureDetector(
        onTap: widget.canRemove ? _handleTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (player.isHost) ...[
                Icon(Icons.star, size: 20, color: AppPalette.accent),
                const SizedBox(height: 4),
              ],
              Text(
                player.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.showScores) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco, size: 16, color: Colors.orange.shade200),
                    const SizedBox(width: 4),
                    Text('${player.apples}', style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                player.isHost ? 'Host' : 'Player',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.blueGrey[200],
                ),
              ),
              if (widget.canRemove)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _hovering
                      ? Text(
                          'Click to remove${_shiftHint()}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: highlight
                                ? Colors.redAccent
                                : Colors.blueGrey[200],
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _shiftHint() {
    final shiftPressed = _isShiftPressed();
    return shiftPressed ? '' : ' (Shift to skip confirm)';
  }

  bool _isShiftPressed() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
  }
}
