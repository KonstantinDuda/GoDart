package main

import "fmt"

func removePlayerFromRoom(wrongPlayer *Client) []*Client {
	newPlayers := []*Client{}
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
