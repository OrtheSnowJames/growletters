import 'dart:async';

import 'package:flutter/material.dart';
import '../game/main_view/main_view.dart';
import '../widgets/confirm_exit_dialog.dart';
//import 'leave_beacon.dart';
import 'unload_hook.dart';
import 'lobby_api.dart';
import 'models.dart';
import 'lobby_session_store.dart';
import 'widgets/leaderboard_card.dart';
import 'widgets/lobby_header.dart';
import 'widgets/players_card.dart';
import 'widgets/status_banner.dart';
import 'widgets/time_limit_card.dart';

class LobbyRoomPage extends StatefulWidget {
  const LobbyRoomPage({
    super.key,
    required this.session,
    this.returnToGameOnPlay = false,
  });

  final LobbySession session;
  final bool returnToGameOnPlay;

  @override
  State<LobbyRoomPage> createState() => _LobbyRoomPageState();
}

class _LobbyRoomPageState extends State<LobbyRoomPage> {
  LobbyInfo? _info;
  String? _error;
  Timer? _ticker;
  Timer? _timeTicker;
  bool _isStarting = false;
  bool _hostDisconnected = false;
  bool _navigatedToGame = false;
  bool _isUpdatingTimeLimit = false;
  bool _isEndingGame = false;
  bool _isExiting = false;
  Timer? _autoEndTimer;
  DateTime? _localStartedAt;
  DateTime? _localEndedAt;
  UnloadDisposer? _unloadDisposer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _ticker = Timer.periodic(const Duration(seconds: 3), (_) => _fetch());
    _timeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    _unloadDisposer = registerBeforeUnload(() {
      if (!_navigatedToGame) {
        LobbyApi.instance.sendLeaveBeacon(
          widget.session.lobbyCode,
          widget.session.playerId,
        );
      }
    });
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
    _timeTicker?.cancel();
    _autoEndTimer?.cancel();
    _unloadDisposer?.call();
    if (!_navigatedToGame && !_isExiting) {
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
      final stillInLobby = info.players.any(
        (player) => player.id == widget.session.playerId,
      );
      if (!stillInLobby) {
        await _forceReturnToLobby(showDialog: true);
        return;
      }
      if (!info.started) {
        _localStartedAt = null;
        if (_localEndedAt == null && info.startedAt != null) {
          _localEndedAt = info.startedAt?.add(
            Duration(seconds: info.timeLimitSeconds),
          );
        }
        _autoEndTimer?.cancel();
        _autoEndTimer = null;
      } else if (info.startedAt != null) {
        _localStartedAt = info.startedAt;
        _localEndedAt = null;
      } else if (_localStartedAt == null) {
        _localStartedAt = DateTime.now().toUtc();
      }
      setState(() {
        _info = info;
        _error = null;
      });
      _scheduleAutoEndIfNeeded(info);
    } on LobbyClosedException catch (err) {
      if (!mounted) return;
      await _forceReturnToLobby(showDialog: true);
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

  Future<void> _updateTimeLimitSeconds(int seconds) async {
    if (_isUpdatingTimeLimit) return;
    setState(() => _isUpdatingTimeLimit = true);
    try {
      await LobbyApi.instance.setTimeLimit(
        widget.session.lobbyCode,
        widget.session.playerId,
        seconds,
      );
      await _fetch();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isUpdatingTimeLimit = false);
      }
    }
  }

  Future<void> _endGame() async {
    if (_isEndingGame) return;
    setState(() => _isEndingGame = true);
    try {
      await LobbyApi.instance.endLobby(
        widget.session.lobbyCode,
        widget.session.playerId,
      );
      _localEndedAt = DateTime.now().toUtc();
      await _fetch();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isEndingGame = false);
      }
    }
  }

  void _scheduleAutoEndIfNeeded(LobbyInfo info) {
    if (!widget.session.isHost) return;
    if (!info.started || _isEndingGame) return;
    if (_autoEndTimer != null) return;
    final startedAt = info.startedAt ?? _localStartedAt;
    if (startedAt == null) return;
    final endAt = startedAt.add(Duration(seconds: info.timeLimitSeconds));
    if (DateTime.now().toUtc().isBefore(endAt)) return;
    _autoEndTimer = Timer(const Duration(seconds: 5), () {
      _autoEndTimer = null;
      if (mounted) {
        _endGame();
      }
    });
  }

  bool _isEndWindow(LobbyInfo info) {
    final startedAt = info.startedAt;
    final endAt = startedAt != null
        ? startedAt.add(Duration(seconds: info.timeLimitSeconds))
        : _localEndedAt;
    if (endAt == null) return false;
    final now = DateTime.now().toUtc();
    return now.isAfter(endAt) &&
        now.isBefore(endAt.add(const Duration(seconds: 5)));
  }

  Future<void> _removePlayer(
    LobbyPlayer player, {
    required bool skipConfirmation,
  }) async {
    if (!widget.session.isHost || player.id == widget.session.playerId) {
      return;
    }
    if (!skipConfirmation) {
      final confirmed = await _confirmPlayerRemoval(player);
      if (!confirmed) return;
    }
    try {
      await LobbyApi.instance.leaveLobby(widget.session.lobbyCode, player.id);
      await _fetch();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to remove ${player.name}: $err';
      });
    }
  }

  Future<bool> _confirmPlayerRemoval(LobbyPlayer player) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove player?'),
        content: Text(
          'Remove ${player.name} from the lobby?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _enterGame() {
    final info = _info;
    final effectiveStartedAt = (info != null && info.started)
        ? info.startedAt ?? _localStartedAt
        : null;
    _navigatedToGame = true;
    if (widget.returnToGameOnPlay && Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainView(
          showHostWarning: widget.session.isHost,
          timeLimitSeconds: info?.timeLimitSeconds ?? 600,
          startedAt: effectiveStartedAt,
          session: widget.session,
        ),
      ),
    );
  }

  Future<bool> _confirmExit() async {
    return showLobbyExitDialog(
      context,
      showHostWarning: widget.session.isHost,
    );
  }

  Future<void> _exitLobby() async {
    if (_isExiting) return;
    final confirmed = await _confirmExit();
    if (!confirmed) return;
    _isExiting = true;
    try {
      await LobbyApi.instance.leaveLobby(
        widget.session.lobbyCode,
        widget.session.playerId,
      );
    } catch (_) {}
    LobbySessionStore.instance.clear();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _forceReturnToLobby({bool showDialog = false}) async {
    if (_isExiting) return;
    _isExiting = true;
    if (showDialog) {
      LobbySessionStore.instance.markKicked();
    }
    LobbySessionStore.instance.clear();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    final effectiveStartedAt = (info != null && info.started)
        ? info.startedAt ?? _localStartedAt
        : null;
    final showResults = info != null && (info.started || _isEndWindow(info));
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lobby'),
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _exitLobby,
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
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
                        child: StatusBanner(
                          message: _error!,
                          color: Colors.redAccent,
                          onDismiss: () => setState(() => _error = null),
                        ),
                      ),
                    if (info != null) ...[
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (widget.session.isHost) ...[
                                      Flexible(
                                        fit: FlexFit.loose,
                                        child: LobbyHeader(info: info),
                                      ),
                                      const SizedBox(height: 16),
                                      TimeLimitCard(
                                        timeLimitSeconds: info.timeLimitSeconds,
                                        startedAt: effectiveStartedAt,
                                        canEdit: !showResults,
                                        isStarted: showResults ||
                                            _isUpdatingTimeLimit,
                                        onChanged: _updateTimeLimitSeconds,
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                minimumSize:
                                                    const Size.fromHeight(56),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                              ),
                                              onPressed: showResults ||
                                                      _isStarting
                                                  ? null
                                                  : _startGame,
                                              child: Text(
                                                showResults
                                                    ? 'Starting...'
                                                    : 'Start Game',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]
                                  else ...[
                                    LobbyHeader(info: info),
                                    const SizedBox(height: 16),
                                    TimeLimitCard(
                                      timeLimitSeconds: info.timeLimitSeconds,
                                      startedAt: effectiveStartedAt,
                                      canEdit: false,
                                      isStarted: info.started,
                                      onChanged: null,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      info.started
                                          ? 'Game is starting…'
                                          : 'Waiting for host to start the game.',
                                      textAlign: TextAlign.center,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 12),
                                    if (info.started)
                                      ElevatedButton(
                                        onPressed: _enterGame,
                                        child: const Text('Enter Game'),
                                      ),
                                  ],
                                  if (widget.session.isHost && showResults) ...[
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _enterGame,
                                      child: const Text('Play Game'),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      onPressed:
                                          _isEndingGame || !info.started
                                              ? null
                                              : _endGame,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('End Game Now'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: PlayersCard(
                                      info: info,
                                      canManagePlayers: widget.session.isHost,
                                      currentPlayerId: widget.session.playerId,
                                      showScores: info.started,
                                      onRemovePlayer: (player, skipConfirm) {
                                        _removePlayer(
                                          player,
                                          skipConfirmation: skipConfirm,
                                        );
                                      },
                                    ),
                                  ),
                                  if (showResults) ...[
                                    const SizedBox(height: 16),
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: LeaderboardCard(info: info),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
