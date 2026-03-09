import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../trading_post/tradingPostUI.dart';
import '../tools/apple_price_ticker.dart';
import '../inventory/inventory_manager.dart';
import '../../theme/palette.dart';
import '../../widgets/confirm_exit_dialog.dart';
import '../../lobby/lobby_api.dart';
import '../../lobby/lobby_room_page.dart';
import '../../lobby/models.dart';
import '../../lobby/lobby_session_store.dart';
import 'game_tree.dart';

class MainView extends StatefulWidget {
  const MainView({
    super.key,
    this.showHostWarning = false,
    this.timeLimitSeconds = 600,
    this.startedAt,
    this.session,
  });

  final bool showHostWarning;
  final int timeLimitSeconds;
  final DateTime? startedAt;
  final LobbySession? session;

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final List<TreeData> _trees = List<TreeData>.generate(
    6,
    (_) => TreeData.basic(),
  );

  final ScrollController _scrollController = ScrollController();
  double _currentOffset = 0;
  final ApplePriceTicker _priceTicker = ApplePriceTicker.instance;
  Timer? _timeTicker;
  Timer? _lobbyTicker;
  bool _navigatedToResults = false;
  bool _isPollingLobby = false;

  @override
  void initState() {
    super.initState();
    _priceTicker.attach();
    _scrollController.addListener(_handleScrollChanged);
    if (widget.startedAt != null) {
      _timeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          _checkForTimeExpiry();
          setState(() {});
        }
      });
    }
    if (widget.session != null) {
      _pollLobbyStatus();
      _lobbyTicker = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _pollLobbyStatus(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollChanged);
    _priceTicker.detach();
    if (!_priceTicker.hasListeners) {
      _priceTicker.reset();
    }
    if (InventoryManager.isInitialized) {
      InventoryManager.reset();
    }
    _timeTicker?.cancel();
    _lobbyTicker?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    final maxExtent = _scrollController.position.hasContentDimensions
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final double target = (_currentOffset + delta).clamp(0, maxExtent);
    _currentOffset = target;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleScrollChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _checkForTimeExpiry() {
    if (_navigatedToResults) return;
    final startedAt = widget.startedAt;
    if (startedAt == null) return;
    final endAt = startedAt.add(Duration(seconds: widget.timeLimitSeconds));
    if (DateTime.now().toUtc().isBefore(endAt)) return;
    final session = widget.session;
    if (session == null) return;
    _navigateToResults(session);
  }

  Future<void> _pollLobbyStatus() async {
    if (_isPollingLobby || _navigatedToResults) return;
    final session = widget.session;
    if (session == null) return;
    _isPollingLobby = true;
    try {
      final info = await LobbyApi.instance.fetchLobby(session.lobbyCode);
      if (!mounted) return;
      final stillInLobby = info.players.any(
        (player) => player.id == session.playerId,
      );
      if (!stillInLobby) {
        await _forceReturnToLobby(showDialog: true);
        return;
      }
      if (!info.started) {
        _navigateToResults(session);
        return;
      }
      final startedAt = info.startedAt ?? widget.startedAt;
      if (startedAt == null) return;
      final endAt = startedAt.add(Duration(seconds: info.timeLimitSeconds));
      if (DateTime.now().toUtc().isAfter(endAt)) {
        _navigateToResults(session);
      }
    } on LobbyClosedException {
      await _forceReturnToLobby(showDialog: true);
    } catch (_) {
      // Ignore polling failures.
    } finally {
      _isPollingLobby = false;
    }
  }

  void _navigateToResults(LobbySession session) {
    if (_navigatedToResults) return;
    _navigatedToResults = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LobbyRoomPage(session: session)),
      (route) => route.isFirst,
    );
  }

  Future<void> _forceReturnToLobby({bool showDialog = false}) async {
    if (!mounted) return;
    if (showDialog) {
      LobbySessionStore.instance.markKicked();
    }
    LobbySessionStore.instance.clear();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openTradingPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TradingPost(
          onTreeSeedPurchased: _handleTreeSeedPurchase,
          onExit: _exitToLobby,
          timeLimitSeconds: widget.timeLimitSeconds,
          startedAt: widget.startedAt,
        ),
      ),
    );
  }

  Future<bool> _confirmExitGame() async {
    return showLobbyExitDialog(
      context,
      showHostWarning: widget.showHostWarning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExitGame,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forest'),
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _exitToLobby,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A120C),
                    backgroundBlendMode: BlendMode.darken,
                    image: const DecorationImage(
                      image: AssetImage('assets/grass_texture.png'),
                      repeat: ImageRepeat.repeat,
                      alignment: Alignment.topLeft,
                      scale: 2.8,
                      colorFilter: ColorFilter.mode(
                        Color(0xE60A120C),
                        BlendMode.darken,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Trees(treeData: _trees, controller: _scrollController),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final canScrollBack =
                      _scrollController.hasClients &&
                      _scrollController.position.pixels > 0;
                  final canScrollForward =
                      _scrollController.hasClients &&
                      _scrollController.position.pixels <
                          _scrollController.position.maxScrollExtent;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (canScrollBack)
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => _scrollBy(-300),
                        ),
                      if (canScrollBack) const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _openTradingPost,
                        child: const Text('Trading Post'),
                      ),
                      if (widget.showHostWarning && widget.session != null) ...[
                        const SizedBox(width: 20),
                        OutlinedButton(
                          onPressed: _returnToLobby,
                          child: const Text('Back to Leaderboard'),
                        ),
                      ],
                      if (canScrollForward) const SizedBox(width: 20),
                      if (canScrollForward)
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => _scrollBy(300),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              _TimeLeftBanner(
                timeLimitSeconds: widget.timeLimitSeconds,
                startedAt: widget.startedAt,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTreeSeedPurchase() {
    if (!mounted) return;
    setState(() {
      _trees.add(TreeData.basic());
    });
  }

  void _returnToLobby() {
    final session = widget.session;
    if (session == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LobbyRoomPage(session: session, returnToGameOnPlay: true),
      ),
    );
  }

  Future<void> _exitToLobby() async {
    final session = widget.session ?? LobbySessionStore.instance.current;
    final confirmed = await showLobbyExitDialog(
      context,
      showHostWarning: session?.isHost ?? false,
    );
    if (!confirmed) return;
    if (session != null) {
      try {
        await LobbyApi.instance.leaveLobby(session.lobbyCode, session.playerId);
      } catch (_) {}
      LobbySessionStore.instance.clear();
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _TimeLeftBanner extends StatelessWidget {
  const _TimeLeftBanner({
    required this.timeLimitSeconds,
    required this.startedAt,
  });

  final int timeLimitSeconds;
  final DateTime? startedAt;

  @override
  Widget build(BuildContext context) {
    final timeLeft = _formatDuration(_timeLeft());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        'Time left: $timeLeft',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Duration _timeLeft() {
    final startedAtValue = startedAt;
    if (startedAtValue == null) {
      return Duration(seconds: timeLimitSeconds);
    }
    final endAt = startedAtValue.add(Duration(seconds: timeLimitSeconds));
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

class Trees extends StatelessWidget {
  const Trees({super.key, required this.treeData, required this.controller});

  final List<TreeData> treeData;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double itemWidth = 160;
        const double itemHeight = 220;
        final rows = math.max(1, (constraints.maxHeight / itemHeight).floor());

        return GridView.builder(
          controller: controller,
          scrollDirection: Axis.horizontal,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rows,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemCount: treeData.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: itemWidth,
              child: Tree(dat: treeData[index]),
            );
          },
        );
      },
    );
  }
}
