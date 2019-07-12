package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/ping", func(writer http.ResponseWriter, request *http.Request) {
		fmt.Println("Pong")
		_, _ = fmt.Fprint(writer, "Pong")
	})

	fmt.Println("Server Started")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
