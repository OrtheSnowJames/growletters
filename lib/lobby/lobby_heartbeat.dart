import 'dart:async';

import 'lobby_api.dart';
import 'lobby_session_store.dart';
import 'models.dart';

class LobbyHeartbeat {
  LobbyHeartbeat._() {
    LobbySessionStore.instance.notifier.addListener(_onSessionChanged);
  }

  static final LobbyHeartbeat instance = LobbyHeartbeat._();

  static const Duration _interval = Duration(seconds: 5);

  Timer? _timer;
  LobbySession? _session;
  bool _sending = false;

  void _onSessionChanged() {
    _session = LobbySessionStore.instance.current;
    _timer?.cancel();
    _timer = null;

    if (_session == null) {
      return;
    }

    _sendHeartbeat();
    _timer = Timer.periodic(_interval, (_) {
      _sendHeartbeat();
    });
  }

  Future<void> _sendHeartbeat() async {
    final session = _session;
    if (session == null || _sending) {
      return;
    }

    _sending = true;
    try {
      await LobbyApi.instance.sendHeartbeat(session);
    } catch (_) {
      // State transition is handled by lobby polling and closed-lobby responses.
    } finally {
      _sending = false;
    }
  }
}
