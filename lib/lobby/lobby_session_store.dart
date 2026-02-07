import 'package:flutter/foundation.dart';

import 'models.dart';

class LobbySessionStore {
  LobbySessionStore._();

  static final LobbySessionStore instance = LobbySessionStore._();

  final ValueNotifier<LobbySession?> notifier = ValueNotifier<LobbySession?>(null);
  final ValueNotifier<String?> kickedMessage = ValueNotifier<String?>(null);

  LobbySession? get current => notifier.value;

  void update(LobbySession session) {
    notifier.value = session;
  }

  void clear() {
    notifier.value = null;
  }

  void markKicked([String message = 'You have been removed from the lobby.']) {
    kickedMessage.value = message;
  }

  void clearKicked() {
    kickedMessage.value = null;
  }
}
