package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func main() {
	http.HandleFunc("/ping", func(writer http.ResponseWriter, request *http.Request) {
		fmt.Printf("Pong %v", time.Now())
		_, _ = fmt.Fprint(writer, "Pong")
	})

	fmt.Println("Server Started")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
