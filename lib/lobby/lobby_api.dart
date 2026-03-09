import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'leave_beacon.dart';
import 'models.dart';

class LobbyApi {
  const LobbyApi(this.baseUrl);

  final String baseUrl;

  static const defaultBaseUrl = 'http://localhost:3000';
  static final LobbyApi instance = LobbyApi(defaultBaseUrl);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<LobbySession> createLobby(String name) async {
    final response = await http.post(
      _uri('/create-lobby'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'playerName': name}),
    );
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return LobbySession(
      lobbyId: data['lobbyId'] as String,
      lobbyCode: data['lobbyCode'] as String,
      playerId: data['playerId'] as String,
      playerName: name,
      isHost: true,
    );
  }

  Future<LobbySession> joinLobby(String code, String name) async {
    final response = await http.post(
      _uri('/lobby/$code/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'playerName': name}),
    );
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return LobbySession(
      lobbyId: data['lobbyId'] as String,
      lobbyCode: data['lobbyCode'] as String,
      playerId: data['playerId'] as String,
      playerName: name,
      isHost: data['isHost'] as bool? ?? false,
    );
  }

  Future<LobbyInfo> fetchLobby(String code) async {
    final response = await http.get(_uri('/lobby/$code'));
    _throwIfNeeded(response);
    return LobbyInfo.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<LobbyPlayer>> fetchLeaderboard(String code) async {
    final response = await http.get(_uri('/lobby/$code/leaderboard'));
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final players = data['players'] as List<dynamic>? ?? [];
    return players
        .map((player) => LobbyPlayer.fromJson(player as Map<String, dynamic>))
        .toList();
  }

  Future<void> startLobby(String code, String playerId) async {
    final response = await http.post(
      _uri('/lobby/$code/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'playerId': playerId}),
    );
    _throwIfNeeded(response);
  }

  Future<void> setTimeLimit(
    String code,
    String playerId,
    int timeLimitSeconds,
  ) async {
    final response = await http.post(
      _uri('/lobby/$code/time-limit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'playerId': playerId,
        'timeLimitSeconds': timeLimitSeconds,
      }),
    );
    _throwIfNeeded(response);
  }

  Future<void> endLobby(String code, String playerId) async {
    final response = await http.post(
      _uri('/lobby/$code/end'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'playerId': playerId}),
    );
    _throwIfNeeded(response);
  }

  Future<void> leaveLobby(String code, String playerId) async {
    try {
      final response = await http.post(
        _uri('/lobby/$code/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'playerId': playerId}),
      );
      _throwIfNeeded(response);
    } catch (_) {}
  }

  bool sendLeaveBeacon(String code, String playerId) {
    final url = _uri('/lobby/$code/leave').toString();
    final body = jsonEncode({'playerId': playerId});
    return sendLeaveBeaconPayload(url, body);
  }

  Future<void> reportApples(String code, String playerId, int apples) async {
    try {
      final response = await http.post(
        _uri('/lobby/$code/apples'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'playerId': playerId, 'apples': apples}),
      );
      if (response.statusCode >= 400 && kDebugMode) {
        debugPrint('Failed to report apples: ${response.body}');
      }
    } catch (err) {
      if (kDebugMode) {
        debugPrint('Failed to report apples: $err');
      }
    }
  }

  Future<void> sendHeartbeat(String code, String playerId) async {
    final response = await http.post(
      _uri('/lobby/$code/heartbeat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'playerId': playerId}),
    );
    _throwIfNeeded(response);
  }

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 400) {
      final message = _extractError(response.body);
      if (response.statusCode == 410) {
        throw LobbyClosedException(message ?? 'Host disconnected');
      }
      throw Exception(
        'Server error ${response.statusCode}: ${message ?? response.body}',
      );
    }
  }

  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['error'] as String? ??
            decoded['message'] as String? ??
            decoded['status'] as String?;
      }
    } catch (_) {}
    return null;
  }
}

class LobbyClosedException implements Exception {
  LobbyClosedException(this.message);

  final String message;

  @override
  String toString() => message;
}
