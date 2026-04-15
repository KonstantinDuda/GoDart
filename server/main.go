package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

type Response struct {
	Count int `json:"count"`
}

var (
	counter int
	mu sync.Mutex // Потрібно для безпечної роботи з данними з різних потоків

	// clients = make(map[*websocket.Conn]bool)
	// broadcast = make(chan int) // Chanal to sending new value
	// upgrader = websocket.Upgrader{
	// 	CheckOrigin: func(r *http.Request) bool {return true}, // Дозволяємо всі підключення
	// }
)

func incrementHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Тільки POST запити", http.StatusMethodNotAllowed)
		return
	}

	// Захищаємо змінну від одночасного запису
	mu.Lock()
	counter++
	current := counter
	mu.Unlock()

	// Відправляємо відповідь у формі JSON
	w.Header().Set("Counter-Type", "application/json")
	json.NewEncoder(w).Encode(Response{Count: current})
	fmt.Printf("Лог: Лічильник збільшився до %d\n", current)
}

func main() {
	http.HandleFunc("/increment", incrementHandler)

	fmt.Println("http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
