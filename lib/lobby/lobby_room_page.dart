import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/main_view/main_view.dart';
import '../theme/palette.dart';
import 'leave_beacon.dart';
import 'unload_hook.dart';
import 'lobby_api.dart';
import 'models.dart';

class LobbyRoomPage extends StatefulWidget {
  const LobbyRoomPage({super.key, required this.session});

  final LobbySession session;

  @override
  State<LobbyRoomPage> createState() => _LobbyRoomPageState();
}

class _LobbyRoomPageState extends State<LobbyRoomPage> {
  LobbyInfo? _info;
  String? _error;
  Timer? _ticker;
  bool _isStarting = false;
  bool _hostDisconnected = false;
  bool _navigatedToGame = false;
  UnloadDisposer? _unloadDisposer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _ticker = Timer.periodic(const Duration(seconds: 3), (_) => _fetch());
    if (widget.session.isHost) {
      _unloadDisposer = registerBeforeUnload(() {
        if (!_navigatedToGame) {
          LobbyApi.instance.sendLeaveBeacon(
            widget.session.lobbyCode,
            widget.session.playerId,
          );
        }
      });
    }
  }

  Widget _buildHostDisconnected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),

          /*
          Text(
            'Host disconnected',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
          ),
          */
          
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _unloadDisposer?.call();
    if (!_navigatedToGame) {
      LobbyApi.instance.leaveLobby(
        widget.session.lobbyCode,
        widget.session.playerId,
      );
    }
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final info = await LobbyApi.instance.fetchLobby(widget.session.lobbyCode);
      if (!mounted) return;
      setState(() {
        _info = info;
        _error = null;
      });
    } on LobbyClosedException catch (err) {
      if (!mounted) return;
      _ticker?.cancel();
      setState(() {
        _hostDisconnected = true;
        _error = err.message;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
      });
    }
  }

  Future<void> _startGame() async {
    setState(() => _isStarting = true);
    try {
      await LobbyApi.instance.startLobby(
        widget.session.lobbyCode,
        widget.session.playerId,
      );
      if (!mounted) return;
      await _fetch();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  void _enterGame() {
    _navigatedToGame = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainView()),
    );
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave lobby?'),
        content: const Text(
          'This will eradicate you from the lobby. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lobby'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetch,
            ),
          ],
        ),
        body: _hostDisconnected
            ? _buildHostDisconnected(context)
            : Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _StatusBanner(
                  message: _error!,
                  color: Colors.redAccent,
                  onDismiss: () => setState(() => _error = null),
                ),
              ),
            if (info != null) ...[
              _LobbyHeader(info: info),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _PlayersCard(info: info)),
                    const SizedBox(width: 16),
                    if (info.started) Expanded(child: _LeaderboardCard(info: info)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (widget.session.isHost)
                ElevatedButton(
                  onPressed: info.started || _isStarting ? null : _startGame,
                  child: Text(info.started ? 'Starting...' : 'Start Game'),
                )
              else ...[
                Text(
                  info.started
                      ? 'Game is starting…'
                      : 'Waiting for host to start the game.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                if (info.started)
                  ElevatedButton(
                    onPressed: _enterGame,
                    child: const Text('Enter Game'),
                  ),
              ],
              if (widget.session.isHost && info.started) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _enterGame,
                  child: const Text('Play Game'),
                ),
              ],
            ],
          ]
          ),
        ),
      ),
    );
  }
}

class _LobbyHeader extends StatelessWidget {
  const _LobbyHeader({required this.info});

  final LobbyInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final link = '${Uri.base.origin}/?code=${info.lobbyCode}';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lobby Code',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.blueGrey[200]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      info.lobbyCode,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                letterSpacing: 4,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(
                link,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blueGrey[100],
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayersCard extends StatelessWidget {
  const _PlayersCard({required this.info});

  final LobbyInfo info;

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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: info.players.length,
              itemBuilder: (context, index) {
                final player = info.players[index];
                return ListTile(
                  leading: Icon(
                    player.isHost ? Icons.star : Icons.person,
                    color: player.isHost ? AppPalette.accent : Colors.white70,
                  ),
                  title: Text(player.name),
                  subtitle: Text('${player.apples} apples'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.info});

  final LobbyInfo info;

  @override
  Widget build(BuildContext context) {
    final players = List<LobbyPlayer>.from(info.players)
      ..sort((a, b) => b.apples.compareTo(a.apples));
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
            'Leaderboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return ListTile(
                  leading: Text('#${index + 1}'),
                  title: Text(player.name),
                  trailing: Text(
                    '${player.apples}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.color,
    required this.onDismiss,
  });

  final String message;
  final Color color;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: color,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
