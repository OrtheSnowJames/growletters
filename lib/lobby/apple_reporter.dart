import '../game/inventory/inventory_manager.dart';
import 'lobby_api.dart';
import 'lobby_session_store.dart';
import 'models.dart';

class AppleReporter {
  AppleReporter._() {
    LobbySessionStore.instance.notifier.addListener(_onSessionChanged);
    InventoryManager.listenable.addListener(_emitIfNeeded);
  }

  static final AppleReporter instance = AppleReporter._();

  LobbySession? _session;
  int? _lastSent;

  void _onSessionChanged() {
    _session = LobbySessionStore.instance.current;
    _lastSent = null;
    _emitIfNeeded();
  }

  void _emitIfNeeded() {
    final session = _session;
    if (session == null) return;
    final apples = InventoryManager.counts['ananab'] ?? 0;
    if (_lastSent == apples) return;
    _lastSent = apples;
    LobbyApi.instance.reportApples(session, apples);
  }
}
