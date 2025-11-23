package main

import (
	"encoding/json"
	"fmt"
	"strconv"

	socketio "github.com/googollee/go-socket.io"
	"github.com/googollee/go-socket.io/engineio"
)

type questionAnswered struct {
	Question string `json:"question"`
	Correct bool `json:"correct"`
}

func Red(text string) string {
    red := "\033[31m"
    reset := "\033[0m"
    return red + text + reset
}


var questionsAnswered []questionAnswered

var leaderboard map[string]int // string = client id, int = how many apples

func main() {
	server := socketio.NewServer(&engineio.Options{})

	server.OnConnect("/game", func(c socketio.Conn) error {
		return nil
	})

	server.OnEvent("/game", "questionAnswered", func(s socketio.Conn, msg string) {
		data := &questionAnswered{}
		json.Unmarshal([]byte(msg), data)

		questionsAnswered = append(questionsAnswered, *data)
	})

	server.OnEvent("/game", "appleCount", func(s socketio.Conn, msg string) {
		data, err := strconv.Atoi(msg)

		if err != nil {
			fmt.Printf("%s%s", Red("Error trying to cast msg to int in appleCount: "), err)
		}

		leaderboard[s.ID()] = data
	})
}