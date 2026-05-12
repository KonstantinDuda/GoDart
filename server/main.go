package main

import (
	//"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

type Room struct {
	ID      string
	Board   [9]string
	Players []*websocket.Conn
	Turn    string
	Winner  string
}

var (
	upgrader = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool { return true }, // Дозволяємо всі підключення
	}
	rooms   = make(map[string]*Room)
	waiting *websocket.Conn
	roomsMu sync.Mutex
)

func main() {
	//http.HandleFunc("/increment", incrementHandler)
	http.HandleFunc("/ws", handleConnections)

	// Окремий потік для розсилки оновлень
	//go handleMessages()

	fmt.Println("WebSocket сервер запущено на :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func handleConnections(w http.ResponseWriter, r *http.Request) {
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Fatal(err)
	}
	// Ми не закриваємо ws тут через defer, бо він має жити в handleMessages

	roomsMu.Lock()
	if waiting == nil {
		waiting = ws
		roomsMu.Unlock()
		fmt.Println("Waiting for an opponent...")
		ws.WriteJSON(map[string]string{"status": "waiting",
			"message": "Пошук суперника"})
	} else {
		player1 := waiting
		player2 := ws
		waiting = nil

		fmt.Println("Пара знайдена! Створюємо кімнату.")

		roomID := fmt.Sprintf("room-%d", len(rooms)+1)
		newRoom := &Room{
			ID:      roomID,
			Board:   [9]string{"", "", "", "", "", "", "", "", ""},
			Players: []*websocket.Conn{player1, player2},
			Turn:    "X",
		}

		roomsMu.Unlock()
		rooms[roomID] = newRoom

		go handleMessages(newRoom)
		//broadcastToRoom(newRoom, "started")
	}

}

func handleMessages(room *Room) {
	// Коли функція завершується, ми маємо закрити всі сокети в цій кімнаті
	defer func() {
		fmt.Printf("Кімната %s закрита\n", room.ID)
		roomsMu.Lock()
		delete(rooms, room.ID) // Видаляємо кімнату з пам'яті
		roomsMu.Unlock()

		for _, p := range room.Players {
			p.Close()
		}
	}()

	// 2. Відправляємо початковий стан обом гравцям
	// Гравцю 0 кажемо, що він X, гравцю 1 — що він O
	for i, conn := range room.Players {
		symbol := "X"
		if i == 1 {
			symbol = "O"
		}
		conn.WriteJSON(map[string]any{
			"status": "started",
			"board":  room.Board,
			"turn":   room.Turn,
			"symbol": symbol,
		})
	}

	type PlayerMove struct {
		Index  int
		Symbol string
	}
	moves := make(chan PlayerMove)

	// 3. Запускаємо горутину для читання повідомлень від кожного гравця
	for i, conn := range room.Players {
		symbol := "X"
		if i == 1 {
			symbol = "O"
		}

		go func(c *websocket.Conn, s string) {
			for {
				var msg map[string]any
				if err := c.ReadJSON(&msg); err != nil {
					log.Printf("Помилка читання від клієнта: %v \n", err)
					c.Close()
					room.Players = removePlayer(room, c)
					return
				}
				if idx, ok := msg["index"]; ok {
					//fmt.Printf("Player %s send %d", s, idx)
					player := msg["symbol"]
					//moves <- PlayerMove{Index: int(idx.(float64)), Symbol: s}
					moves <- PlayerMove{Index: int(idx.(float64)), Symbol: player.(string)}
				} else {
					fmt.Printf("Player %s send msg['index'] != ok \n", s)
					//var newMsg map[string]any
					if new, ok := msg["new_game"]; ok {
						fmt.Printf("Player %s wants new game: %v \n", s, new)
						newInt := int(new.(float64))

						switch newInt {
						case 1:
							index := 0
							if s == "X" {
								index = 1
							}
							fmt.Printf("Player %s wants new game: %v \n", s, new)
							//winner := checkWinner(room.Board, room)
							room.Players[index].WriteJSON(map[string]any{
								"status": "new_game_requested",
								"board":  room.Board,
								"turn":   room.Turn,
								"winner": room.Winner, // checkWinner(room.Board),
							})
						case 2:
							fmt.Printf("Player %s agrees to new game: %v \n", s, new)
							room.Board = [9]string{"", "", "", "", "", "", "", "", ""}
							room.Turn = "X"
							room.Winner = ""
							for _, conn := range room.Players {
								conn.WriteJSON(map[string]any{
									"status": "started",
									"board":  room.Board,
									"turn":   room.Turn,
									"winner": room.Winner, // checkWinner(room.Board, room),
								})
							}
						case 0:
							fmt.Printf("Player %s refuses new game: %v \n", s, new)
							index := 0
							if s == "O" {
								index = 1
							}
							c.Close()
							room.Players = removePlayer(room, room.Players[index])
						}
					}
					if leave, ok := msg["status"]; ok {
						if leave == "leave" {
							fmt.Printf("Player %s wants to leave room \n", s)
							index := 0
							if s == "O" {
								index = 1
							}
							c.Close()
							room.Players = removePlayer(room, room.Players[index])
							return
						}
					}
				}
			}
		}(conn, symbol)
	}

	// 4. Основний цикл гри (обробка черги)
	for {
		move := <-moves // Чекаємо на хід від будь-кого
		fmt.Printf("Отримано хід: %s на позицію %d, Черга: %s\n", move.Symbol, move.Index, room.Turn)
		// Перевірка: чи зараз хід цього гравця?
		if move.Symbol != room.Turn {
			fmt.Printf("Невірний хід від %s. Очікується %s\n", move.Symbol, room.Turn)
			continue
		}

		// Перевірка: чи клітинка вільна, та чи ще немає переможця?
		if room.Board[move.Index] == "" && room.Winner == "" {
			room.Board[move.Index] = move.Symbol

			// Зміна черги
			if room.Turn == "X" {
				room.Turn = "O"
			} else {
				room.Turn = "X"
			}

			room.Winner = checkWinner(room.Board, room)

			// Відправка оновлення обом
			for _, conn := range room.Players {
				err := conn.WriteJSON(map[string]any{
					"status": "playing",
					"board":  room.Board,
					"turn":   room.Turn,
					"winner": room.Winner, // checkWinner(room.Board, room),
				})
				if err != nil {
					fmt.Printf("Помилка відправки оновлення: %v\n", err)
					return // Якщо не вдалося відправити — завершуємо горутину
				}
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

func removePlayer(room *Room, wrongPlayer *websocket.Conn) []*websocket.Conn {
	newPlayers := []*websocket.Conn{}
	room.Turn = "X"

	for _, p := range room.Players {
		if p != wrongPlayer {
			newPlayers = append(newPlayers, p)
		}
	}

	fmt.Printf("removePlayer. newPlayers len == %v \n", len(newPlayers))
	if len(newPlayers) == 1 {
		//fmt.Println("remove player. newPlayers len < 2")
		if waiting == nil {
			waiting = newPlayers[0]
			//fmt.Printf("rooms length before delete == %v \n", len(rooms))
			roomsMu.Lock()
			delete(rooms, room.ID)
			roomsMu.Unlock()
			//fmt.Printf("rooms length after delete == %v \n", len(rooms))
			waiting.WriteJSON(map[string]string{"status": "waiting",
				"message": "Пошук суперника"})
		} else {
			fmt.Println("remove player. waiting != nil")
			newPlayers = append(newPlayers, waiting)
		}
	} else if len(newPlayers) == 0 {
		fmt.Println("remove player. newPlayers len == 0")
		roomsMu.Lock()
		delete(rooms, room.ID)
		roomsMu.Unlock()
	}

	return newPlayers
}
