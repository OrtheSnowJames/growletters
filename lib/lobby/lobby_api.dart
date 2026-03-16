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
  Map<String, String> _jsonHeaders({String? authToken}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<LobbySession> createLobby(String name) async {
    final response = await http.post(
      _uri('/create-lobby'),
      headers: _jsonHeaders(),
      body: jsonEncode({'playerName': name}),
    );
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return LobbySession(
      lobbyId: data['lobbyId'] as String,
      lobbyCode: data['lobbyCode'] as String,
      playerId: data['playerId'] as String,
      authToken: data['authToken'] as String,
      playerName: name,
      isHost: true,
    );
  }

  Future<LobbySession> joinLobby(String code, String name) async {
    final response = await http.post(
      _uri('/lobby/$code/join'),
      headers: _jsonHeaders(),
      body: jsonEncode({'playerName': name}),
    );
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return LobbySession(
      lobbyId: data['lobbyId'] as String,
      lobbyCode: data['lobbyCode'] as String,
      playerId: data['playerId'] as String,
      authToken: data['authToken'] as String,
      playerName: name,
      isHost: data['isHost'] as bool? ?? false,
    );
  }

  Future<LobbyInfo> fetchLobby(String code, {LobbySession? session}) async {
    final response = await http.get(
      _uri('/lobby/$code'),
      headers: _jsonHeaders(authToken: session?.authToken),
    );
    _throwIfNeeded(response);
    return LobbyInfo.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<LobbyPlayer>> fetchLeaderboard(
    String code, {
    LobbySession? session,
  }) async {
    final response = await http.get(
      _uri('/lobby/$code/leaderboard'),
      headers: _jsonHeaders(authToken: session?.authToken),
    );
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final players = data['players'] as List<dynamic>? ?? [];
    return players
        .map((player) => LobbyPlayer.fromJson(player as Map<String, dynamic>))
        .toList();
  }

  Future<void> startLobby(LobbySession session) async {
    final response = await http.post(
      _uri('/lobby/${session.lobbyCode}/start'),
      headers: _jsonHeaders(authToken: session.authToken),
      body: jsonEncode({'authToken': session.authToken}),
    );
    _throwIfNeeded(response);
  }

  Future<void> setTimeLimit(LobbySession session, int timeLimitSeconds) async {
    final response = await http.post(
      _uri('/lobby/${session.lobbyCode}/time-limit'),
      headers: _jsonHeaders(authToken: session.authToken),
      body: jsonEncode({
        'authToken': session.authToken,
        'timeLimitSeconds': timeLimitSeconds,
      }),
    );
    _throwIfNeeded(response);
  }

  Future<void> endLobby(LobbySession session) async {
    final response = await http.post(
      _uri('/lobby/${session.lobbyCode}/end'),
      headers: _jsonHeaders(authToken: session.authToken),
      body: jsonEncode({'authToken': session.authToken}),
    );
    _throwIfNeeded(response);
  }

  Future<void> leaveLobby(
    LobbySession session, {
    String? targetPlayerId,
  }) async {
    try {
      final response = await http.post(
        _uri('/lobby/${session.lobbyCode}/leave'),
        headers: _jsonHeaders(authToken: session.authToken),
        body: jsonEncode(<String, dynamic>{
          'authToken': session.authToken,
          if (targetPlayerId != null) 'playerId': targetPlayerId,
        }),
      );
      _throwIfNeeded(response);
    } catch (_) {}
  }

  bool sendLeaveBeacon(String code, String authToken) {
    final url = _uri('/lobby/$code/leave').toString();
    final body = jsonEncode({'authToken': authToken});
    return sendLeaveBeaconPayload(url, body, authToken);
  }

  Future<void> reportApples(LobbySession session, int apples) async {
    try {
      final response = await http.post(
        _uri('/lobby/${session.lobbyCode}/apples'),
        headers: _jsonHeaders(authToken: session.authToken),
        body: jsonEncode({'authToken': session.authToken, 'apples': apples}),
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

  Future<void> sendHeartbeat(LobbySession session) async {
    final response = await http.post(
      _uri('/lobby/${session.lobbyCode}/heartbeat'),
      headers: _jsonHeaders(authToken: session.authToken),
      body: jsonEncode({'authToken': session.authToken}),
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
