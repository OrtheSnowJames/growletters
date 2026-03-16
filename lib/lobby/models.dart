class LobbyPlayer {
  LobbyPlayer({
    required this.id,
    required this.name,
    required this.apples,
    required this.isHost,
  });

  final String id;
  final String name;
  final int apples;
  final bool isHost;

  factory LobbyPlayer.fromJson(Map<String, dynamic> json) {
    return LobbyPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      apples: (json['apples'] as num?)?.toInt() ?? 0,
      isHost: json['isHost'] as bool? ?? false,
    );
  }
}

class LobbyInfo {
  LobbyInfo({
    required this.lobbyId,
    required this.lobbyCode,
    required this.started,
    required this.timeLimitSeconds,
    required this.startedAt,
    required this.players,
  });

  final String lobbyId;
  final String lobbyCode;
  final bool started;
  final int timeLimitSeconds;
  final DateTime? startedAt;
  final List<LobbyPlayer> players;

  factory LobbyInfo.fromJson(Map<String, dynamic> json) {
    final playersJson = json['players'] as List<dynamic>? ?? [];
    final startedAtSeconds = (json['startedAt'] as num?)?.toInt() ?? 0;
    return LobbyInfo(
      lobbyId: json['lobbyId'] as String,
      lobbyCode: json['lobbyCode'] as String,
      started: json['started'] as bool? ?? false,
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 600,
      startedAt: startedAtSeconds > 0
          ? DateTime.fromMillisecondsSinceEpoch(
              startedAtSeconds * 1000,
              isUtc: true,
            )
          : null,
      players: playersJson
          .map((player) => LobbyPlayer.fromJson(player as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LobbySession {
  const LobbySession({
    required this.lobbyId,
    required this.lobbyCode,
    required this.playerId,
    required this.authToken,
    required this.playerName,
    required this.isHost,
  });

  final String lobbyId;
  final String lobbyCode;
  final String playerId;
  final String authToken;
  final String playerName;
  final bool isHost;

  LobbySession copyWith({
    String? lobbyId,
    String? lobbyCode,
    String? playerId,
    String? authToken,
    String? playerName,
    bool? isHost,
  }) {
    return LobbySession(
      lobbyId: lobbyId ?? this.lobbyId,
      lobbyCode: lobbyCode ?? this.lobbyCode,
      playerId: playerId ?? this.playerId,
      authToken: authToken ?? this.authToken,
      playerName: playerName ?? this.playerName,
      isHost: isHost ?? this.isHost,
    );
  }
}
