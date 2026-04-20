package main

import (
	//"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

// type Response struct {
// 	Count int `json:"count"`
// }

var (
	//counter int
	board         = [9]string{"", "", "", "", "", "", "", "", ""}
	currentSymbol = "X"
	mu            sync.Mutex // Потрібно для безпечної роботи з данними з різних потоків

	clients   = make(map[*websocket.Conn]bool)
	broadcast = make(chan [9]string) // Chanal to sending new value
	upgrader  = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool { return true }, // Дозволяємо всі підключення
	}
)

func main() {
	//http.HandleFunc("/increment", incrementHandler)
	http.HandleFunc("/ws", handleConnections)

	// Окремий потік для розсилки оновлень
	go handleMessages()

	fmt.Println("WebSocket сервер запущено на :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func handleConnections(w http.ResponseWriter, r *http.Request) {
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Fatal(err)
	}
	defer ws.Close()

	clients[ws] = true

	ws.WriteJSON(map[string]interface{}{"board": board})

	for {
		// Чекаємо на повідомлення від клієнта (наприклад, сигнал про натискання)
		var msg map[string]int
		err := ws.ReadJSON(&msg)
		if err != nil {
			break
		}
		fmt.Printf("handleConnections() msg is: %v\n", msg)

		idx := msg["index"]
		// Логіка
		mu.Lock()
		if board[idx] == "" && checkWinner() == "" {
			board[idx] = currentSymbol

			if currentSymbol == "X" {
				currentSymbol = "O"
			} else {
				currentSymbol = "X"
			}
		}
		mu.Unlock()

		// Відправляємо нове значення в канал для розсилки всім
		broadcastBoard()
	}
}

func broadcastBoard() {
	mu.Lock()
	currentBoard := board
	mu.Unlock()

	broadcast <- currentBoard
}

func handleMessages() {
	for {
		updatedBoard := <-broadcast
		msg := map[string]any{"board": updatedBoard, "winner": checkWinner()}

		// Send to all connected clients
		for client := range clients {
			err := client.WriteJSON(msg)
			if err != nil {
				log.Printf("Помилка відправки клієнту: %v", err)
				client.Close()
				delete(clients, client)
			}
		}
	}
}

// Cheking the winner
var winPatterns = [8][3]int{
	{0, 1, 2}, {3, 4, 5}, {6, 7, 8},
	{0, 3, 6}, {1, 4, 7}, {2, 5, 8},
	{0, 4, 8}, {2, 4, 6},
}

func checkWinner() string {
	for _, pattern := range winPatterns {
		if board[pattern[0]] != "" &&
			board[pattern[0]] == board[pattern[1]] &&
			board[pattern[1]] == board[pattern[2]] {
			return board[pattern[0]]
		}
	}

	isFull := true
	for _, cell := range board {
		if cell == "" {
			isFull = false
			break
		}
	}

	if isFull {
		return "Draw"
	}

	return ""
}
