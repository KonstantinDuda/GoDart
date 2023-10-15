package main

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"

	//"strconv"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql"
)

var db *gorm.DB
var err error
var myErray []int

//clients := int[]{}

type Player struct {
	Id             int    `json:"id"`
	PlayerName     string `json:"name"`
	PlayerPassword string `json:"password"`
	WinGame        int    `json:"wingame"`
	LoseGame       int    `json:"losegame"`
}

var plOnline []Player

type MyUser struct {
	Name     string `json:"name"`
	Password string `json:"password"`
}

/*func homePage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Welcome to HomePage!")
	fmt.Println("Endpoint Hit: HomePage")
}*/

func homePageWS(w http.ResponseWriter, r *http.Request) {
	upgrader := websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}

	//erray := []int{0,0,0,0,0,0,0,0,0}
	myErray = []int{0, 0, 0, 0, 0, 0, 0, 0, 0}
	wsh, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Println(err)
		return
	}

	ip := wsh.LocalAddr().String()

	for {
		//data := ""
		t, msg, err := wsh.ReadMessage()
		if err != nil {
			fmt.Println(err)
			return
		}
		//data = string(msg)
		fmt.Println("msg: ", msg)
		var i = 0
		/*decode :=*/ json.Unmarshal(msg, &i)
		myErray[i] = 1
		fmt.Println("myErray: ", myErray)
		strMyErray := myErrayToString(myErray)
		//decod := json.Unmarshal(msg, &data)
		fmt.Println("msg json.Unmarshal: ", i)
		//fmt.Println("Decode: ", decode)
		//fmt.Println("Decode: ", data)
		fmt.Println("Ip: ", ip)
		fmt.Println("Type: ", t)
		//wsh.WriteMessage(_, ip)
		//wsh.WriteMessage(websocket.TextMessage, []byte(data))
		fmt.Println("strMyErray: ", strMyErray)
		wsh.WriteMessage(websocket.TextMessage, []byte(strMyErray))

	}

}

func myErrayToString(erray []int) string {
	str := ""
	for i := 0; i < len(erray); i++ {
		element := string(erray[i])
		fmt.Println("myErrayToString: ", element)
		str += element
	}
	return str
}

func handleRequests() {
	log.Println("Starting developer server at http://127.0.0.1:10000/in")
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

	myRouter.HandleFunc("/in", in)
	myRouter.HandleFunc("/ws", homePageWS)

	http.ListenAndServe(":10000", myRouter) //)
}

func in(w http.ResponseWriter, r *http.Request) {

	fmt.Println("in")
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println("body is ", body)
	var user = MyUser{}
	jsonErr := json.Unmarshal(body, &user)
	if jsonErr != nil {
		fmt.Println(jsonErr)
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	userToken := make([]byte, 16)
	_, err = rand.Read(userToken)
	if err != nil {
		log.Fatal(err)
	}
	uuid := fmt.Sprintf("%x-%x-%x-%x-%x",
		userToken[0:4], userToken[4:6], userToken[6:8], userToken[8:10], userToken[10:])

	fmt.Println(uuid)
	fmt.Fprintf(w, "Hello, %s! Your password is %s. Your Token: %s", user.Name, user.Password, uuid)
	playersOnline(user)
}

func myCreatePlayer(user MyUser) Player {
	stats := []Player{}
	db.Find(&stats)

	newPlayer := Player{}
	if len(stats) > 0 {
		newPlayer.Id = len(stats)
	} else {
		newPlayer.Id = 0
	}
	newPlayer.PlayerName = user.Name
	newPlayer.PlayerPassword = user.Password
	newPlayer.WinGame = 0
	newPlayer.LoseGame = 0

	return newPlayer
}

func playersOnline(user MyUser) {
	newPl := myCreatePlayer(user)

	plOnline = append(plOnline, newPl)
	fmt.Printf("Players.len == %d", len(plOnline))
}

/*func createNewPlayer(w http.ResponseWriter, r *http.Request) {
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
	/*if stats != nil {
		fmt.Println("Players: ", stats[0].PlayerName)
	}
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

func deletePlayer(w http.ResponseWriter, r *http.Request) {}*/

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
