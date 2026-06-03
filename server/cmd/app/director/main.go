package main

import (
	"log"
	"net/http"
)

func main() {
	log.Println("sandbox starting...")

	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("api director"))
	})

	// ここや！これが無いと店を畳んでまうで、ワレ！
	log.Println("Server listening on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
