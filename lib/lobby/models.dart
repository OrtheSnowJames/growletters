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
    required this.players,
  });

  final String lobbyId;
  final String lobbyCode;
  final bool started;
  final List<LobbyPlayer> players;

  factory LobbyInfo.fromJson(Map<String, dynamic> json) {
    final playersJson = json['players'] as List<dynamic>? ?? [];
    return LobbyInfo(
      lobbyId: json['lobbyId'] as String,
      lobbyCode: json['lobbyCode'] as String,
      started: json['started'] as bool? ?? false,
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
    required this.playerName,
    required this.isHost,
  });

  final String lobbyId;
  final String lobbyCode;
  final String playerId;
  final String playerName;
  final bool isHost;

  LobbySession copyWith({
    String? lobbyId,
    String? lobbyCode,
    String? playerId,
    String? playerName,
    bool? isHost,
  }) {
    return LobbySession(
      lobbyId: lobbyId ?? this.lobbyId,
      lobbyCode: lobbyCode ?? this.lobbyCode,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      isHost: isHost ?? this.isHost,
    );
  }
}
