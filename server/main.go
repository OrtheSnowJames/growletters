package main

import (
	"encoding/json"
	"log"
	"math/rand"
	"net/http"
	"strings"
	"sync"
	"time"

	uuid "github.com/gofrs/uuid"
	socketio "github.com/googollee/go-socket.io"
	"github.com/googollee/go-socket.io/engineio"
)

type questionAnswered struct {
	Question string `json:"question"`
	Correct  bool   `json:"correct"`
	PlayerID string `json:"playerId"`
}

type appleCountPayload struct {
	PlayerID string `json:"playerId"`
	Apples   int    `json:"apples"`
}

type lobbyPlayer struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Apples  int    `json:"apples"`
	IsHost  bool   `json:"isHost"`
	Joined  int64  `json:"joinedAt"`
	Session string `json:"-"`
}

type lobby struct {
	ID          string
	Code        string
	HostID      string
	Started     bool
	Closed      bool
	CloseReason string
	CreatedAt   time.Time
	Players     map[string]*lobbyPlayer
}

var (
	sockServer *socketio.Server
	lobbies    = map[string]*lobby{}
	lobbyMu    sync.RWMutex
)

func main() {
	sockServer = socketio.NewServer(
		&engineio.Options{
			//Transports: []transport.Transport{"websocket", "polling"},
		},
	)

	go sockServer.Serve()
	defer sockServer.Close()

	mux := http.NewServeMux()
	mux.HandleFunc("/create-lobby", handleCreateLobby)
	mux.HandleFunc("/lobby/", handleLobbyRoutes)
	mux.Handle("/socket.io/", sockServer)

	addr := ":3000"
	log.Printf("Server listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, withCORS(mux)))
}

func handleCreateLobby(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		PlayerName string `json:"playerName"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.PlayerName) == "" {
		http.Error(w, "playerName required", http.StatusBadRequest)
		return
	}

	lobbyMu.Lock()
	defer lobbyMu.Unlock()

	code := generateCode()
	for _, exists := lobbies[code]; exists; _, exists = lobbies[code] {
		code = generateCode()
	}

	lobbyID := uuid.Must(uuid.NewV4()).String()
	playerID := uuid.Must(uuid.NewV4()).String()

	player := &lobbyPlayer{
		ID:     playerID,
		Name:   req.PlayerName,
		IsHost: true,
		Joined: time.Now().Unix(),
	}

	newLobby := &lobby{
		ID:        lobbyID,
		Code:      code,
		HostID:    playerID,
		CreatedAt: time.Now(),
		Players: map[string]*lobbyPlayer{
			playerID: player,
		},
	}

	lobbies[code] = newLobby
	registerNamespace(code)

	respondJSON(w, http.StatusCreated, map[string]any{
		"lobbyId":   lobbyID,
		"lobbyCode": code,
		"playerId":  playerID,
		"isHost":    true,
	})
}

func handleLobbyRoutes(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/lobby/")
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) == 0 || parts[0] == "" {
		http.NotFound(w, r)
		return
	}
	code := strings.ToUpper(parts[0])

	switch {
	case r.Method == http.MethodGet && len(parts) == 1:
		handleGetLobby(w, r, code)
	case r.Method == http.MethodGet && len(parts) == 2 && parts[1] == "leaderboard":
		handleLeaderboard(w, r, code)
	case r.Method == http.MethodPost && len(parts) == 2 && parts[1] == "join":
		handleJoinLobby(w, r, code)
	case r.Method == http.MethodPost && len(parts) == 2 && parts[1] == "start":
		handleStartLobby(w, r, code)
	case r.Method == http.MethodPost && len(parts) == 2 && parts[1] == "leave":
		handleLeaveLobby(w, r, code)
	case r.Method == http.MethodPost && len(parts) == 2 && parts[1] == "apples":
		handleApplesUpdate(w, r, code)
	default:
		http.NotFound(w, r)
	}
}

func handleGetLobby(w http.ResponseWriter, r *http.Request, code string) {
	lobbyMu.RLock()
	l, ok := lobbies[code]
	lobbyMu.RUnlock()
	if !ok {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}
	if l.Closed {
		respondJSON(w, http.StatusGone, map[string]string{
			"error": l.CloseReason,
		})
		return
	}

	respondJSON(w, http.StatusOK, lobbyToResponse(l))
}

func handleLeaderboard(w http.ResponseWriter, r *http.Request, code string) {
	lobbyMu.RLock()
	l, ok := lobbies[code]
	lobbyMu.RUnlock()
	if !ok {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}
	if l.Closed {
		respondJSON(w, http.StatusGone, map[string]string{
			"error": l.CloseReason,
		})
		return
	}

	players := lobbyPlayersSlice(l)
	sortPlayersByApples(players)
	respondJSON(w, http.StatusOK, map[string]any{
		"players": players,
	})
}

func handleJoinLobby(w http.ResponseWriter, r *http.Request, code string) {
	var req struct {
		PlayerName string `json:"playerName"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.PlayerName) == "" {
		http.Error(w, "playerName required", http.StatusBadRequest)
		return
	}

	lobbyMu.Lock()
	defer lobbyMu.Unlock()
	l, ok := lobbies[code]
	if !ok {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}
	if l.Closed {
		http.Error(w, l.CloseReason, http.StatusGone)
		return
	}
	if l.Started {
		http.Error(w, "lobby already started", http.StatusGone)
		return
	}
	playerID := uuid.Must(uuid.NewV4()).String()
	l.Players[playerID] = &lobbyPlayer{
		ID:     playerID,
		Name:   req.PlayerName,
		Joined: time.Now().Unix(),
	}

	respondJSON(w, http.StatusOK, map[string]any{
		"lobbyId":   l.ID,
		"lobbyCode": l.Code,
		"playerId":  playerID,
		"isHost":    false,
	})
}

func handleStartLobby(w http.ResponseWriter, r *http.Request, code string) {
	var req struct {
		PlayerID string `json:"playerId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.PlayerID == "" {
		http.Error(w, "playerId required", http.StatusBadRequest)
		return
	}

	lobbyMu.Lock()
	defer lobbyMu.Unlock()
	l, ok := lobbies[code]
	if !ok {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}
	if l.HostID != req.PlayerID {
		http.Error(w, "only host can start lobby", http.StatusForbidden)
		return
	}
	if l.Started {
		http.Error(w, "lobby already started", http.StatusConflict)
		return
	}
	l.Started = true

	respondJSON(w, http.StatusOK, map[string]string{"status": "started"})
}

func handleLeaveLobby(w http.ResponseWriter, r *http.Request, code string) {
	var req struct {
		PlayerID string `json:"playerId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.PlayerID == "" {
		http.Error(w, "playerId required", http.StatusBadRequest)
		return
	}
	lobbyMu.Lock()
	defer lobbyMu.Unlock()
	l, ok := lobbies[code]
	if !ok {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}
	if l.HostID == req.PlayerID {
		l.Closed = true
		l.CloseReason = "Host disconnected"
	} else {
		delete(l.Players, req.PlayerID)
	}
	respondJSON(w, http.StatusOK, map[string]string{"status": "left"})
}

func handleApplesUpdate(w http.ResponseWriter, r *http.Request, code string) {
	var req appleCountPayload
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid payload", http.StatusBadRequest)
		return
	}
	lobbyMu.Lock()
	defer lobbyMu.Unlock()
	l, ok := lobbies[code]
	if !ok {
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}
	if l.Closed {
		http.Error(w, l.CloseReason, http.StatusGone)
		return
	}
	player, ok := l.Players[req.PlayerID]
	if !ok {
		http.Error(w, "player not found", http.StatusNotFound)
		return
	}
	player.Apples = req.Apples
	respondJSON(w, http.StatusOK, map[string]string{"status": "updated"})
}

func registerNamespace(code string) {
	ns := "/" + strings.ToLower(code)

	sockServer.OnConnect(ns, func(c socketio.Conn) error {
		c.SetContext(code)
		return nil
	})

	sockServer.OnEvent(ns, "questionAnswered", func(c socketio.Conn, payload string) {
		var data questionAnswered
		if err := json.Unmarshal([]byte(payload), &data); err != nil {
			log.Printf("invalid question payload: %v", err)
			return
		}
		updatePlayerApples(code, data.PlayerID, func(p *lobbyPlayer) {
			// no-op for now but placeholder for tracking answered questions
		})
	})

	sockServer.OnEvent(ns, "appleCount", func(c socketio.Conn, payload string) {
		var data appleCountPayload
		if err := json.Unmarshal([]byte(payload), &data); err != nil {
			log.Printf("invalid apple payload: %v", err)
			return
		}
		updatePlayerApples(code, data.PlayerID, func(p *lobbyPlayer) {
			p.Apples = data.Apples
		})
	})
}

func updatePlayerApples(code, playerID string, update func(*lobbyPlayer)) {
	lobbyMu.Lock()
	defer lobbyMu.Unlock()
	l, ok := lobbies[code]
	if !ok {
		return
	}
	player, ok := l.Players[playerID]
	if !ok {
		return
	}
	update(player)
}

func lobbyToResponse(l *lobby) map[string]any {
	return map[string]any{
		"lobbyId":   l.ID,
		"lobbyCode": l.Code,
		"started":   l.Started,
		"players":   lobbyPlayersSlice(l),
	}
}

func lobbyPlayersSlice(l *lobby) []map[string]any {
	players := make([]map[string]any, 0, len(l.Players))
	for _, p := range l.Players {
		players = append(players, map[string]any{
			"id":     p.ID,
			"name":   p.Name,
			"apples": p.Apples,
			"isHost": p.IsHost,
		})
	}
	return players
}

func sortPlayersByApples(players []map[string]any) {
	for i := 0; i < len(players); i++ {
		for j := i + 1; j < len(players); j++ {
			if players[j]["apples"].(int) > players[i]["apples"].(int) {
				players[i], players[j] = players[j], players[i]
			}
		}
	}
}

func generateCode() string {
	const letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	rand.Seed(time.Now().UnixNano())
	b := make([]byte, 6)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		w.Header().Set("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func respondJSON(w http.ResponseWriter, code int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(payload)
}
