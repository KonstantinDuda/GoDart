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
	board = [9]string{"","","","","","","","",""}
	currentSymbol = "X" 
	mu sync.Mutex // Потрібно для безпечної роботи з данними з різних потоків

	clients = make(map[*websocket.Conn]bool)
	broadcast = make(chan [9]string) // Chanal to sending new value
	upgrader = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {return true}, // Дозволяємо всі підключення
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

	ws.WriteJSON(map[string]any{"board": board})

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
		if board[idx] == "" {
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
		msg := map[string]any{"board": updatedBoard}

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
