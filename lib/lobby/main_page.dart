import 'package:flutter/material.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _lobbyCodeController = TextEditingController();

  bool _showLobbyLink = false;
  bool _allowedToBeHost = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final codeFromUrl = Uri.base.queryParameters['code'];
    if (codeFromUrl != null && codeFromUrl.isNotEmpty) {
      _lobbyCodeController.text = codeFromUrl.toUpperCase();
      _allowedToBeHost = false;
    }
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _lobbyCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
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
                if (_allowedToBeHost) ...[
                  _buildHostCard(theme),
                  const SizedBox(height: 16),
                ],
                _buildJoinCard(theme),
                const SizedBox(height: 24),
                _buildStatusMessages(theme),
                const SizedBox(height: 24),
                _buildFooter(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          'grow_some_letters',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            color: const Color(0xFF4ADE80),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _allowedToBeHost
              ? 'Choose your role to get started'
              : 'Enter your name',
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
              onPressed: () {
                setState(() {
                  _showLobbyLink = true;
                  _successMessage = 'Lobby created! Code: ABC123';
                  _errorMessage = null;
                });
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF22C55E),
              ),
              child: const Text('Create Lobby'),
            ),
          ),
          if (_showLobbyLink) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF17223b),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Share this link with players:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'growletters.app/landing?code=ABC123',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightBlueAccent,
                    ),
                    child: const Text('Copy'),
                  ),
                ],
              ),
            ),
          ],
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
              onPressed: () {
                final hasName = _playerNameController.text.trim().isNotEmpty;
                setState(() {
                  if (!hasName) {
                    _errorMessage = 'Please enter your name before joining.';
                    _successMessage = null;
                    return;
                  }
                  _errorMessage = null;
                  _successMessage = 'Joining lobby...';
                });
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: const Color(0xFF0F172A),
              ),
              child: const Text('Join Lobby'),
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
        if (_successMessage != null && _successMessage!.isNotEmpty) ...[
          if (_errorMessage != null) const SizedBox(height: 12),
          _StatusBanner(
            message: _successMessage!,
            color: const Color(0xFF22C55E),
            onDismiss: () => setState(() => _successMessage = null),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Text(
      'This is just a demo of what the landing page could look like. ;)',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
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
