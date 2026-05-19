package main

import (
	"fmt"
	"log"
	"net/http"

	"sync"

	"github.com/gorilla/websocket"
)

var (
	upgrader = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool { return true }, // Дозволяємо всі підключення
	}
	//clients = make(map[string]*Client)
	clients   = []*Client{}
	clientsMu = sync.Mutex{}
	rooms     = make(map[string]*Room)
	roomsMu   = sync.Mutex{}
	joinQueue = make(chan *Client)
	//waitingClient *Client
)

type Client struct {
	ID    int
	Conn  *websocket.Conn
	read  chan map[string]any
	write chan map[string]any
}

type Room struct {
	ID      int
	Board   [9]string
	Players []*Client
	Turn    string
	Winner  string
}

func main() {

	go matchmaker()

	http.HandleFunc("/ws", handleConnections)

	fmt.Println("WebSocket сервер запущено на :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func handleConnections(w http.ResponseWriter, r *http.Request) {
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Fatal(err)
		return
	}

	index := len(clients)
	var clientID int
	if index == 0 {
		clientID = 0
		fmt.Printf("Перший клієнт підключився. ID: %d \n", index)
	} else {
		clientID = clients[len(clients)-1].ID + 1
		fmt.Printf("Новий клієнт підключився. ID: %d.\n", index)
	}

	fmt.Printf("len(clients) %d. new ID: %d\n", len(clients), clientID)
	client := &Client{
		ID:    clientID,
		Conn:  ws,
		read:  make(chan map[string]any),
		write: make(chan map[string]any),
		//inRoom: false,
	}

	clients = append(clients, client)
	go client.listen()
	go client.writePump()

	//client.write <- map[string]any{"status": "waiting", "message": "Пошук суперника"}

	joinQueue <- client
}

func matchmaker() {
	var waitingClient *Client

	for {
		newClient := <-joinQueue

		if newClient == nil {
			fmt.Println("matchmaker: отримано nil клієнта, видаляємо з черги")
			waitingClient = nil
			continue
		}

		if waitingClient == nil {
			waitingClient = newClient
			fmt.Printf("Клієнт %d очікує на пару \n", waitingClient.ID)

			newClient.write <- map[string]any{"status": "waiting", "message": "Пошук суперника"}

		} else {
			player1 := waitingClient
			player2 := newClient
			waitingClient = nil

			log.Printf("Пара створена. Гравець 1: %d, Гравець 2: %d \n", player1.ID, player2.ID)
			roomID := len(rooms) + 1 // fmt.Sprintf("room-%d", len(rooms)+1)
			newRoom := &Room{
				ID:      roomID,
				Board:   [9]string{"", "", "", "", "", "", "", "", ""},
				Players: []*Client{player1, player2},
				Turn:    "X",
				Winner:  "",
			}
			idString := fmt.Sprintf("client-%d", player1.ID)
			rooms[idString] = newRoom

			go handleMessages(newRoom)

			player1.write <- map[string]any{
				"status": "started",
				"board":  newRoom.Board,
				"turn":   newRoom.Turn,
				"symbol": "X"}
			player2.write <- map[string]any{
				"status": "started",
				"board":  newRoom.Board,
				"turn":   newRoom.Turn,
				"symbol": "O"}
		}
	}
}
