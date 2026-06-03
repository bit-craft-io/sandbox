package main

import (
	"bit-craft/gen/gorm/model"
	"bit-craft/internal/core"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	spannergorm "github.com/googleapis/go-gorm-spanner"
	_ "github.com/googleapis/go-sql-spanner"
	"gorm.io/gorm"
)

func main() {
	log.Println("sandbox starting...")

	//wd, _ := os.Getwd()
	log.Println("----------------------")
	log.Printf("PROJECT=%s", os.Getenv("SPANNER_PROJECT_ID"))
	log.Printf("INSTANCE=%s", os.Getenv("SPANNER_INSTANCE_ID"))
	log.Printf("DATABASE=%s", os.Getenv("SPANNER_DATABASE_ID"))
	log.Printf("EMULATOR=%s", os.Getenv("SPANNER_EMULATOR_HOST"))
	log.Println("----------------------")

	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		uuid := core.GenUuid()
		_, _ = w.Write([]byte("api ok " + uuid))
	})

	dsn := fmt.Sprintf(
		"projects/%s/instances/%s/databases/%s",
		os.Getenv("SPANNER_PROJECT_ID"),
		os.Getenv("SPANNER_INSTANCE_ID"),
		os.Getenv("SPANNER_DATABASE_ID"),
	)
	db, err := gorm.Open(spannergorm.New(spannergorm.Config{DriverName: "spanner", DSN: dsn}), &gorm.Config{})
	if err != nil {
		log.Fatal(err)
	}
	log.Println("----------------------")
	fmt.Println(db)
	log.Println("----------------------")

	router := chi.NewRouter()
	router.Method("Get, Post", "/access", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		newRecord := &model.HAccess{
			ID:       core.GenUuid(),
			PublicID: "",
			Info:     "{}",
		}
		if err := db.Create(newRecord).Error; err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		res := map[string]interface{}{
			"status": "created",
			"id":     newRecord.ID,
		}
		jsonData, _ := json.Marshal(res)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write(jsonData)
	}))

	// @note main が停止しないように待ち受け
	log.Println("Server listening on :8080")
	if err := http.ListenAndServe(":8080", router); err != nil {
		log.Fatal(err)
	}
}
