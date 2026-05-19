package main

import (
	//"encoding/json"
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
	//inRoom bool
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

func (c *Client) listen() {
	defer func() {
		fmt.Printf("Клієнт %d відключився. Видаляємо з кімнати та масиву клієнтів. \n", c.ID)
		// TODO: Коли клієнт просто закритий, сервер крашиться.
		// Потрібно додати перевірку на nil для кімнати та клієнта, щоб уникнути цього.
		//if c.inRoom {
		removePlayerFromRoom( /*rooms[fmt.Sprintf("client-%d", c.ID)],*/ c)
		// } else {
		// 	deletePlayer(c)
		// }
	}()

	for {
		var msg map[string]any
		if err := c.Conn.ReadJSON(&msg); err != nil {
			log.Printf("Помилка читання від клієнта %d: %v \n", c.ID, err)
			return
		}
		if leave, ok := msg["status"]; ok {
			if leave == "leave" {
				log.Printf("Гравець %d вийшов з очікування \n", c.ID)
				return
			}
		}
		if len(msg) > 0 {
			fmt.Printf("Отримано повідомлення від %d: %v \n", c.ID, msg)
			c.read <- msg
		}

	}
}

func (c *Client) writePump() {
	for msg := range c.write {
		if err := c.Conn.WriteJSON(msg); err != nil {
			log.Printf("Помилка відправки повідомлення клієнту %d: %v \n", c.ID, err)
			return
		} else {
			fmt.Printf("Відправлено повідомлення клієнту %d: %v \n", c.ID, msg)
		}
	}
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
			// player1.inRoom = true
			// player2.inRoom = true

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

func handleMessages(room *Room) {
	// Логіка гри, обробка ходів, відправка оновлень гравцям
	// Ця функція буде слухати канали обох гравців та оновлювати стан гри відповідно до отриманих повідомлень
	for {
		select {
		case msg1, ok := <-room.Players[0].read:
			if !ok {
				fmt.Printf("Гравець 1 вийшов з гри \n")
				roomsMu.Lock()
				delete(rooms, fmt.Sprintf("client-%d", room.Players[0].ID))
				roomsMu.Unlock()
				return
			}
			playerMove(room, msg1, "X")

			//fmt.Printf("Отримано повідомлення від гравця 1: %v \n", msg1)
			// Обробка повідомлення від гравця 1
		case msg2, ok := <-room.Players[1].read:
			if !ok {
				fmt.Printf("Гравець 2 вийшов з гри \n")
				roomsMu.Lock()
				delete(rooms, fmt.Sprintf("client-%d", room.Players[1].ID))
				roomsMu.Unlock()
				return
			}
			playerMove(room, msg2, "O")
			//fmt.Printf("Отримано повідомлення від гравця 2: %v \n", msg2)
			// Обробка повідомлення від гравця 2
		}
	}
}

func playerMove(room *Room, msg map[string]any /*index int, */, player string) {
	indexFloat, ok := msg["index"].(float64)
	index := 0
	if ok {
		index = int(indexFloat)
	}

	fmt.Printf("Гравець %s робить хід на позицію %d \n", player, index)
	if index >= 0 && index < 9 {
		if room.Board[index] == "" && room.Winner == "" && room.Turn == player {
			room.Board[index] = room.Turn

			// Зміна черги
			if room.Turn == "X" {
				room.Turn = "O"
			} else {
				room.Turn = "X"
			}

			room.Winner = checkWinner(room.Board, room)

			// Відправка оновлення обом
			for _, player := range room.Players {
				player.write <- map[string]any{
					"status": "playing",
					"board":  room.Board,
					"turn":   room.Turn,
					"winner": room.Winner,
				}
			}
		}
	}

	newGame := msg["new_game"]
	if newGame != nil {
		fmt.Printf("Гравець %s робить запит new_game: %v \n", player, newGame)
		newInt := int(newGame.(float64))

		switch newInt {
		case 1:
			fmt.Printf("Гравець %s хоче нову гру: %v \n", player, newGame)
			i := 0
			if player == "X" {
				i = 1
			}
			//winner := checkWinner(room.Board, room)
			room.Players[i].write <- map[string]any{
				"status": "new_game_requested",
				"board":  room.Board,
				"turn":   room.Turn,
				"winner": room.Winner, // checkWinner(room.Board),
			}
		case 2:
			fmt.Printf("Гравець %s погоджується на нову гру: %v \n", player, newGame)
			room.Board = [9]string{"", "", "", "", "", "", "", "", ""}
			room.Turn = "X"
			room.Winner = ""
			for _, player := range room.Players {
				player.write <- map[string]any{
					"status": "started",
					"board":  room.Board,
					"turn":   room.Turn,
					"winner": room.Winner, // checkWinner(room.Board),
				}
			}
		case 0:
			fmt.Printf("Гравець %s відмовляється від нової гри: %v \n", player, newGame)
			for _, p := range room.Players {
				if p.ID != int(msg["id"].(float64)) {
					p.Conn.Close()
				} else {
					joinQueue <- p
					fmt.Printf("Гравець %d повертається в чергу \n", p.ID)
				}
			}
		}
	}

	leave := msg["status"]
	if leave != nil && leave == "leave" {
		fmt.Printf("Гравець %s хоче покинути кімнату \n", player)
		for _, p := range room.Players {
			if p.ID != int(msg["id"].(float64)) {
				p.Conn.Close()
			} else {
				joinQueue <- p
				fmt.Printf("Гравець %d повертається в чергу \n", p.ID)
			}
		}
	}
}

func removePlayerFromRoom( /*room *Room, */ wrongPlayer *Client) []*Client {
	newPlayers := []*Client{}
	//room.Turn = "X"
	var room *Room
	for _, r := range rooms {
		for _, p := range r.Players {
			if p.ID == wrongPlayer.ID {
				room = r
				break
			}
		}
		if room != nil {
			break
		}
	}

	if room != nil {
		for _, p := range room.Players {
			if p != wrongPlayer {
				//p.inRoom = false
				newPlayers = append(newPlayers, p)
			} else {
				deletePlayer(p)
			}
		}
	} else {
		fmt.Println("removePlayer. room == nil")
	}

	fmt.Printf("removePlayer. newPlayers len == %v \n", len(newPlayers))
	if len(newPlayers) == 1 {
		joinQueue <- newPlayers[0]
		roomsMu.Lock()
		delete(rooms, fmt.Sprintf("client-%d", room.Players[0].ID))
		roomsMu.Unlock()
	} else if len(newPlayers) == 0 {
		fmt.Println("remove player. newPlayers len == 0")
		joinQueue <- nil
	}

	return newPlayers
}

func deletePlayer(p *Client) {
	clientsMu.Lock()
	if p.Conn != nil {
		p.Conn.Close()
		joinQueue <- nil
		fmt.Printf("Гравець %d видалений з кімнати \n", p.ID)
	}
	close(p.read)
	close(p.write)
	for index := range clients {
		if clients[index].ID == p.ID {
			clients = append(clients[:index], clients[index+1:]...)
			fmt.Printf("Клієнт %d видалений з масиву клієнтів. Кількість клієнтів: %d\n", p.ID, len(clients))
			break
		} else {
			fmt.Printf("Гравець %d не знайдений для видалення \n", clients[index].ID)
		}
	}
	clientsMu.Unlock()
}

// Cheking the winner
var winPatterns = [8][3]int{
	{0, 1, 2}, {3, 4, 5}, {6, 7, 8},
	{0, 3, 6}, {1, 4, 7}, {2, 5, 8},
	{0, 4, 8}, {2, 4, 6},
}

func checkWinner(board [9]string, room *Room) string {
	for _, pattern := range winPatterns {
		if board[pattern[0]] != "" &&
			board[pattern[0]] == board[pattern[1]] &&
			board[pattern[1]] == board[pattern[2]] {
			room.Winner = board[pattern[0]]
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

	canAnyoneWin := false
	for _, pattern := range winPatterns {
		hasX := false
		hasO := false
		for _, idx := range pattern {
			if board[idx] == "X" {
				hasX = true
			}
			if board[idx] == "O" {
				hasO = true
			}
		}
		if !(hasX && hasO) {
			canAnyoneWin = true
			break
		} else {
			canAnyoneWin = false
		}
	}

	if !canAnyoneWin {
		return "Draw"
	}

	return ""
}
