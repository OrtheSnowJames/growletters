import 'package:flutter/material.dart';
import 'lobby_api.dart';
import 'lobby_session_store.dart';
import 'lobby_room_page.dart';
import '../widgets/confirm_exit_dialog.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _lobbyCodeController = TextEditingController();
  late final VoidCallback _kickedListener;

  bool _hostingOptionsOn = false;
  bool _isCreatingLobby = false;
  bool _isJoiningLobby = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final codeFromUrl = Uri.base.queryParameters['code'];
    if (codeFromUrl != null && codeFromUrl.isNotEmpty) {
      _lobbyCodeController.text = codeFromUrl.toUpperCase();
      _hostingOptionsOn = false;
    }
    _kickedListener = () {
      final message = LobbySessionStore.instance.kickedMessage.value;
      if (message == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showKickedDialog(context);
        LobbySessionStore.instance.clearKicked();
      });
    };
    LobbySessionStore.instance.kickedMessage.addListener(_kickedListener);
  }

  @override
  void dispose() {
    LobbySessionStore.instance.kickedMessage.removeListener(_kickedListener);
    _playerNameController.dispose();
    _lobbyCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 32),
                    _buildNameField(theme),
                    const SizedBox(height: 24),
                    if (_hostingOptionsOn) ...[
                      _buildHostCard(theme),
                    ] else ...[
                      _buildJoinCard(theme),
                    ],
                    const SizedBox(height: 24),
                    _buildStatusMessages(theme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildHostingToggleButton(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostingToggleButton(ThemeData theme) {
    final hosting = _hostingOptionsOn;
    return ElevatedButton.icon(
      icon: Icon(hosting ? Icons.person_off : Icons.person_add_alt_1),
      label: Text(hosting ? 'Join A Game' : 'Host A Game'),
      style: ElevatedButton.styleFrom(
        backgroundColor: hosting ? Colors.blueGrey[700] : const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () => setState(() => _hostingOptionsOn = !hosting),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          'grow_bananas',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            color: const Color(0xFF4ADE80),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _hostingOptionsOn
              ? 'Host a game'
              : 'Join a game',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.blueGrey[200],
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Name',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.blueGrey[100],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _playerNameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Enter your name'),
            maxLength: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildHostCard(ThemeData theme) {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            theme,
            title: 'Host a Game',
            subtitle: 'Create a new lobby and invite players to join',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isCreatingLobby ? null : _handleCreateLobby,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF22C55E),
              ),
              child: Text(_isCreatingLobby ? 'Creating...' : 'Create Lobby'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCard(ThemeData theme) {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            theme,
            title: 'Join a Game',
            subtitle: 'Enter a lobby code to join an existing game',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lobbyCodeController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Enter 6-digit code'),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isJoiningLobby ? null : _handleJoinLobby,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: const Color(0xFF0F172A),
              ),
              child: Text(_isJoiningLobby ? 'Joining...' : 'Join Lobby'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessages(ThemeData theme) {
    return Column(
      children: [
        if (_errorMessage != null && _errorMessage!.isNotEmpty)
          _StatusBanner(
            message: _errorMessage!,
            color: Colors.redAccent,
            onDismiss: () => setState(() => _errorMessage = null),
          ),
      ],
    );
  }

  Widget _cardHeader(
    ThemeData theme, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.blueGrey[200],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      counterText: '',
    );
  }

  Future<void> _handleCreateLobby() async {
    final name = _playerNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name to host.';
      });
      return;
    }
    setState(() {
      _isCreatingLobby = true;
      _errorMessage = null;
    });
    try {
      final session = await LobbyApi.instance.createLobby(name);
      LobbySessionStore.instance.update(session);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LobbyRoomPage(session: session)),
      );
    } catch (err) {
      setState(() => _errorMessage = err.toString());
    } finally {
      if (mounted) {
        setState(() => _isCreatingLobby = false);
      }
    }
  }

  Future<void> _handleJoinLobby() async {
    final name = _playerNameController.text.trim();
    final code = _lobbyCodeController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name before joining.';
      });
      return;
    }
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a lobby code.';
      });
      return;
    }
    setState(() {
      _isJoiningLobby = true;
      _errorMessage = null;
    });
    try {
      final session = await LobbyApi.instance.joinLobby(code, name);
      LobbySessionStore.instance.update(session);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LobbyRoomPage(session: session)),
      );
    } catch (err) {
      setState(() => _errorMessage = err.toString());
    } finally {
      if (mounted) {
        setState(() => _isJoiningLobby = false);
      }
    }
  }
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
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
        color: color.withOpacity(0.2),
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
