package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql"
)

var db *gorm.DB
var err error

type Player struct {
	Id         int    `json:"id"`
	PlayerName string `json:"playername"`
	WinGame    int    `json:"wingame"`
	LoseGame   int    `json:"losegame"`
}

func homePage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Welcome to HomePage!")
	fmt.Println("Endpoint Hit: HomePage")
}

func homePageWS(w http.ResponseWriter, r *http.Request) {
	upgrader := websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}

	wsh, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Println(err)
		return
	}

	/*for {
		thisType, msg, err := wsh.ReadMessage()
		if err != nil {
			fmt.Println(err)
			return
		}
		fmt.Println(msg)
		fmt.Println(thisType)
		wsh.WriteMessage(thisType, msg)
	}*/

	for {
		data := ""
		thisType, msg, err := wsh.ReadMessage()
		if err != nil {
			fmt.Println(err)
			return
		}
		data = string(msg)
		//decod := json.Unmarshal(msg, &data)
		fmt.Println("Decode: ", data)
		//fmt.Println(thisType)
		wsh.WriteMessage(thisType, msg)
	}

}

func handleRequests() {
	log.Println("Starting developer server at http://127.0.0.1:10000/")
	log.Println("Quit the server with CONTROL-C.")

	/*myRouter := mux.NewRouter().StrictSlash(true)
	myRouter.HandleFunc("/", homePage)
	myRouter.HandleFunc("/players", returnAllPlayer)
	myRouter.HandleFunc("/player/new", createNewPlayer)
	myRouter.HandleFunc("/player/{id}", returnSinglePlayer)
	myRouter.HandleFunc("/player/delete/{id}", deletePlayer)
	myRouter.HandleFunc("/player/update/{id}", updatePlayer)*/

	//log.Fatal(
	myRouter := mux.NewRouter()

	myRouter.HandleFunc("/ws", homePageWS)

	http.ListenAndServe(":10000", myRouter) //)
}

func createNewPlayer(w http.ResponseWriter, r *http.Request) {
	reqBody, _ := ioutil.ReadAll(r.Body)

	var stats Player
	json.Unmarshal(reqBody, &stats)
	db.Create(&stats)

	fmt.Println("Endpoint Hit: Create New Card")
	json.NewEncoder(w).Encode(stats)
}

func returnAllPlayer(w http.ResponseWriter, r *http.Request) {
	stats := []Player{}
	db.Find(&stats)
	fmt.Println("Endpoint Hit: return All stats")

	json.NewEncoder(w).Encode(stats)
}

func returnSinglePlayer(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]
	stats := []Player{}
	db.Find(&stats) // db.Find(&cards,id) додати умову пошуку по id

	for _, Stats := range stats {
		s, err := strconv.Atoi(id)
		if err == nil {
			if Stats.Id == s {
				fmt.Println(Stats)
				fmt.Println("Endpoint Hit: Card No:", id)
				json.NewEncoder(w).Encode(Stats)
			}
		}
	}
}

func updatePlayer(w http.ResponseWriter, r *http.Request) {}

func deletePlayer(w http.ResponseWriter, r *http.Request) {}

func main() {
	db, err = gorm.Open("mysql", "user:123456@tcp(127.0.0.1:3306)/MyGame?charset=utf8&parseTime=True")

	if err != nil {
		log.Println("Connection Failed to Open")
	} else {
		log.Println("Connection Established")
	}

	db.AutoMigrate(&Player{})
	handleRequests()
}
