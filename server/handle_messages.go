package main

import (
	"fmt"
	"log"
)

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

func (c *Client) listen() {
	defer func() {
		fmt.Printf("Клієнт %d відключився. Видаляємо з кімнати та масиву клієнтів. \n", c.ID)
		removePlayerFromRoom(c)
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
