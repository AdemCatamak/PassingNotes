package main

import (
	"PassingNotes/notes"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"log"
)

func init() {

	log.Print("init function was triggered")

	err := godotenv.Load()
	if err != nil {
		log.Print(err)
	}

	log.Print("init function was completed")
}

func main() {

	log.Print("main function was triggered")

	g := gin.Default()
	g.Use(gin.Recovery())

	api := g.Group("/api")
	notes.Register(api.Group("/notes"))

	log.Fatal(g.Run())

}
