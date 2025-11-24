import 'package:flutter/foundation.dart';

import 'models.dart';

class LobbySessionStore {
  LobbySessionStore._();

  static final LobbySessionStore instance = LobbySessionStore._();

  final ValueNotifier<LobbySession?> notifier = ValueNotifier<LobbySession?>(null);

  LobbySession? get current => notifier.value;

  void update(LobbySession session) {
    notifier.value = session;
  }

  void clear() {
    notifier.value = null;
  }
}
